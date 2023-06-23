library(dplyr)
library(ggplot2)
library(sp)
library(rgdal)
library(tmap)
library(sf)
library(cowplot)

path <- "/Users/ram/Documents/Projects/VT/prf-ri"


deviation_df <- read.csv(file.path(path, "./deviation/deviation-count.csv"), stringsAsFactors = FALSE)

# Read CPC grid codes for Texas counties
tx_grids <- read.csv(file.path(path, "./tx-county-grids.csv"), stringsAsFactors = FALSE)

# Filter for CPC grid codes within Texas counties as per the program
tx_deviation_df <- deviation_df %>%
                    filter(GRIDCODE %in% tx_grids$GRIDCODE)

# Read Texas state boundary shapefile
texas <- readOGR(file.path(path, "Texas_State_Boundary"), "State")

# Read CPC grids shapefile
CPC_grids <- readOGR(file.path(path, "CPC_grids_shapefile"), "official_RMA_RI_grid")

# Filter for CPC grid codes within Texas counties
CPC_grids <- CPC_grids[CPC_grids$GRIDCODE %in% tx_grids$GRIDCODE, ]


CPC_grids_deviations <- merge(CPC_grids, tx_deviation_df)


CPC_grids_deviations_90_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "cpc_payout_90_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

CPC_grids_deviations_80_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "cpc_payout_80_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

CPC_grids_deviations_70_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "cpc_payout_70_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

CHIRPS_grids_deviations_90_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "chirps_payout_90_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

CHIRPS_grids_deviations_80_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "chirps_payout_80_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

CHIRPS_grids_deviations_70_map <- tm_shape(texas) +
  tm_borders() +
  tm_shape(CPC_grids_deviations) +
  tm_fill(col = "chirps_payout_70_count", palette = "Blues", legend.show = FALSE) +
  tm_borders(col = "grey60", lwd = 0.5) +
  tm_layout(frame = FALSE)

# legend <- tm_shape(texas) +
#   tm_borders() +
#   tm_shape(CPC_grids_deviations) +
#   tm_fill(col = "chirps_payout_70_count", palette = "Blues", title = "Count") +
#   tm_layout(legend.only= TRUE)

choropleth_panel <- plot_grid(
  tmap_grob(CPC_grids_deviations_90_map), tmap_grob(CHIRPS_grids_deviations_90_map),
  tmap_grob(CPC_grids_deviations_80_map), tmap_grob(CHIRPS_grids_deviations_80_map),
  tmap_grob(CPC_grids_deviations_70_map), tmap_grob(CHIRPS_grids_deviations_70_map),
  ncol = 2
)

choropleth_panel

#ggsave("/Users/ram/Desktop/deviations-1.png", plot = choropleth_panel)
# tmap_save(legend, filename = "/Users/ram/Desktop/chirps_payout_70_count-legend.png")




