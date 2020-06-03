join_to_state_population <- function(viz=as.viz("state_app_traffic")){
  # get population and percentage of total US population per state
  # 2019 estimated population data, from Census website
  # https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
  us_pop_raw <- read.csv('nst-est2019-alldata.csv') %>% 
    select(REGION, DIVISION, STATE, NAME, POPESTIMATE2019) %>% 
    filter(STATE != 0)
  pop_total <- sum(us_pop_raw$POPESTIMATE2019)
  us_pop <- us_pop_raw %>% 
    mutate(pop_pct = POPESTIMATE2019/pop_total)
  
  # get traffic data based on users by state
  traffic_us_only <- df %>%
    filter(region %in% state.name | region == "District of Columbia" | country == "Puerto Rico") %>% #drop traffic from outside US
    mutate(region = if_else(country == "Puerto Rico",
                            true = "Puerto Rico",
                            false = region)) %>% 
    group_by(view_name, view_id, period, region) %>% 
    summarize(sessions = sum(sessions)) %>% 
    left_join(us_pop, by = c(region = "NAME"))
  
  # merge app traffic w/ population
  all_apps <- unique(traffic_us_only$view_name)
  all_states <- unique(traffic_us_only$region)
  all_states_apps <- expand.grid(view_name = all_apps, region = all_states, stringsAsFactors = FALSE)
  traffic_us_only_padded <- left_join(all_states_apps, traffic_us_only) %>%
    mutate(sessions = ifelse(is.na(sessions), 0, sessions)) # NAs --> 0
  
  # add total app traffic to traffic by state
  traffic_app_totals <- traffic_us_only_padded %>% 
    group_by(view_name, view_id, period) %>%
    summarize(sessions_total_period = sum(sessions)) %>% 
    na.omit()
  traffic_with_totals <- left_join(traffic_us_only_padded, traffic_app_totals)
  
  # calculate percentage of traffic for each state
  traffic_with_pct <- mutate(traffic_with_totals, 
                             sessions_pct = sessions/sessions_total_period*100,
                             sessions_population_ratio = sessions_pct / pop_pct)
  return(traffic_with_pct)
}

compute_regionality_metric <- function(df){
  df %>% group_by(view_name, view_id, period) %>% 
    summarize(region_metric_all = 1 - ineq::Gini(sessions_population_ratio)) %>% 
    na.omit() 
}

#' Get fraction of last year's traffic in last week for each state
#'