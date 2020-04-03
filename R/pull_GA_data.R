#pull some data to develop visuals with
#grab several important applications
library(googleAnalyticsR)
library(googleAuthR)
library(tidyverse)
gar_auth_service('~/.vizlab/VIZLAB-a48f4107248c.json')
ga_table <- do.call(bind_rows, yaml::read_yaml('gaTable.yaml')) 
# set.seed(1) #get a random selection of applications, plus NWIS web
# ga_table_filtered <- sample_n(ga_table, 5) %>%
#   bind_rows(filter(ga_table, shortName %in% c('NWISWebDesktop', 'New Site Pages')))

three_years_ago <- Sys.Date() - lubridate::years(3)
one_year_ago <- Sys.Date() - lubridate::years(1)
thirty_days_ago <- Sys.Date() - 30
today <- Sys.Date()

source('R/functions.R')
traffic_data <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = three_years_ago,
                                        dimensions = c("date"),
                                        metrics = c("sessions", "users"),
                                        max= -1)
traffic_data_out <- traffic_data %>% mutate(year = lubridate::year(date),
                                            fiscal_year = dataRetrieval::calcWaterYear(date))
write_csv(traffic_data_out, path = "out/all_apps_traffic_data_3_years.csv")

year_month_week_traffic <- group_day_month_year(traffic_data)
write_csv(year_month_week_traffic, path = "out/year_month_week_traffic.csv")

#Can you get page content groupings from the API?
#probably want to use less sampling (samplingLevel argument to google_analytics) for final product
landing_exit_pages <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = one_year_ago,
                                        dimensions = c("landingPagePath", "secondPagePath", "exitPagePath"),
                                        metrics = c("sessions"),
                                        max= -1)
write_csv(landing_exit_pages, path = "out/all_apps_landing_exit_pages.csv")
#system('aws s3 sync out/ s3://internal-test.wma.chs.usgs.gov/analytics/data/dashboard_test/ --profile chsprod')


#page load data
load_time_data <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = thirty_days_ago,
                                        dimensions = c("pagePath"),
                                        metrics = c("pageLoadSample", "avgPageLoadTime",
                                                    "avgPageDownloadTime",
                                                    "avgDomContentLoadedTime"),
                                        max= -1)
load_time_data_filtered <- load_time_data %>% 
  filter(pageLoadSample > 0)
write_csv(load_time_data_filtered, 
          path = "out/page_load_30_days.csv")
