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
                                  ...) %>% 
      mutate(view_id = view_id, view_name = view_name)
    all_data <- bind_rows(all_data, view_data)
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