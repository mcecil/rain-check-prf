library(dplyr)
library(ggplot2)
library(sp)
library(rgdal)
library(tmap)
library(sf)



library(cowplot)

path <- "/Users/ram/Documents/Projects/VT/prf-ri"


deviation_df <- read.csv(file.path(path, "./deviation/deviation-count-2021.csv"), stringsAsFactors = FALSE)

# Read Texas state boundary shapefile
texas <- readOGR(file.path(path, "./state-data/texas/state-boundary"), "State")

# Read CPC grids shapefile
CPC_grids <- readOGR(file.path(path, "CPC_grids_shapefile"), "official_RMA_RI_grid")

# Read CPC grid codes for Texas counties
tx_grids <- read.csv(file.path(path, "./state-data/texas/cpc-grid-codes.csv"), stringsAsFactors = FALSE)

# Filter for CPC grid codes within Texas counties
CPC_grids <- CPC_grids[CPC_grids$GRIDCODE %in% tx_grids$GRIDCODE, ]

tx_deviation_df <- deviation_df %>%
  filter(GRIDCODE %in% tx_grids$GRIDCODE)

tx_deviation_df <- tx_deviation_df %>%
  group_by(GRIDCODE) %>%
  summarise(total_cpc_90 = sum(cpc_payout_90_count),
            total_cpc_70 = sum(cpc_payout_70_count),
            total_chirps_90 = sum(chirps_payout_90_count),
            total_chirps_70 = sum(chirps_payout_70_count))

CPC_grids_deviations <- merge(CPC_grids, tx_deviation_df)

create_grids_deviation_map <- function(data) {
  grids_deviation_map <- tm_shape(texas) +
    tm_borders() +
    tm_shape(CPC_grids_deviations) +
    # Setting fixed style so that all maps have consistent comparable scale
    tm_fill(col = data, palette = "Blues",  style = "fixed", breaks = c(0, 1, 21, 41, 61, 81, 101, 121, 140),
            legend.show = FALSE) +
    tm_borders(col = "grey60", lwd = 0.5) +
    tm_layout(frame = FALSE)

  return(tmap_grob(grids_deviation_map))
}


plot_grid(
  create_grids_deviation_map("total_cpc_90"), create_grids_deviation_map("total_chirps_90"),
  create_grids_deviation_map("total_cpc_70"), create_grids_deviation_map("total_chirps_70"),
  ncol = 2
)

# tx_deviation_df %>%
#   summarise(total = sum(cpc_payout_90_count) + sum(chirps_payout_90_count)  + sum(both_payout_90) + sum(neither_payout_90)
#             )
#   
# tx_deviation_df %>%
#   group_by(GRIDCODE) %>%
#   summarise(count = n())

# tx_deviation_df %>%
#   distinct(GRIDCODE) %>%
#   summarise(count = n())



# tx_deviation_df %>%
#   summarise(across(everything(), ~ sum(is.na(.))))



# tmap_save(create_grids_deviation_map("total_cpc_90"), filename = file.path("/Users/ram/Desktop/", "dev-cpc-90.png"))
# tmap_save(create_grids_deviation_map("total_cpc_80"), filename = file.path("/Users/ram/Desktop/", "dev-cpc-80.png"))
# tmap_save(create_grids_deviation_map("total_cpc_70"), filename = file.path("/Users/ram/Desktop/", "dev-cpc-70.png"))
# 
# tmap_save(create_grids_deviation_map("total_chirps_90"), filename = file.path("/Users/ram/Desktop/", "dev-chirps-90.png"))
# tmap_save(create_grids_deviation_map("total_chirps_80"), filename = file.path("/Users/ram/Desktop/", "dev-chirps-80.png"))
# tmap_save(create_grids_deviation_map("total_chirps_70"), filename = file.path("/Users/ram/Desktop/", "dev-chirps-70.png"))
#ggsave(file.path("/Users/ram/Desktop/", "deviations.png"), plot = choropleth_panel)


# create_legend <- function(data) {
#   legend <- tm_shape(texas) +
#     tm_borders() +
#     tm_shape(CPC_grids_deviations) +
#     tm_fill(col = data, palette = "Blues", title = "Count", style = "fixed", breaks = c(0, 1, 21, 41, 61, 81, 101, 121, 140)) +
#     tm_layout(legend.only = TRUE)
# 
#   return(legend)
# }
# create_legend("total_cpc_90")
# 
# tmap_save(create_legend("total_cpc_90"), filename = file.path("/Users/ram/Desktop/", "deviation-legend.png"))




