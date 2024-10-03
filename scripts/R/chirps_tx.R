library(dplyr)
library(raster)
library(ggplot2)
library(RColorBrewer)
library(scico)
library(sf)
library(here)

tx_chirps_files_folder <- "/Users/mjcecil/Downloads/PRF-RI"

clean_chart_clutter_explore <- 
  theme(    
    panel.grid.major = element_blank(),      # Remove panel grid lines
    panel.grid.minor = element_blank(),      # Remove panel grid lines
    panel.background = element_blank(),      # Remove panel background
    axis.line = element_line(colour = "grey"),       # Add axis line
    axis.title.y = element_text(angle = 0, vjust = 0.5),      # Rotate y axis so don't have to crank head
    legend.position="bottom",
    text = element_text(size = 18),
    axis.text = element_text(size = 18),
    legend.text = element_text(size = 18)
  ) 

tx_chirps_files <- list.files(tx_chirps_files_folder,
                              pattern = "CHIRPS_precip_TX",
                              full.names = T) 

tx_chirps_files_625 <- tx_chirps_files[tx_chirps_files %>% grepl("625.csv", .)]
tx_chirps_files_627 <- tx_chirps_files[tx_chirps_files %>% grepl("627.csv", .)]



df <- read.csv(tx_chirps_files[1])
df_grid <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, GRIDCODE )


r_grid <- rasterFromXYZ(df_grid)
grids <- rasterToPolygons(r_grid, dissolve = TRUE)




tx_chirps_raster_625 <- lapply(tx_chirps_files_625, function(x){
  print(x)
  df <- read.csv(x)
  print(names(df))
  df <-  df %>%
    group_by(GRIDCODE) %>%
    mutate(CHIRPS_precip_agg = mean(CHIRPS_precip, na.rm = TRUE)) %>% ungroup()
  
  df_chirps <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip)
  r_chirps <- rasterFromXYZ(df_chirps)
  
  # df_chirps_agg <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip_agg)
  # r_chirps_agg <- rasterFromXYZ(df_chirps_agg)
  
  return(r_chirps)
  # df_grid <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, GRIDCODE )
  # r_grid <- rasterFromXYZ(df_grid)
  
  #r_chirps_agg <- 
  
  
})
tx_chirps_raster_627 <- lapply(tx_chirps_files_627, function(x){
  print(x)
  df <- read.csv(x)
  print(names(df))
  df <-  df %>%
    group_by(GRIDCODE) %>%
    mutate(CHIRPS_precip_agg = mean(CHIRPS_precip, na.rm = TRUE)) %>% ungroup()
  
  df_chirps <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip)
  r_chirps <- rasterFromXYZ(df_chirps)
  
  # df_chirps_agg <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip_agg)
  # r_chirps_agg <- rasterFromXYZ(df_chirps_agg)
  
  return(r_chirps)
  # df_grid <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, GRIDCODE )
  # r_grid <- rasterFromXYZ(df_grid)
  
  #r_chirps_agg <- 
  
  
})

tx_chirps_raster_625_agg <- lapply(tx_chirps_files_625, function(x){
  print(x)
  df <- read.csv(x)
  print(names(df))
  df <-  df %>%
    group_by(GRIDCODE) %>%
    mutate(CHIRPS_precip_agg = mean(CHIRPS_precip, na.rm = TRUE)) %>% ungroup()
  
  # df_chirps <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip)
  # r_chirps <- rasterFromXYZ(df_chirps)
  
  df_chirps_agg <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip_agg)
  r_chirps_agg <- rasterFromXYZ(df_chirps_agg)
  
  return(r_chirps_agg)
  # df_grid <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, GRIDCODE )
  # r_grid <- rasterFromXYZ(df_grid)
  
  #r_chirps_agg <- 
  
  
})

