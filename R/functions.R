#run the same GA API call for multiple views
get_multiple_view_ga_df <- function(view_df, start_date, 
                                    end_date, ...) {
  all_data <- tibble()
  for(i in seq_along(view_df$viewID)) {
    view_id <- view_df$viewID[i]
    view_name <- view_df$longName[i]
    print(view_name)
    view_data <- google_analytics(view_id, 
                                  date_range = c(as.Date(start_date), as.Date(end_date)),
                                  ...) 
    if(!is.null(view_data)) {
      view_data_augmented <- view_data %>% 
        mutate(view_id = view_id, view_name = view_name)
      all_data <- bind_rows(all_data, view_data_augmented)
    }
  }
  return(all_data)
}

#' Wrapper for arrow::write_parquet to accept a dataframe/tibble
#' @param df a data frame
#' @param sink character sink argument to arrow::write_parquet
write_df_to_parquet <- function(df, sink) {
  write_parquet(Table$create(df), sink = sink)
}


#' convert a year to date of January 1st of that year
#' @param year a character or numeric year
year_to_jan_1st <- function(year) {
  as.Date(paste0(year, "-01-01"))
}

#' backfill a single data frame.  Meant to be lapply-ed on a nested data frame
#' @param x data frame of a single app
#' @param min_date date to backfill to (inclusive)
backfill_df <- function(x, min_date) {
  if(min_date == min(x$first_of_month)){
    return(x)
  } else {
    latest_missing_date <- min(x$first_of_month) - month(1)
    
    backfill_date_df <- tibble(first_of_month = seq(min_date, latest_missing_date, 
                                                    by = "month"),
                               year = as.character(year(first_of_month)),
                               month = as.character(month(first_of_month)),
                               backfill = TRUE
    )
    backfilled_full_df <- bind_rows(x, backfill_date_df) %>% 
      arrange(first_of_month) %>% 
      fill(everything(), -first_of_month, -year, -month, -backfill, .direction = "up") %>% 
      replace_na(list(backfill = FALSE))
    return(backfilled_full_df)
  }
}

#' Backfill data for each application where missing to a certain date
#' Tableau does the 'from first' percent change calculation from a fixed date.  This
#' function repeats the first date value for each month going back to min_date
#' @param df data.frame a df/tibble of monthly traffic values for multiple applications
#' @param char the earliest month/year that data should be backfilled to, represented
#' as the first day of the month
backfill_app_data <- function(df, min_date) {
  backfilled <- df %>%   
    group_by(view_id, view_name) %>%
    nest() %>% 
    mutate(data = lapply(data, backfill_df, min_date = min_date)) %>% 
    unnest(cols = c(data))
  return(backfilled)
}


#' Function to combine Water Science School and water.usgs.gov
#' Could be generalized further to combine two groups in a grouped
#' data.frame, but not worthwhile for now
#' 
#' @param df data frame expecting certain columns from Google Analytics
#' @param view_name_pattern string that will be matched against the 
#' view_name columns.  All rows that match it will be combined by year/month
#'
add_drupal_natweb_sum <- function(df, view_name_pattern) {
  df_groups_to_sum <- df %>% filter(grepl(x = view_name, pattern = view_name_pattern)) 
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
           view_name = view_name_pattern,
           view_id = view_name_pattern) %>% 
      select(-newSessions, -pageViews, -totalSessionDuration)
  df_plus_new_group <- bind_rows(df, new_group)
  return(df_plus_new_group)
}

#' filter out leap days in a data frame with a 'date' column
remove_leap_days <- function(df) {
  df %>% mutate(month = month(date),
                day = day(date)) %>% 
    filter(!(month == 2 & day == 29))
}


#' Compare a certain number of days to the same time period last year
#' @param df data.frame with a date and sessions column
#' @param last_n_days numeric how many days from the latest date should the comparison be made over?
#' @param period_name character time period label for each row; appended in a new column.  e.g. month, week
compare_sessions_to_last_year <- function(df, last_n_days, period_name) {
  #filter to n days this year, last year, compare
  #assert that each group has at least a certain number of values?
  #need to handle leap years here? (2020 was one)  could just filter leap day out?
  max_date <- max(df$date) #inclusive
  start_date <- max_date - last_n_days + 1 #inclusive, +1 because only have yesterday's data
  max_date_last_year <- max_date - years(1)
  start_date_last_year <- start_date - years(1)
  n_days_this_year <- df %>% filter(date >= start_date, date <= max_date,
                                    sessions > 0) %>% 
    remove_leap_days() %>% 
    group_by(view_name, view_id) %>% 
    summarize(sessions_this_year = sum(sessions), 
              n_this_year = n(),
              first_non_zero_date_this_year = min(date))
  
  n_days_last_year <- df %>% filter(date >= start_date_last_year, 
                                    date <= max_date_last_year,
                                    sessions > 0) %>% 
    remove_leap_days() %>% 
    group_by(view_name, view_id) %>% 
    summarize(sessions_last_year = sum(sessions), 
              n_last_year = n(),
              first_non_zero_date_last_year = min(date))
  #assertthat::assert_that(all(n_days_last_year$n_last_year >= (last_n_days - 1)))
  #assertthat::assert_that(all(n_days_this_year$n_this_year >= (last_n_days - 1)))
  #actually do the comparison
  both_years <- full_join(n_days_this_year, n_days_last_year, by = c("view_name", "view_id")) %>% 
    mutate(percent_change = (sessions_this_year - sessions_last_year)/sessions_last_year * 100,
           # percent_change = ifelse(is.infinite(percent_change) || (n_days_last_year != n_days_this_year), 
           #                          yes = NA, 
           #                          no = percent_change),
           percent_change = case_when(
             first_non_zero_date_last_year != start_date_last_year ~ NA_real_,
             first_non_zero_date_this_year != start_date ~ NA_real_,
             is.infinite(percent_change) ~ NA_real_,
             TRUE ~ percent_change
           ),
           period = period_name)
  return(both_years)
}

#' Get fraction of last year's traffic in last week for each state
#' 