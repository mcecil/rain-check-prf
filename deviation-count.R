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

create_grids_deviation_map <- function(data) {
  grids_deviation_map <- tm_shape(texas) +
    tm_borders() +
    tm_shape(CPC_grids_deviations) +
    # Setting fixed style so that all maps have consistent comparable scale
    tm_fill(col = data, palette = "Blues", style = "fixed", breaks = c(1, 201, 401, 601, 801, 1001, 1200),
            legend.show = FALSE) +
    tm_borders(col = "grey60", lwd = 0.5) +
    tm_layout(frame = FALSE)
  
  return(tmap_grob(grids_deviation_map))
}

choropleth_panel <- plot_grid(
  create_grids_deviation_map("cpc_payout_90_count"), create_grids_deviation_map("chirps_payout_90_count"),
  create_grids_deviation_map("cpc_payout_80_count"), create_grids_deviation_map("chirps_payout_80_count"),
  create_grids_deviation_map("cpc_payout_70_count"), create_grids_deviation_map("chirps_payout_70_count"),
  ncol = 2
)

choropleth_panel

# ggsave(file.path(path, "deviations.png"), plot = choropleth_panel)


# create_legend <- function(data) {
#   legend <- tm_shape(texas) +
#     tm_borders() +
#     tm_shape(CPC_grids_deviations) +
#     tm_fill(col = data, palette = "Blues", title = "Count", style = "fixed", breaks = c(1, 201, 401, 601, 801, 1001, 1200)) +
#     tm_layout(legend.only = TRUE)
#   
#   return(legend)
# }
# 
# tmap_save(create_legend("cpc_payout_90_count"), filename = file.path(path, "cpc_payout_90_count-legend.png"))




