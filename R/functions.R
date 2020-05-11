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
