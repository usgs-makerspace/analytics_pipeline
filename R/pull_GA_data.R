#pull some data to develop visuals with
#grab several important applications
library(googleAnalyticsR)
library(googleAuthR)
library(dplyr)
library(arrow)
gar_set_client(json = Sys.getenv('GA_CLIENTID_FILE'), 
               scopes = "https://www.googleapis.com/auth/analytics.readonly")
gar_auth_service(json_file = Sys.getenv('GA_AUTH_FILE'))
ga_table <- do.call(bind_rows, yaml::read_yaml('gaTable.yaml')) 

three_years_ago <- Sys.Date() - lubridate::years(3)
one_year_ago <- Sys.Date() - lubridate::years(1)
thirty_days_ago <- Sys.Date() - 30
today <- Sys.Date()

source('R/functions.R')
source('R/group_data.R')
traffic_data <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = three_years_ago,
                                        dimensions = c("date"),
                                        metrics = c("sessions", "users"),
                                        max= -1)
traffic_data_out <- traffic_data %>% mutate(year = lubridate::year(date),
                                            fiscal_year = dataRetrieval::calcWaterYear(date))
write_df_to_parquet(traffic_data_out, sink = "out/all_apps_traffic_data_3_years.parquet")

year_month_week_traffic <- group_day_month_year(traffic_data)
write_df_to_parquet(year_month_week_traffic, sink = "out/year_month_week_traffic.parquet")

#Can you get page content groupings from the API?
#probably want to use less sampling (samplingLevel argument to google_analytics) for final product
landing_exit_pages <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = one_year_ago,
                                        dimensions = c("landingPagePath", "secondPagePath", "exitPagePath"),
                                        metrics = c("sessions"),
                                        max= -1)
write_df_to_parquet(landing_exit_pages, sink = "out/all_apps_landing_exit_pages.parquet")
#system('aws s3 sync out/ s3://internal-test.wma.chs.usgs.gov/analytics/data/dashboard_test/ --profile chsprod')


#page load data
load_time_data <- get_multiple_view_ga_df(view_df = ga_table,
                                        end_date = today,
                                        start_date = thirty_days_ago,
                                        dimensions = c("pagePath"),
                                        metrics = c("pageLoadSample", "avgPageLoadTime",
                                                    "avgPageDownloadTime",
                                                    "avgDomContentLoadedTime",
                                                    "exitRate"),
                                        max= -1)
load_time_data_filtered <- load_time_data %>% 
  filter(pageLoadSample > 0)
write_df_to_parquet(load_time_data_filtered, 
          sink = "out/page_load_30_days.parquet")