tx_chirps_raster_627_agg <- lapply(tx_chirps_files_627, function(x){
  print(x)
  df <- read.csv(x)
  print(names(df))
  df <-  df %>%
    group_by(GRIDCODE) %>%
    mutate(CHIRPS_precip_agg = mean(CHIRPS_precip, na.rm = TRUE)) %>% ungroup()
  
  # df_chirps <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip)
  # r_chirps <- rasterFromXYZ(df_chirps)
  
  df_chirps_agg <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, CHIRPS_precip_agg)
  r_chirps_agg <- rasterFromXYZ(df_chirps_agg)
  
  return(r_chirps_agg)
  # df_grid <- df %>% dplyr::select(CHIRPS_LON, CHIRPS_LAT, GRIDCODE )
  # r_grid <- rasterFromXYZ(df_grid)
  
  #r_chirps_agg <- 
  
  
})

tx_chirps_raster_2023_baseline <- stack(tx_chirps_raster_627[1:41]) %>% mean()

tx_chirps_raster_2023_baseline_agg <- stack(tx_chirps_raster_627_agg[1:41]) %>% mean()

tx_chirps_ri_627_2023 <- tx_chirps_raster_627[[43]]/tx_chirps_raster_2023_baseline_agg

tx_chirps_ri_agg_627_2023 <- tx_chirps_raster_627_agg[[43]]/tx_chirps_raster_2023_baseline_agg

chirps_ri_2023_627 <- tx_chirps_ri_627_2023
chirps_ri_2023_627_agg <- tx_chirps_ri_agg_627_2023

d_chirps_2023_627 <- tx_chirps_ri_627_2023 - tx_chirps_ri_agg_627_2023
plot(d_chirps_2023_627)


## read in vector files
tx_counties <- st_read(here("data/Tx_CntyBndry_Jurisdictional_TIGER/Tx_CntyBndry_Jurisdictional_TIGER.shp"))
crs(d_chirps_2023_627) <- "+proj=longlat +datum=WGS84 +nodefs"
tx_counties <- st_transform(tx_counties, crs(d_chirps_2023_627))
brewster <- tx_counties %>% filter(NAME == "Brewster County")
cpc_grids <- st_read("/Users/mjcecil/Downloads/prfri/rainfall_index_grids/official_RMA_RI_grid.shp") %>% 
  st_transform(., st_crs(d_chirps_2023_627))
brewster_grids <- st_crop(cpc_grids, brewster)


## calculate rasters
d_chirps_brewster <- mask(crop(d_chirps_2023_627, brewster), brewster)
chirps_ri_2023_627_brewster <- mask(crop(chirps_ri_2023_627, brewster), brewster)
chirps_ri_2023_627_brewster_agg <- mask(crop(chirps_ri_2023_627_agg, brewster), brewster)

precip_2023_627_brewster <- mask(crop(tx_chirps_raster_627[[43]], brewster), brewster)
precip_2023_627_brewster_agg <- mask(crop(tx_chirps_raster_627_agg[[43]], brewster), brewster)

rcl_matrix <- c(0, 0.9, 1, 0.9, Inf, 0)  %>% matrix(., ncol=3, byrow=TRUE)
payout_2023_627 <- reclassify(chirps_ri_2023_627, rcl_matrix)
payout_2023_627_agg <- reclassify(chirps_ri_2023_627_agg, rcl_matrix)
payout_2023_627_brewster <- mask(crop(payout_2023_627, brewster), brewster)
payout_2023_627_brewster_agg <- mask(crop(payout_2023_627_agg, brewster), brewster)

payout_crosstab <- payout_2023_627_brewster + 2 *payout_2023_627_brewster_agg

d_precip_2023_627_brewster <- precip_2023_627_brewster - precip_2023_627_brewster_agg



ggplot() +
  geom_sf(data = brewster_grids) +
  geom_sf_label(data = brewster_grids, aes(label = GRIDCODE)) +
  ggtitle("Polygon with GRIDCODE Labels")

clip_polygons <- brewster_grids %>%
  filter(GRIDCODE %in% c(12407, 12408, 12409,
                         12107, 12108, 12109))
