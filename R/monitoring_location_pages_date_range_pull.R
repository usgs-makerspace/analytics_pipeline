library(googleAnalyticsR)
library(googleAuthR)
library(arrow)
library(tidyr)
library(lubridate)
library(dplyr)

yesterday <- Sys.Date()-1

yesterday <- seq(from=yesterday, to=yesterday, by='days')

gar_set_client(json = Sys.getenv('GA_CLIENTID_FILE'), 
               scopes = "https://www.googleapis.com/auth/analytics.readonly")
gar_auth_service(json_file = Sys.getenv('GA_AUTH_FILE'))

source('R/functions.R')
source('R/group_data.R')

for ( i in seq_along(yesterday) ) {
  
  message(paste0("pulling data for: ", yesterday[i]))
  df <- get_nwis_site_page_views(date_range = c(yesterday[i], yesterday[i]))
  message(paste0("pulled ", nrow(df)," rows."))
  
  message(paste0("summarizing data"))
  df <- group_by_site_id(df)
  message(paste0("summarized ", nrow(df)," rows."))
  
  filename <- paste0("monitoring_location_pages_daily","_",yesterday[i],".parquet")
  
  write_df_to_parquet(df, 
                      sink = paste0("out/monitoring_location_pages/",filename))
  message(paste0("done with ", yesterday[i]))
}
  
