group_by_ndays <- function(df, ndays, period_name) {
  most_recent_day <- max(df$date)
  df %>% filter(date >= (most_recent_day - ndays)) %>% 
    group_by(view_name, view_id) %>%
    summarize(sessions = sum(sessions), users = sum(users)) %>% 
    mutate(period = period_name)
}

#' @param df data.frame of daily timeseries of sessions and users for multiple applications
#'           expects sessions, users, view_id, view_name, date columns
#' @return data frame with total users and sessions for previous year, month, and day for each application
group_day_month_year <- function(df) {
  year_df <- group_by_ndays(df, ndays = 365, period_name = "365 days")
  month_df <- group_by_ndays(df, ndays = 30, period_name = "30 days")
  week_df <- group_by_ndays(df, ndays = 7, period_name = "7 days")
  return_df <- bind_rows(year_df, month_df, week_df)
}

merge_app_groups <- function(df_groups_to_sum, new_name) {
  UseMethod("merge_app_groups", df_groups_to_sum)
}
merge_app_groups.long_term <- function(df_groups_to_sum, new_name) {
  new_group <- df_groups_to_sum %>% 
    mutate(pageViews = sessions * pageviewsPerSession,
           newSessions = sessions * (percentNewSessions*0.01),
           totalSessionDuration = sessions * avgSessionDuration) %>% 
    group_by(year, month) %>% 
    summarize(sessions = sum(sessions),
              pageViews = sum(pageViews),
              newSessions = sum(newSessions),
              totalSessionDuration = sum(totalSessionDuration)) %>% 
    mutate(avgSessionDuration = totalSessionDuration/sessions,
           pageviewsPerSession = pageViews/sessions,
           percentNewSessions = newSessions/sessions*100,
           view_name = new_name,
           view_id = new_name) %>% 
    select(-newSessions, -pageViews, -totalSessionDuration)
  return(new_group)
}
merge_app_groups.state <- function(df_groups_to_sum, new_name) {
  df_groups_to_sum %>% group_by(region, country, period) %>% 
    summarize(sessions = sum(sessions)) %>% 
    mutate(view_name = new_name,
           view_id = new_name)
}
merge_app_groups.three_year_traffic <- function(df_groups_to_sum, new_name) {
  df_groups_to_sum %>% group_by(date) %>% 
    summarize(sessions = sum(sessions)) %>% 
    mutate(view_name = new_name,
           view_id = new_name)
}

#' Combine the contents of two views
#' 
#' @param df data frame expecting certain columns from Google Analytics
#' @param view_name_pattern string that will be matched against the 
#' view_name columns.  All rows that match it will be combined by year/month
#'
add_sum_of_views <- function(df, view_name_pattern, method, new_name = view_name_pattern) {
  df_groups_to_sum <- df %>% filter(grepl(x = view_name, pattern = view_name_pattern))
  class(df_groups_to_sum) <- c(method, class(df_groups_to_sum))
  new_group <- merge_app_groups(df_groups_to_sum, new_name)
  df_plus_new_group <- bind_rows(df, new_group)
  return(df_plus_new_group)
}

#' @param df data.frame of daily unique pageviews and page paths with site ids for noms
#'           expects pagepath, date, uniquePageviews and pageviews
#' @return data frame with daily unique pageviews and site ids
group_by_site_id <- function(df) {
  # clean up yucky url bits like encoded things and different param names
  df$pagePath <- gsub("&amp;","&",df$pagePath)
  df$pagePath <- gsub("search_site_no","site_no",df$pagePath)
  df$pagePath <- gsub("Site_no","site_no",df$pagePath)
  df$pagePath <- gsub("multiple_site_no","site_no",df$pagePath)
  df$pagePath <- gsub(", ",",",df$pagePath)
  
  #pull out site_no data in to their own column
  df$site_no <- param_get(urls = df$pagePath, parameter_names = c("site_no"))
  
  #site_no column data character instead of df
  df$site_no <- df$site_no$site_no
  
  #break up multiple site nos separated by commas
  df <- separate_rows(df, site_no, sep=",")
  
  #trim extraneous white space from around site_no
  df$site_no <- trimws(df$site_no, which=c("both"))

  #drop empty site_no rows
  df <- df[!(is.na(df$site_no) | df$site_no==""), ]
  
  #if any exist, break up multiple site nos separated by spaces
  df <- separate_rows(df, site_no, sep=" ")
  
  #only keep numeric site_no data
  df <- subset(df, grepl('^\\d+$', df$site_no))
  
  #keep values at 8 or more characters, likely erroneous if less
  df <- subset(df, nchar(as.character(site_no)) >= 8)
  
  #grab date to put back in data after summarizing totals per site_no
  date <- df$date[1]
  
  #add together uniquePageviews by site_no
  df <- ddply(df,"site_no",numcolwise(sum))
  
  #put date back
  df$date <- date
  
  #keep only columns that we need
  df <- select(df, date, uniquePageviews, site_no)
  
  return(df)
}