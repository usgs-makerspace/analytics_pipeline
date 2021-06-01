library(googleAnalyticsR)
library(googleAuthR)
library(dplyr)
library(tidyr)
library(arrow)
library(lubridate)

gar_set_client(json = Sys.getenv('GA_CLIENTID_FILE'), 
               scopes = "https://www.googleapis.com/auth/analytics.readonly")
gar_auth_service(json_file = Sys.getenv('GA_AUTH_FILE'))
ga_table <- do.call(bind_rows, yaml::read_yaml('gaTable.yaml')) 


##### Time variable setup #####
sys_date_eastern_time <- date(with_tz(Sys.time(), 'America/New_York')) #Jenkins is on UTC 
  
start_fy_2010 <- as.Date("2009-10-01")  #WaterWatch has data starting summer 2009
three_years_ago_rounded_down <- (sys_date_eastern_time - lubridate::years(3)) %>% 
  floor_date(unit = "quarter")
one_year_ago <- sys_date_eastern_time - lubridate::years(1)
end_of_last_month <- sys_date_eastern_time %>% floor_date(unit = "month") - 1
thirty_days_ago <- sys_date_eastern_time - 30
yesterday <- sys_date_eastern_time - 1
seven_days_ago <- sys_date_eastern_time - 7
current_fiscal_year <- dataRetrieval::calcWaterYear(sys_date_eastern_time -1)
start_current_fiscal_year <- as.Date(paste0(current_fiscal_year - 1, "-10-01")) 
days_into_current_fiscal_year <- sys_date_eastern_time - start_current_fiscal_year

nwisweb_all_regex <- "NWISWeb \\(NextGen \\+ Legacy Desktop\\)|NWISWeb \\(Mobile\\)|NWISWeb \\(Mapper\\)"
nwisweb_all <- "NWISWeb (All)"

#these (NWIS Web Legacy, NG Beta) are covered by the original NWISWeb view 
#('NWISWeb (NextGen + Legacy Desktop)')
double_count_view_ids <- c('190316048', '221302252')

backfill_date <- as.Date("2009-11-01") #to generate dummy data for Tableau 'relative to first'
message("Yesterday in Eastern time: ", yesterday) #depends on Jenkins tz; record what is used

source('R/functions.R')
source('R/group_data.R')
source('R/regionality.R')

##### Past three years traffic #####
traffic_data <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = yesterday,
                                        start_date = three_years_ago_rounded_down,
                                        dimensions = c("date"),
                                        metrics = c("sessions", "users"),
                                        max= -1) %>% 
  add_sum_of_views(view_name_pattern = "Water Science School", method = "three_year_traffic") %>% 
  add_sum_of_views(view_name_pattern = "water.usgs.gov", method = "three_year_traffic") %>% 
  add_sum_of_views(view_name_pattern = nwisweb_all_regex,
                   new_name = nwisweb_all, method = "three_year_traffic") %>% 
  splice_two_views(splice_date = "2020-06-16", 
                   view_to_fill_in = "NWISWeb (Legacy Desktop)",
                   view_to_fill_with = "NWISWeb (NextGen + Legacy Desktop)",
                   date_col = date)

traffic_data_out <- traffic_data %>% mutate(year = year_to_jan_1st(lubridate::year(date)),
                                            fiscal_year = year_to_jan_1st(dataRetrieval::calcWaterYear(date)))

write_df_to_parquet(traffic_data_out, 
                    sink = "out/three_year_traffic/all_apps_traffic_data_3_years.parquet")

year_month_week_traffic <- group_day_month_year(traffic_data)
current_fy_traffic <- group_by_ndays(traffic_data, ndays = days_into_current_fiscal_year,
                                     period_name = "current fiscal year")
year_month_week_fy_traffic <- bind_rows(year_month_week_traffic, current_fy_traffic)
write_df_to_parquet(year_month_week_fy_traffic, 
                    sink = "out/year_month_week/year_month_week_traffic.parquet")

week_change <- compare_sessions_to_last_year(traffic_data, last_n_days = 7, period_name = "7 days")
month_change <- compare_sessions_to_last_year(traffic_data, last_n_days = 30, period_name = "30 days")
fiscal_year_change <- compare_sessions_to_last_year(traffic_data, 
                                             last_n_days = days_into_current_fiscal_year,
                                             period_name = "fiscal_year")
app_period_bins <- bind_rows(week_change, month_change, fiscal_year_change)
write_df_to_parquet(app_period_bins,
                    sink = "out/compared_to_last_year/compared_to_last_year.parquet")


