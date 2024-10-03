library(dplyr)
library(ggplot2)
library(sp)
library(rgdal)
library(tmap)

path <- "/Users/ram/Documents/Projects/VT/prf-ri"

# Read Texas county boundaries shapefile 
texas_county <- readOGR(file.path(path, "./state-data/texas/county-boundary"), "County")

# Read Texas county codes
county_codes_df <- read.csv(file.path(path, "./state-data/texas/county-codes.csv"), stringsAsFactors = FALSE)

# Add county codes to Spatial dataframe
texas_county <- merge(texas_county, county_codes_df, by.x = "OBJECTID", by.y = "id")

payout_df <- read.csv(file.path(path, "./payouts/texas/2021-payouts.csv"), stringsAsFactors = FALSE)

# Payout Difference by county
payout_difference_by_county <- payout_df %>%
  mutate(difference = CPC_indemnity - CHIRPS_indemnity) %>%
  group_by(county_code) %>%
  summarise(total_difference = sum(difference)) %>%
  arrange(desc(total_difference))

payout_difference_by_county

texas_county_differences <-  merge(texas_county, payout_difference_by_county)

payout_difference_map <- tm_shape(texas_county_differences) +
  tm_fill(col = "total_difference", title = "Payout Difference (in USD)", palette = "Blues", style = "quantile",
          textNA = "No Enrollments") +
  tm_borders() +
  tm_text(text = "CNTY_NM", size = 0.3) +
  tm_layout(frame = FALSE)

payout_difference_map
# tmap_save(payout_difference_map, filename = file.path(path, "payout-differences.png"))

# # Total CPC indemnity payout by county
# total_CPC_indemnity_by_county <- payout_df %>%
#   group_by(county_code) %>%
#   summarise(total_CPC_payout = sum(CPC_indemnity)) %>%
#   arrange(desc(total_CPC_payout))
# total_CPC_indemnity_by_county
# 
# texas_county_CPC_indemnity <-  merge(texas_county, total_CPC_indemnity_by_county)
# 
# cpc_payout_map <- tm_shape(texas_county_CPC_indemnity) +
#   tm_fill(col = "total_CPC_payout", title = "Indemnity Payout (CPC grids)", palette = "Blues", style = "quantile") +
#   tm_borders() +
#   tm_text(text = "CNTY_NM", size = 0.3) +
#   tm_layout(frame = FALSE)
# 
# cpc_payout_map
# tmap_save(cpc_payout_map, filename = "/Users/ram/Desktop/cpc-payout-quantile-1.png")

# # Total CHIRPS indemnity payout by county
# total_CHIRPS_indemnity_by_county <- payout_df %>%
#   group_by(county_name) %>%
#   summarise(total_CHIRPS_payout = sum(CHIRPS_indemnity)) %>%
#   arrange(desc(total_CHIRPS_payout))
# total_CHIRPS_indemnity_by_county
# texas_county_CHIRPS_indemnity <-  merge(texas_county, total_CHIRPS_indemnity_by_county)
# 
# chirps_payout_map <- tm_shape(texas_county_CHIRPS_indemnity) +
#   tm_fill(col = "total_CHIRPS_payout", title = "Indemnity Payout (CHIRPS grids)", palette = "Blues", style = "quantile") +
#   tm_borders() +
#   tm_text(text = "CNTY_NM", size = 0.3) +
#   tm_layout(frame = FALSE)
# 
# chirps_payout_map
# 
# tmap_save(chirps_payout_map, filename = "/Users/ram/Desktop/chirps-payout-quantile.png")
