library(sf)
library(here)


sob_2023 <- read.csv(here("data/PRF_sob/sobcov23.txt"),
                     sep = '|', header = F) %>% filter()

sob_names <- read.csv(here("data/PRF_sob/sobcov_2024_names.csv")) %>% colnames()

colnames(sob_2023) <- sob_names

sob_2023_tx <- sob_2023 %>% 
  filter(Commodity.Name == "Pasture,Rangeland,Forage      ") %>% 
  filter(Location.State.Abbreviation == "TX") 

top_tx_county <- sob_2023_tx %>%
  group_by(Location.County.Name) %>%
  summarize(sum_acres = sum(Net.Reported.Quantity)) %>%
  top_n(1, wt = sum_acres)

# load monthly averages


replace_dots_in_colnames <- function(df) {
  colnames(df) <- gsub("\\.", "-", colnames(df))
  return(df)
}

monthly_averages <- read.csv(here("data/outputs/monthly_averages_na_rm.csv"))
monthly_averages <- replace_dots_in_colnames(monthly_averages)

monthly_averages$total_interval_na_count <- rowSums(is.na(monthly_averages %>% select(contains("cpc_index_2"))))

valid_grids <- monthly_averages %>% filter(total_interval_na_count == 0)
valid_grids$lon <- valid_grids$lon - 360 ## correct longitude so it has negative values in western hemisphere


## TX, make spatial
grids_sf <- st_read(here("data/rainfall_index_grids/official_RMA_RI_grid.shp"))
numeric_cols <- c("X_MIN", "X_MAX", "Y_MIN", "Y_MAX")

for (col in numeric_cols){
  grids_sf[[col]] <- as.numeric(grids_sf[[col]])
}


grids_sf$lon <- grids_sf$X_MIN + ((grids_sf$X_MAX - grids_sf$X_MIN)/2)
grids_sf$lat <- grids_sf$Y_MIN + ((grids_sf$Y_MAX - grids_sf$Y_MIN)/2)

grids_sf_merge <- grids_sf %>% left_join(valid_grids, by = c("lon", "lat")) %>% filter(total_interval_na_count == 0)

## top TX prf county is Brewster
tx_counties <- st_read(here("data/Tx_CntyBndry_Jurisdictional_TIGER/Tx_CntyBndry_Jurisdictional_TIGER.shp"))
tx_counties <- st_transform(tx_counties, st_crs(grids_sf_merge))

grids_join_counties <- st_join(grids_sf_merge, tx_counties) %>% filter(COUNTY == "Brewster")
grids_join_counties$GRIDCODE  

pdf(here('data/outputs/figures/brewster_plots.pdf'))
for (grid_id in grids_join_counties$GRIDCODE){
  single_grid_df <- grids_sf_merge %>% filter(GRIDCODE == grid_id)
  yearly_data <- data.frame(year = 1948:2020)
  
  for (interval in 627:632){
    yearly_data$grid_precip <- sapply(yearly_data$year, function(year){
      precip <- single_grid_df[[paste0("precip_", year, "-", interval)]][1]
    })
    
    yearly_data_trunc <- yearly_data %>% filter(year >= 1991)
    yearly_data_trunc$grid_precip_graph <- yearly_data_trunc$grid_precip + 1
    grid_id <- single_grid_df$GRIDCODE[1]
    
    cpc_baseline_mean <- mean(yearly_data$grid_precip)
    
    cpc_baseline_mean_30 <- mean(yearly_data_trunc$grid_precip)
    
    p <- ggplot(yearly_data) +
      geom_line(aes(x = year, y = grid_precip), colour = 'blue') +
      geom_point(aes(x = year, y = grid_precip), colour = 'blue') +
      geom_line(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'red', alpha = 0.9) +
      geom_point(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'red', alpha = 0.9) +
      geom_segment(x=1948,xend=2020, y = cpc_baseline_mean, yend=cpc_baseline_mean,
                   colour = 'blue', lty = 'dashed') +
      geom_segment(x=1991,xend=2020, y = cpc_baseline_mean_30, yend=cpc_baseline_mean_30,
                   colour = 'red', lty = 'dashed') +
      geom_point(x = 2022, y = single_grid_df[[paste0("precip_2012-", interval)]], size = 3) +
      theme_bw() +
      #  ggtitle(paste0("Jan Feb precip for grid ID ", grid_id)) +
      ggtitle(paste0("interval ", interval, " precip for grid ID ", grid_id)) +
      xlab("") + 
      ylab("precip") +
      ylim(0, max(yearly_data$grid_precip) + 10)
    
    print(p)
  }
}

dev.off()
  
