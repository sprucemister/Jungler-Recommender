library(tidyverse)

# Helper Functions
remove_cols_with_less_than_2_factor_levels <- function(my_df){
  
  # identify factors with less than 2 unique values
  factors <- sapply(my_df, is.factor)
  low_levels <- sapply(my_df[factors], function(x) length(levels(x)) < 2)
  
  # remove columns with less than 2 unique factor levels
  my_df <- my_df[factors][, !low_levels]
  
  # display resulting dataframe
  return(my_df)
}


# Read Data CSVs
df1 <- c()
for (i in dir('Match_Data')) {
  if (length(df1) == 0) {
    df1 <- read.csv(paste0('Results_Data/',i))
  } else {
    df1 <- rbind(df1, read.csv(paste0('Results_Data/',i)))
  }
}

# Wrangling
df2 <- df1 %>% 
  filter(position == 'JUNGLE') %>% 
  select(matchid, winloss,champname) %>% 
  right_join(df1, by=c('matchid'), multiple = "all") %>% 
  filter(winloss.x != winloss.y) %>% 
  group_by(matchid, champname.x, winloss.x) %>% 
  reframe(opponents = paste(champname.y),
          position = paste(position)) %>%
  pivot_wider(names_from = opponents, values_from = position) %>% 
  rename(champname = champname.x) %>% 
  rename(winloss = winloss.x) %>% 
  mutate(winloss = case_when(winloss=='True' ~ TRUE,
                              winloss=='TRUE' ~ TRUE,
                              TRUE ~ FALSE)) 

# Get list of all champs
c_champions <- unique(df2$champname)

# Initialize vector to store regression models
c_models <- list(type=any)

# Loop  through champion list and make regression model
for (i in 1:length(c_champions)) {
  print(i)
  print(c_champions[i])
  
  # Get data for this iteration "i" champion
  df_regr_raw <- df2 %>% 
    filter(champname == c_champions[i]) %>% 
    mutate(across(where(is.list), as.character)) %>% 
    mutate(across(c(where(is.character),-matchid, -champname), ~replace(., . == 'NULL', NA))) %>% 
    mutate(across(c(where(is.character),-matchid, -champname), is.na)) %>% 
    mutate(across(c(where(is.logical),-winloss), ~if_else(. == TRUE, FALSE, TRUE))) %>% 
    mutate(across(c(where(is.logical),-winloss), as.factor)) %>% 
    mutate(winloss = case_when(winloss == TRUE ~ 1, TRUE ~ 0)) 
  df_regr <- df_regr_raw %>% 
    select(-winloss, -matchid, -champname) %>% 
    remove_cols_with_less_than_2_factor_levels() %>% 
    cbind(df_regr_raw %>% select(winloss))
    
  
  # Fit regression with error catching
  if (nrow(df_regr) > 1000 | c_champions[i] == 'Gwen') {
    result = tryCatch({
      fit_i <- glm(winloss ~ ., data= df_regr, family=binomial)
      c_models[[c_champions[i]]] <- fit_i
    }, error = function(e) {
      print('Regression Errored')
      c_models[[c_champions[i]]] <- NULL
    })
  } else {
    print('Not 1000 Jungle Games for this Champ')
    c_models[[c_champions[i]]] <- NULL
  }
}
  
# Save output for use by app
saveRDS(c_champions,'Analysis_Data/c_champions.rds')
saveRDS(c_models,'Analysis_Data/c_models.rds')
