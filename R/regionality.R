#' Calculate percent of an application's traffic coming from each state, and 
#' compare with the state's fraction of the US population, for each time period
#' @param df data.frame expects columns view_name, view_id, period (week/month/etc),
#' region (state), and sessions
get_state_traffic_pop_pct <- function(df){
  # get population and percentage of total US population per state
  # 2019 estimated population data, from Census website
  # https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-total.html
  us_pop_raw <- read.csv('in/nst-est2019-alldata.csv') %>% 
    select(REGION, DIVISION, STATE, NAME, POPESTIMATE2019) %>% 
    filter(STATE != 0)
  pop_total <- sum(us_pop_raw$POPESTIMATE2019)
  us_pop <- us_pop_raw %>% 
    mutate(pop_pct = POPESTIMATE2019/pop_total)
  
  # get traffic data based on users by state
  #Puerto Rico is treated as a country by Google-- move it to the region column,
  #and redo summarize
  traffic_us_only <- df %>%
    filter(region %in% state.name | region == "District of Columbia" | country == "Puerto Rico") %>% #drop traffic from outside US
    mutate(region = if_else(country == "Puerto Rico",
                            true = "Puerto Rico",
                            false = region)) %>% 
    group_by(view_name, view_id, period, region) %>% 
    summarize(sessions = sum(sessions)) %>% 
    left_join(us_pop, by = c(region = "NAME"))
  
  # join app traffic w/ population
  all_apps <- unique(traffic_us_only$view_name)
  all_states <- unique(traffic_us_only$region)
  #ensure that all state/application combos represented; some will have zero sessions
  all_states_apps <- expand.grid(view_name = all_apps, region = all_states, stringsAsFactors = FALSE)
  traffic_us_only_padded <- left_join(all_states_apps, traffic_us_only) %>%
    mutate(sessions = ifelse(is.na(sessions), yes = 0, no = sessions)) 
  
  # add total app traffic to traffic by state
  traffic_app_totals <- traffic_us_only_padded %>% 
    group_by(view_name, view_id, period) %>%
    summarize(sessions_total_period = sum(sessions)) %>% 
    na.omit()
  traffic_with_totals <- left_join(traffic_us_only_padded, traffic_app_totals)
  
  # calculate percentage of traffic for each state
  traffic_with_pct <- mutate(traffic_with_totals, 
                             sessions_pct = sessions/sessions_total_period,
                             sessions_population_ratio = sessions_pct / pop_pct)
  return(traffic_with_pct)
}

#' Compute Gini coefficient for sesssions/population ratio for each state and application
#' @param df data.frame Expects columns view_name, view_id, period, and sessions_population_ration
compute_regionality_metric <- function(df){
  df %>% group_by(view_name, view_id, period) %>% 
    summarize(region_metric_all = 1 - ineq::Gini(sessions_population_ratio)) %>% 
    na.omit() 
}

#' Get fraction of last year's traffic in last week for each state and application combo
#' @param df data.frame Expects view_id, view_name, region (i.e. states in Google Analytics),
#' period (week and year values), and sessions columns
compute_week_vs_year <- function(df) {
  df %>% filter(country == "United States") %>%  
    pivot_wider(id_cols = c(view_id, view_name, region), 
                         names_from = period,
                         values_from = sessions) %>% 
    mutate(week_over_year = `7 days` / `365 days`)
}
