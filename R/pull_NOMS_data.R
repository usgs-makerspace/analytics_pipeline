library(googleAnalyticsR)
library(googleAuthR)
library(dplyr)
library(tidyr)
library(arrow)
library(lubridate)
library(urltools)
library(plyr)

get_nwisweb_google_analytics <- function(date_range = c('2020-01-01', '2020-02-01')) {
  gar_auth_service('~/.vizlab/VIZLAB-a48f4107248c.json')
  nwis_web_view <- '49785472'
  
  #filters 
  #all requests should 1st and either 2nd or third of these:
  filter_eight_digit_site <- dim_filter("pagePath", "REGEXP", expressions = "site_no=[0-9]{8,8}[^0-9]")
  filter_8_15_digit_site <- dim_filter("pagePath", "REGEXP", expressions = "site_no=[0-9]{8,15}[^0-9]")
  #########
  #plus, one of these two filters
  
  ###########
  filter_clause_site_page <- filter_clause_ga4(list(filter_eight_digit_site, 
                                                    filter_8_15_digit_site),
                                               operator = "AND")
  
  #uncomment the dimensions arg to retrieve the actual data --- this just
  #retrieves totals for each metric
  flow_stage_or_q <- google_analytics(nwis_web_view, date_range = date_range,
                                      dimensions = c("pagePath", "date"), slow_fetch = TRUE,
                                      metrics = c("uniquePageviews","pageViews"),
                                      max = -1, dim_filters = filter_clause_site_page,
                                      rows_per_call = 100000, anti_sample = TRUE)
  
}

df <- get_nwisweb_google_analytics(date_range = c('2021-05-11', '2021-05-11'))

source('R/functions.R')
source('R/group_data.R')

df <- group_by_site_id(df)
