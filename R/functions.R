#run the same GA API call for multiple views
get_multiple_view_ga_df <- function(view_df, start_date, 
                                    end_date, ...) {
  all_data <- tibble()
  for(i in seq_along(view_df$viewID)) {
    view_id <- view_df$viewID[i]
    view_name <- view_df$shortName[i]
    view_data <- google_analytics(view_id, 
                                  date_range = c(as.Date(start_date), as.Date(end_date)), 
                                  ...) %>% 
      mutate(view_id = view_id, view_name = view_name)
    all_data <- bind_rows(all_data, view_data)
  }
  return(all_data)
}
