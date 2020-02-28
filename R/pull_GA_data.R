#pull some data to develop visuals with
#grab several important applications
library(googleAnalyticsR)
library(googleAuthR)
library(tidyverse)
gar_auth_service('~/.vizlab/VIZLAB-a48f4107248c.json')
ga_table <- do.call(bind_rows, yaml::read_yaml('gaTable.yaml')) 
set.seed(1) #get a random selection of applications, plus NWIS web
ga_table_filtered <- sample_n(ga_table, 5) %>%
  bind_rows(filter(ga_table, shortName %in% c('NWISWebDesktop', 'New Site Pages')))

three_years_ago <- Sys.Date() - lubridate::years(3)
one_year_ago <- Sys.Date() - lubridate::years(1)
today <- Sys.Date()

source('R/functions.R')
traffic_data <- get_multiple_view_ga_df(view_df = ga_table_filtered,
                                        end_date = today,
                                        start_date = three_years_ago,
                                        dimensions = c("date"),
                                        metrics = c("sessions", "users"),
                                        max= -1)
traffic_data_out <- traffic_data %>% mutate(year = lubridate::year(date),
                                            fiscal_year = dataRetrieval::calcWaterYear(date))
write_csv(traffic_data_out, path = "out/traffic_data_3_years.csv")

#Can you get page content groupings from the API?
#probably want to use less sampling (samplingLevel argument to google_analytics) for final product
landing_exit_pages <- get_multiple_view_ga_df(view_df = ga_table_filtered,
                                        end_date = today,
                                        start_date = one_year_ago,
                                        dimensions = c("landingPagePath", "secondPagePath", "exitPagePath"),
                                        metrics = c("sessions"),
                                        max= -1)
write_csv(landing_exit_pages, path = "out/landing_exit_pages.csv")
aws.signature::use_credentials(profile = "chsprod")
system2('aws s3 cp out/* s3://internal-wma-test-website/analytics/data/dashboard_test/ --profile chsprod')
aws.s3::s3sync(files = dir('out', full.names = TRUE), 
               bucket = "s3://internal-wma-test-website/analytics/data/dashboard_test/",
               direction = "upload")
  