##### long term data #####
message("Long term data pull")
traffic_data_long_term <- get_multiple_view_ga_df(view_df = ga_table,
                                                  end_date = end_of_last_month,
                                                  start_date = start_fy_2010,
                                                  dimensions = c("year", "month"),
                                                  metrics = c("sessions",
                                                              "avgSessionDuration",
                                                              "pageviewsPerSession",
                                                              "percentNewSessions"),
                                                  max= -1) %>% 
  add_sum_of_views(view_name_pattern = "Water Science School", method = "long_term") %>% 
  add_sum_of_views(view_name_pattern = "water.usgs.gov", method = "long_term") %>% 
  add_sum_of_views(view_name_pattern = nwisweb_all_regex,
                   new_name = nwisweb_all, method = "long_term") %>% 
  mutate(first_of_month = as.Date(paste(year, month, "01", sep = "-"))) %>% 
  splice_two_views(splice_date = "2020-06-16", 
                   view_to_fill_in = "NWISWeb (Legacy Desktop)",
                   view_to_fill_with = "NWISWeb (NextGen + Legacy Desktop)",
                   date_col = first_of_month) %>% 
  #Drop pre-launch data to eliminate massive percent increases in traffic
  filter(sessions > 0,
         first_of_month > '2016-06-01' | view_name != 'NWISWeb (Mapper)',
         first_of_month > '2014-02-01' | view_name != 'NWISWeb (Mobile)',
         first_of_month > '2019-04-01' | view_name != 'Water Science School (Drupal)',
         first_of_month > '2013-07-01' | view_name != 'National Environmental Methods Index',
         first_of_month > '2015-07-01' | view_name != 'Geo Data Portal') %>% 
  group_by(view_name) %>% 
  arrange(view_name, year, month) %>% 
  slice(-1) %>% 
  backfill_app_data(min_date = as.Date(backfill_date)) %>% 
  mutate(fiscal_year = year_to_jan_1st(
    dataRetrieval::calcWaterYear(as.Date(paste(year, month, '01', sep = "-")))
  ))
write_df_to_parquet(traffic_data_long_term, 
                    sink = "out/long_term_monthly/long_term_monthly.parquet")

##### state data ####
message("Geographic data pull")
state_traffic_year <- get_multiple_view_ga_df(view_df = ga_table,
                                              end_date = yesterday,
                                              start_date = one_year_ago,
                                              dimensions = c("region", "country"),
                                              metrics = c("sessions"),
                                              max= -1) %>% 
  mutate(period = "365 days")

state_traffic_month <- get_multiple_view_ga_df(view_df = ga_table,
                                               end_date = yesterday,
                                               start_date = thirty_days_ago,
                                               dimensions = c("region", "country"),
                                               metrics = c("sessions"),
                                               max= -1) %>% 
  mutate(period = "30 days")
state_traffic_week <- get_multiple_view_ga_df(view_df = ga_table,
                                              end_date = yesterday,
                                              start_date = seven_days_ago,
                                              dimensions = c("region", "country"),
                                              metrics = c("sessions"),
                                              max= -1) %>% 
  mutate(period = "7 days")
state_traffic_all <- bind_rows(state_traffic_year, state_traffic_month, state_traffic_week) %>% 
  add_sum_of_views(view_name_pattern = "water.usgs.gov", method = "state") %>% 
  add_sum_of_views(view_name_pattern = "Water Science School", method = "state") %>% 
  add_sum_of_views(view_name_pattern = nwisweb_all_regex, new_name = nwisweb_all, method = "state")
write_df_to_parquet(state_traffic_all, 
                    sink = "out/state_traffic/state_traffic_year_month_week.parquet")

state_traffic_percentages <- get_state_traffic_pop_pct(state_traffic_all) %>% 
  mutate(country = "United States") %>% 
  select(-REGION)
write_df_to_parquet(state_traffic_percentages, 
                    sink = "out/state_traffic_population_percentages/state_traffic_population_percentages.parquet")

regionality_metric <- compute_regionality_metric(state_traffic_percentages)
write_df_to_parquet(regionality_metric,
                    sink = 'out/regionality/regionality.parquet')

state_week_vs_year <- compute_week_vs_year(state_traffic_all) %>%
  rename("365_days" = "365 days", "30_days" = "30 days", "7_days" = "7 days") %>% 
  mutate(weekly_average = `365_days`/52.14,
         week_percent_from_average = (`7_days` - weekly_average)/weekly_average * 100)
if(Sys.Date() < as.Date('2021-06-25')) { #this view won't have a full year of data yet
  message("Adjusting state vs week for views that don't have a year of data")
  state_week_vs_year <- state_week_vs_year %>% 
    mutate(week_percent_from_average = if_else(condition = view_name == "NWISWeb (Legacy Desktop)",
                                              true = NA_real_,
                                              false = week_percent_from_average))
}
write_df_to_parquet(state_week_vs_year,
                    sink = 'out/state_week_vs_year/state_week_vs_year.parquet')