## clip various rasters
precip_2023_627_brewster_clip <- mask(crop(precip_2023_627_brewster, 
                                      clip_polygons), brewster)
precip_2023_627_brewster_agg_clip <- mask(crop(precip_2023_627_brewster_agg, 
                                          clip_polygons), brewster)
payout_crosstab_clip <- mask(crop(payout_crosstab, 
                             clip_polygons), brewster)
brewster_grids_clip <- clip_polygons


p_brewster <- ggplot(tx_counties) + 
  geom_sf(fill = NA) +
  geom_sf(data = tx_counties %>% filter(NAME == "Brewster County"), fill = 'red') +
  theme_bw() +
  ggtitle("Brewster County") + 
  clean_chart_clutter_explore








# 3 panel plot
png(here('data/outputs/figures/chirps_3_panel_raw.png'), width = 1200, height = 600)
layout(matrix(c(1, 2, 3), nrow = 1, ncol = 3))
par(mar = c(7, 6, 10, 1))


min_precip <- cellStats(precip_2023_627_brewster, "min")
max_precip <- cellStats(precip_2023_627_brewster, "max")
cex_size <- 2
## precip difference
# plot(d_precip_2023_627_brewster, col= scico(20, palette = 'vik') %>% rev(), main = "Precip difference", zlim = c(-15, 15))
# plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
# plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)
# 
# 
# ## RI difference
# plot(d_chirps_brewster, col= scico(20, palette = 'vik') %>% rev(), zlim = c(-0.5, 0.5), main = "RI difference")
# plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
# plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)

## raw CHIRPS precip
par(cex = 1.2)

max_precip <- cellStats(precip_2023_627_brewster, "max")
plot(precip_2023_627_brewster, col= scico(20, palette = 'vik') %>% rev(), zlim = c(min_precip, max_precip),
     legend = F, cex.axis = 1.5, cex.main = 2)
plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 5)
plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)
title(main = "Fine precip", cex.main = 4, line = 1)  # Adjusted line argument
legend("topright", legend = c("County outline"), 
       fill = c( NA), border = c('red'), 
       bg = 'white',
       cex = 3, pt.cex = 5, pt.lwd = 5)
par(cex = 1.2)

## raw CHIRPS agg precip
plot(precip_2023_627_brewster_agg, col= scico(20, palette = 'vik') %>% rev(), zlim = c(min_precip, max_precip),
    axes = FALSE, legend.width = 4, cex.main = 2)
title(main = "Coarse precip", cex.main = 4, line = 1)  # Adjusted line argument
#scalebar(50, below = "Distance (km)", type = 'bar', cex = 1.5)
plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 5)
plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)
#legend("topright", legend = c("County outline"), fill = c( NA), border = c('red'), cex = cex_size)
scalebar(50, below = "Distance (km)", type = 'bar', cex = 3, xy = c(-102.95, 29))
par(cex = 1.2)

## payout difference
my_colors <- c("blue", "green", "yellow", "orange")
plot(payout_crosstab, 
     legend = FALSE,
     col = my_colors,
     zlim = c(0,3), 
     axes = FALSE,
     xlim = c(-103.8, -102),
     cex.main = 2)
title(main = "Payouts", cex.main = 4, line = 1)  # Adjusted line argument
#scalebar(50, below = "Distance (km)", type = 'bar', cex = 1.5)
plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 5)
plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)
# legend("topright", 
#        legend = c("No payout", "CHIRPS payout", "CHIRPS agg payout", "Both payout"), 
#        fill = my_colors,
#        cex = 1.5)
#legend("topright", legend = c("County outline"), fill = c( NA), border = c('red'), cex = cex_size)
legend("bottomright", 
       legend = expression("None", RI[fine], RI[coarse], Both), 
       fill = c(my_colors, NA),
       border = c(rep(NA, 4), 'red'),
       cex = 3, pt.cex = 5,
       title = "Payout",
       title.adj = 0.2,           # Left-justify the title
       title.font = 2)
