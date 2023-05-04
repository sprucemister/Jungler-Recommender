# This script gets data for the recommender data from riot API
## It uses the LolWatcher package which is a wrapper for the Riot API
## To use, fill out the inputs including the summoner name
## choose 1 summoner who has played games in the last 2 weeks
## Games for similar ELO to that summoner will be found

# Packages
import time
import pandas as pd
import datetime
from riotwatcher import LolWatcher, ApiError

# Inputs
lol_watcher = LolWatcher('RGAPI-baef1ba6-472f-4afb-b5c9-54c9b94dbc3c') # API Key
my_region = 'na1'
my_summoner_name = 'Yodesta'
number_of_matches_to_get = 1000000
# Timeout time
timeout = time.time() + 60*60*7 # this is in epoch seconds

# Get My Summoner Info
me = lol_watcher.summoner.by_name(my_region, my_summoner_name)

# Times to interate through in batches for match ID's
current_time = round(time.time())
twoweeksago_time = current_time - 1296000*2 # 1296000 is about 1 week

# Initiaite things for looping 
this_summoner_puuid = me['puuid'] # Current Player being iterated
summoners_puuids_whose_games_have_been_found = [] # Which summoners have I gotten all their games
all_match_ids = []  # All games looked at
all_players = [me['puuid']] # All players in all games looked at

# Initialize Output Data Frame
my_col_list=['matchid','position','champname','winloss']
df = pd.DataFrame(columns=my_col_list)

# Loop until data for desired number of matches is gotten
while len(all_match_ids) < number_of_matches_to_get:
  print('Matches Found:')
  print(len(all_match_ids))
  print('Summoners Looped:')
  print(len(summoners_puuids_whose_games_have_been_found))
  # Get all mathces in last 2 weeks for this_summoner_puuid
  my_match_ids = lol_watcher.match.matchlist_by_puuid(my_region, \
                                                      this_summoner_puuid, \
                                                      type='ranked', \
                                                      count=100, \
                                                      start_time=twoweeksago_time, \
                                                      end_time=current_time)
                                   
  # Add this summoner's matches to list of all matches                   
  all_match_ids.extend(my_match_ids)
  
  # Add this summoner to list of all summoners that have been investigated
  summoners_puuids_whose_games_have_been_found.append(this_summoner_puuid)
  
  # Loop through each match for the current summoner
  for i in range(0,len(my_match_ids)):

    # If this matches has not already been queried from the API, query it    
    if i not in df['matchid']:
      
      # Query API for this match
      this_match = lol_watcher.match.by_id(my_region, my_match_ids[i])
      
      # Get players in the match and add those players to list of all players
      players_in_match = this_match['metadata']['participants']
      all_players.extend(players_in_match)
      
      # For the 10 players in the match, get their champions, roles, etc
      for j in range(0,10):
        storethis_matchid = my_match_ids[i]
        storethis_position = this_match['info']['participants'][j]['teamPosition']
        storethis_champname = this_match['info']['participants'][j]['championName']
        storethis_winloss = this_match['info']['participants'][j]['win']
      
        # Store this match's champions in results dataframe 
        row_to_append = pd.DataFrame([{'matchid':storethis_matchid, \
                                    'position':storethis_position, \
                                    'champname':storethis_champname, \
                                    'winloss':storethis_winloss}])
        
        # Store this match's champions in results dataframe 
        df = pd.concat([df,row_to_append])
      
  # Get next player from list of all found players
  for i in all_players:
    # Only take him if he hasn't already been investigated
    if i not in summoners_puuids_whose_games_have_been_found:
      this_summoner_puuid = i
      break
  # Return to while loop, which continues until desired match count is reached
  ## Or until timeout
  if time.time() > timeout:
    break

# Export To CSV
df.to_csv('Match_Data/my_matches_' + my_summoner_name + '.csv')
current_time
time.localtime()