##### pull BAN number data #####
#past week, month, and so far in fiscal year
ga_table_no_double_counts <- ga_table %>% 
  filter(!viewID %in% double_count_view_ids)
ban_numbers_week <- get_multiple_view_ga_df(view_df = ga_table_no_double_counts,
                                            end_date = yesterday,
                                            start_date = seven_days_ago,
                                            metrics = c("sessions", "percentNewSessions", "sessionDuration"),
                                            dimensions = c("deviceCategory", "browser","dayOfWeekName"),
                                            max= -1) %>% 
  mutate(period = '7 days',
         newSessions = percentNewSessions*.01*sessions)
ban_numbers_month <- get_multiple_view_ga_df(view_df = ga_table_no_double_counts,
                                             end_date = yesterday,
                                             start_date = thirty_days_ago,
                                             metrics = c("sessions", "percentNewSessions", "sessionDuration"),
                                             dimensions = c("deviceCategory", "browser","dayOfWeekName"),
                                             max= -1) %>% 
  mutate(period = '30 days',
         newSessions = percentNewSessions*.01*sessions)

ban_numbers_fy <- get_multiple_view_ga_df(view_df = ga_table_no_double_counts,
                                          end_date = yesterday,
                                          start_date = start_current_fiscal_year,
                                          metrics = c("sessions", "percentNewSessions", "sessionDuration"),
                                          dimensions = c("deviceCategory", "browser","dayOfWeekName"),
                                          max= -1) %>% 
  mutate(period = 'current fiscal year', 
         newSessions = percentNewSessions*.01*sessions)
ban_numbers_year <- get_multiple_view_ga_df(view_df = ga_table_no_double_counts,
                                            end_date = yesterday,
                                            start_date = one_year_ago,
                                            metrics = c("sessions", "percentNewSessions", "sessionDuration"),
                                            dimensions = c("deviceCategory", "browser","dayOfWeekName"),
                                            max= -1) %>% 
  mutate(period = '365 days',
         newSessions = percentNewSessions*.01*sessions)
all_ban_numbers <- bind_rows(ban_numbers_fy, ban_numbers_month, 
                             ban_numbers_week, ban_numbers_year)
write_df_to_parquet(all_ban_numbers,
                    sink = "out/summary_numbers/summary_numbers.parquet")

gar_cache_setup(mcache = memoise::cache_filesystem("cache"))
##### Landing/exit pages #####
message("Landing/exit page pull")
landing_exit_pages <- get_multiple_view_ga_df(view_df = ga_table,
                                              end_date = yesterday,
                                              start_date = one_year_ago,
                                              dimensions = c("landingPagePath", "secondPagePath", "exitPagePath"),
                                              metrics = c("sessions"),
                                              max= -1, anti_sample = TRUE,
                                              slow_fetch = TRUE)
write_df_to_parquet(landing_exit_pages, 
                    sink = "out/landing_exit_pages/all_apps_landing_exit_pages.parquet")

##### page load data #####
message("Load time data pull")
load_time_data <- get_multiple_view_ga_df(view_df = ga_table,
                                          end_date = yesterday,
                                          start_date = thirty_days_ago,
                                          dimensions = c("pagePath"),
                                          metrics = c("pageLoadSample", "avgPageLoadTime",
                                                      "avgPageDownloadTime",
                                                      "avgDomContentLoadedTime",
                                                      "exitRate"),
                                          max= -1, anti_sample = TRUE,
                                          slow_fetch = TRUE)
load_time_data_filtered <- load_time_data %>% 
  filter(pageLoadSample > 0)
write_df_to_parquet(load_time_data_filtered, 
                    sink = "out/page_load/page_load_30_days.parquet")

get_nwis_site_page_views <- function(date_range = c('2020-01-01', '2020-02-01')) {
  gar_auth_service('~/.vizlab/VIZLAB-a48f4107248c.json')
  nwis_web_view <- '49785472'
  
  #filter 
  #get all pagePaths with numeric data between 8 and 15 digits long in it:
  filter_8_15_digit_site <- dim_filter("pagePath", "REGEXP", expressions = "[0-9]{8,15}")
  #########
  
  ###########
  filter_clause_site_page <- filter_clause_ga4(list(filter_8_15_digit_site),
                                               operator = "AND")
  
  site_number_page_views <- google_analytics(nwis_web_view, date_range = date_range,
                                             dimensions = c("pagePath", "date"), slow_fetch = TRUE,
                                             metrics = c("uniquePageviews","pageViews"),
                                             max = -1, dim_filters = filter_clause_site_page,
                                             rows_per_call = 100000, anti_sample = TRUE)
  
}