dev.off()

##
# 0 = no payout
# 1 = fine-scale only
# 2 = coarse only
# 3 = both
print(table(values(payout_crosstab_clip)))

# Calculate total number of pixels
total_pixels <- length(values(payout_crosstab_clip))

# Calculate percentage frequencies
percentage_frequencies <- (table(values(payout_crosstab_clip))/ total_pixels) * 100

# Print the percentage frequencies table
print(percentage_frequencies)

# TX brewster  plot

png(here('data/outputs/figures/tx_brewster.png'), width = 900, height = 900)

par(cex = 1.2)
plot(st_geometry(tx_counties), main = "Brewster County TX")
plot(tx_counties %>% filter(NAME == "Brewster County"), 
     col = 'red', 
     add = T)


dev.off()



# 3 panel plot - clip
png(here('data/outputs/figures/chirps_3_panel_raw_clip.png'), width = 1200, height = 600)
layout(matrix(c(1, 2, 3), nrow = 1, ncol = 3))
par(mar = c(7, 6, 7, 6))


min_precip <- cellStats(precip_2023_627_brewster_clip, "min")
max_precip <- cellStats(precip_2023_627_brewster_clip, "max")

## precip difference
# plot(d_precip_2023_627_brewster, col= scico(20, palette = 'vik') %>% rev(), main = "Precip difference", zlim = c(-15, 15))
# plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
# plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)
# 
# 
# ## RI difference
# plot(d_chirps_brewster, col= scico(20, palette = 'vik') %>% rev(), zlim = c(-0.5, 0.5), main = "RI difference")
# plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
# plot(st_geometry(brewster_grids), fill = NA, border = 'grey', add = T, lwd = 2)

## raw CHIRPS precip
par(cex = 1.2)

max_precip <- cellStats(precip_2023_627_brewster, "max")
plot(precip_2023_627_brewster_clip, col= scico(20, palette = 'vik') %>% rev(), main = "CHIRPS precip", zlim = c(min_precip, max_precip),
     legend.width = 2)
scalebar(25, below = "Distance (km)", type = 'bar', cex = 1.5)

plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
plot(st_geometry(brewster_grids_clip), fill = NA, border = 'grey', add = T, lwd = 2)
legend("topright", legend = c("Brewster County TX"), fill = c( NA), border = c('red'), cex = 1.5)

par(cex = 1.2)

## raw CHIRPS agg precip
plot(precip_2023_627_brewster_agg_clip, col= scico(20, palette = 'vik') %>% rev(), main = "CHIRPS (agg) precip", zlim = c(min_precip, max_precip),
     legend.width = 2, axes = FALSE)
scalebar(25, below = "Distance (km)", type = 'bar', cex = 1.5)
plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
plot(st_geometry(brewster_grids_clip), fill = NA, border = 'grey', add = T, lwd = 2)
legend("topright", legend = c("Brewster County TX"), fill = c( NA), border = c('red'), cex = 1.5)


par(cex = 1.2)

## payout difference
my_colors <- c("blue", "green", "yellow", "orange")
plot(payout_crosstab_clip, legend = FALSE, col = my_colors, zlim = c(0,3), main = "Payout", axes = FALSE)
scalebar(25, below = "Distance (km)", type = 'bar', cex = 1.5)
plot(st_geometry(brewster), fill = NA, border = 'red', add = T, lwd = 2)
plot(st_geometry(brewster_grids_clip), fill = NA, border = 'grey', add = T, lwd = 2)
# legend("topright", 
#        legend = c("No payout", "CHIRPS payout", "CHIRPS agg payout", "Both payout"), 
#        fill = my_colors,
#        cex = 1.5)
legend("topright", 
       legend = c("No payout", "CHIRPS payout", "CHIRPS agg payout", "Both payout", "Brewster County TX"), 
       fill = c(my_colors, NA),
       border = c(rep(NA, 4), 'red'),
       cex = 1.5)

dev.off()




