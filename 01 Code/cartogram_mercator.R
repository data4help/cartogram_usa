# install libraries
library(maptools)
library(rnaturalearth)
library(cartogram)
library(rgdal)
library(tidyverse)
library("readxl")
library(sf)
library(tmap)

# Paths
MAIN_PATH = "/Users/paulmora/Documents/projects/cartogram_usa"
RAW_PATH = paste(MAIN_PATH, "/00 Raw", sep="")
CODE_PATH = paste(MAIN_PATH, "/01 Code", sep="")
DATA_PATH = paste(MAIN_PATH, "/02 Data", sep="")
OUTPUT_PATH = paste(MAIN_PATH, "/03 Output", sep="")

states_sf = get_urbn_map("states", sf = TRUE) %>%
  st_transform(states_sf, crs = "+proj=robin") %>%
  select(state_name, geometry)

# Get the voting results from 2016 and adjust the changes manually

# Get the population data
pop_data = read_excel(paste(RAW_PATH, "nst-est2019-01.xlsx", sep="/"), skip=3)
select_pop_data = pop_data %>% select("...1", "2019")
colnames(select_pop_data) = c("state_name", "population")
filtered_data = filter(select_pop_data,
                       str_detect(select_pop_data$state_name, "\\."))
filtered_data$state_name = gsub("\\.", "", filtered_data$state_name)

# merge the incarceration data into the shape file
combined = merge(states_sf, filtered_data, by="state_name", all.x=TRUE)

blue_states = c("")
red_states =


# adjusting the map
row_values = as.numeric(rownames(carto_wrld))
carto_wrld$pop_per_100 = combined[row_values,]$pop_per_100

color_list = c('#2f79b5', '#87beda', '#dbeaf2', '#FFFFF7',
               '#fbe3d4', '#f09c7b', '#c13639')
plot = tm_shape(usa_cartogram) +
  tm_polygons("population") +
  tm_basemap(server="OpenStreetMap",alpha=0.5)


  tm_fill("pop_per_100", palette=color_list,
          title="Prison Population \n per 100,000") +
  tm_borders() +
  tm_layout(main.title="Cartogram - Total Prison Population by Country",
            main.title.position="center",
            legend.title.size=0.8)
jpg_file = paste(output_path, "both_metrices.jpg", sep="")
tmap_save(plot, jpg_file, width=1920, height=1080)


# merge the incarceration data into the shape file
combined = merge(states_sf, filtered_data, by="state_name", all.x=TRUE)
