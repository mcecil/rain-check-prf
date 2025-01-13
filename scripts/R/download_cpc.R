library(devtools)
install_github("ropensci/rnoaa")
# install.packages('vctrs')
# install.packages('tidyverse')
library(rnoaa)
library(sf)
library(tidyverse) # For data manipulation
library(lubridate)
library(here)

start_date <- ymd("1948-01-01")
end_date <- ymd("2023-12-31")

date_seq <- format(seq(start_date, end_date, by = "day"),
                   "%Y-%m-%d")


for (date in date_seq) {
  # Perform operations on each date
  cpc_data <- cpc_prcp(as.character(date), us = TRUE)
  write.csv(cpc_data, file = here(paste0("data/cpc_downloads/cpc_", date, ".csv")))
}













# 
# a <- cpc_prcp("1949-01-01", us = TRUE)
# write.csv(a, file = 'CPC.csv')
# df_spatial <- st_as_sf(a, coords = c("lon", "lat"), crs = 4326)
# 
# 
# for cpc_date in
# tx <- st_read("/Users/mcecil/Downloads/tl_2016_48_cousub/tl_2016_48_cousub.shp")
# 
# tx_rpj <- st_transform(tx, st_crs(df_spatial))
# 
# df_spatial_in_texas <- st_intersects(df_spatial, tx_rpj)
# num_points_in_texas <- sum(df_spatial_in_texas > 0)
# 
# count_non_zero_sgbp <- function(sgbp) {
#   sum(lengths(sgbp))
# }
# count_non_zero_sgbp(df_spatial_in_texas)
