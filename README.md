# Jungle Team Recommender

Uses win rates from League of Legends API to determine which jungler should
be played given a list of junglers that you play

## Consists of 3 Parts

* **Get API Data.py** - Python query to get data from API for a given summoner
name and drop it into the `Match_Data` folder

* **Analysis.R** - Uses files in `Match_Data` folder to create regression models
for each jungler as well as a list of all champsions. These are both stored in
the `Analysis_Data` folder

* **app.R** - Shiny app to allow user to input his junglers and his opponents
to get a recomendation for which jungler he should play

## Deployed

Deployed using Google Cloud Run

[Jungle Recommender App](https://serv1-t63g5vlbhq-nn.a.run.app/)
