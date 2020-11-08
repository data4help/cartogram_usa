# Preliminaries ----
library(maptools)
library(rnaturalearth)
library(cartogram)
library(rgdal)
library(tidyverse)
library("readxl")
library(sf)
library(tmap)
library(urbnmapr)

# Paths
MAIN_PATH = "/Users/paulmora/Documents/projects/cartogram_usa"
RAW_PATH = paste(MAIN_PATH, "/00 Raw", sep="")
CODE_PATH = paste(MAIN_PATH, "/01 Code", sep="")
DATA_PATH = paste(MAIN_PATH, "/02 Data", sep="")
OUTPUT_PATH = paste(MAIN_PATH, "/03 Output", sep="")

# Import ----

# Import country information
states_sf = get_urbn_map("states", sf = TRUE) %>%
  st_transform(states_sf, crs = "+proj=robin")

# Import state abbreviations
state_results_data = read_excel(paste(RAW_PATH, "state_results.xlsx", sep="/"))
colnames(state_results_data) = c("state_abbv", "winner")
state_results_data$democratic_win = if_else(state_results_data$winner=="Blue",
                                            1, 0)
states_w_winner = merge(states_sf, state_results_data, by="state_abbv")

# Get the population and electoral data
pop_data = read_excel(paste(RAW_PATH, "nst-est2019-01.xlsx", sep="/"), skip=3)
select_pop_data = pop_data %>% select("...1", "2019", "Electoral Votes")
colnames(select_pop_data) = c("state_name", "population", "elec_votes")
filtered_data = filter(select_pop_data,
                       str_detect(select_pop_data$state_name, "\\."))
filtered_data$state_name = gsub("\\.", "", filtered_data$state_name)

# Merging ----

# merge the incarceration data into the shape file
combined = merge(states_w_winner, filtered_data, by="state_name", all.x=TRUE)

# Plotting ----
color_list = c("#0015BC", "#FF0000")

# Original map
jpg_file = paste(OUTPUT_PATH, "original_image.jpg", sep="/")
jpeg(jpg_file, width=1920, height=1080)
original_map = combined %>% select(winner, geometry)
original_plot = plot(original_map,
     col=color_list[as.factor(original_map$winner)],
     main="")
dev.off()

# Cartogram by population
usa_cartogram = cartogram_cont(combined["population"], "population",
                               maxSizeError = 1.5)
usa_cartogram$democratic_win = combined$winner
plot = tm_shape(usa_cartogram) +
  tm_fill("democratic_win", palette=color_list,
          legend.show=FALSE) +
  tm_borders("black") +
  tm_layout(main.title="Cartogram by Population - US Election 2020",
            main.title.position="center", fontfamily="Times",
            title.size=2.0, frame = FALSE)
jpg_file = paste(OUTPUT_PATH, "pop_cartogram.jpg", sep="/")
tmap_save(plot, jpg_file, width=1920, height=1080)

# Cartogram by electoral votes
usa_cartogram = cartogram_cont(combined["elec_votes"], "elec_votes",
                               maxSizeError = 1.5)
usa_cartogram$democratic_win = combined$winner
plot = tm_shape(usa_cartogram) +
  tm_fill("democratic_win", palette=color_list,
          legend.show=FALSE) +
  tm_borders("black") +
  tm_layout(main.title="Cartogram by Electoral Votes - US Election 2020",
            main.title.position="center", fontfamily="Times",
            title.size=2.0, frame = FALSE)
jpg_file = paste(OUTPUT_PATH, "ele_cartogram.jpg", sep="/")
tmap_save(plot, jpg_file, width=1920, height=1080)

