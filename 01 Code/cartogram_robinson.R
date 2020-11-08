# install libraries
library(maptools)
library(rnaturalearth)
library(cartogram)
library(rgdal)
library(tidyverse)
library("readxl")
library(sf)

# paths
raw_path = ("C:/Users/PaulM/Dropbox/00 Projects/08 Cartogram/00 Raw/")
output_path = ("C:/Users/PaulM/Dropbox/00 Projects/08 Cartogram/03 Output/")

# get a shapefile for the world
world_map_all = ne_countries(returnclass = "sf")
world_map = world_map_all %>% 
  select(admin) %>%
  filter(admin != "Antarctica") %>%
  st_transform(world_map_all, crs = "+proj=robin")

# get the incarceration data
file_name = ("Global Incarceration Rates.xlsx")
sheet_name = ("Sheet 1 - Khartis_template_worl")
inc_data = read_excel(paste(raw_path, file_name, sep=""), sheet=sheet_name)

# renmae the columns into a more handy format
colnames(inc_data) = c("ID", "NAME", "iso_a3", "prison_pop", "pop_per_100", "pop")

# renaming specific countries for better merge
inc_data = inc_data %>%
  mutate(NAME = replace(NAME, NAME=="United States", "United States of America")) %>%
  mutate(NAME = replace(NAME, NAME=="Bahamas", "The Bahamas")) %>%
  mutate(NAME = replace(NAME, NAME=="Brunei Darussalam", "Brunei")) %>%
  mutate(NAME = replace(NAME, NAME=="Côte d'Ivoire", "Ivory Coast")) %>%
  mutate(NAME = replace(NAME, NAME=="The Gambia", "Gambia")) %>%
  mutate(NAME = replace(NAME, NAME=="Guinea-Bissau", "Guinea Bissau")) %>%
  mutate(NAME = replace(NAME, NAME=="Lao PDR", "Laos")) %>%
  mutate(NAME = replace(NAME, NAME=="North Macedonia", "Macedonia")) %>%
  mutate(NAME = replace(NAME, NAME=="Russian Federation", "Russia")) %>%
  mutate(NAME = replace(NAME, NAME=="Serbia", "Republic of Serbia")) %>%
  mutate(NAME = replace(NAME, NAME=="Timor-Leste", "East Timor")) %>%
  mutate(NAME = replace(NAME, NAME=="Tanzania", "United Republic of Tanzania"))
  
# merge the incarceration data into the shape file
combined = merge(world_map, inc_data, by.x="admin", by.y="NAME", all.x=TRUE)

# filling missing datapoints with zero
combined$pop_per_100[is.na(combined$pop_per_100)] = 0

# plot by the variable prison per 100
carto_wrld = cartogram_cont(combined["prison_pop"], "prison_pop", 
                           maxSizeError = 1.5)
jpg_file = paste(output_path, "prison_pop_robinson.jpg", sep="")
jpeg(jpg_file, height=500, width=950)
par(bg="cadetblue1")
plot(carto_wrld, main="Cartogram by total prison population per 100k", cex.main=2)
dev.off()

# adjusting the map
row_values = as.numeric(rownames(carto_wrld))
carto_wrld$pop_per_100 = combined[row_values,]$pop_per_100
carto_wrld_v1 = subset(carto_wrld, select = -c(prison_pop))

color_list = c('#2f79b5', '#87beda', '#dbeaf2', '#FFFFF7', 
               '#fbe3d4', '#f09c7b', '#c13639')
plot = tm_shape(carto_wrld_v1) +
        tm_fill("pop_per_100", palette=color_list,
                title="Prison Population \n per 100,000") +
        tm_borders() +
        tm_layout(main.title="Cartogram - Total Prison Population by Country",
                  main.title.position="center", 
                  legend.title.size=0.8)
jpg_file = paste(output_path, "both_metrices.jpg", sep="")
tmap_save(plot, jpg_file, width=1920, height=1080)








