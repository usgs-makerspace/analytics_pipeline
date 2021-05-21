library(googleAnalyticsR)
library(googleAuthR)
library(arrow)
library(tidyr)
library(lubridate)
library(plyr)
library(dplyr)

yesterday <- seq(from=as.Date('2019-10-01'), to=as.Date('2020-09-30'), by='days')

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
  
  flow_stage_or_q <- google_analytics(nwis_web_view, date_range = date_range,
                                      dimensions = c("pagePath", "date"), slow_fetch = TRUE,
                                      metrics = c("uniquePageviews","pageViews"),
                                      max = -1, dim_filters = filter_clause_site_page,
                                      rows_per_call = 100000, anti_sample = TRUE)
  
}

for ( i in seq_along(yesterday) ) {
  
  message(paste0("pulling data for: ", yesterday[i]))
  df <- get_nwis_site_page_views(date_range = c(yesterday[i], yesterday[i]))
  message(paste0("pulled ", nrow(df)," rows."))
  
  source('R/functions.R')
  source('R/group_data.R')
  
  message(paste0("summarizing data"))
  df <- group_by_site_id(df)
  message(paste0("summarized ", nrow(df)," rows."))
  
  filename <- paste0("noms_daily","_",yesterday[i],".parquet")
  
  write_df_to_parquet(df, 
                      sink = paste0("out/noms/",filename))
  message(paste0("done with ", yesterday[i]))
}
  
