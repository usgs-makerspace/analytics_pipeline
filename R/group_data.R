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
  year_df <- group_by_ndays(df, ndays = 365, period_name = "year")
  month_df <- group_by_ndays(df, ndays = 30, period_name = "month")
  week_df <- group_by_ndays(df, ndays = 7, period_name = "week")
  return_df <- bind_rows(year_df, month_df, week_df)
}