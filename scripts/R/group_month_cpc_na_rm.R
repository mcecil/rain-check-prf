library(tidyverse)
library(lubridate)
library(stringr)
library(here)

cpc_download_folder <- "/Users/mjcecil/Downloads/cpc_downloads"

# Function to process a single file
process_monthly_files <- function(files) {
  file_1 <- read.csv(files[1])
  monthly_data <- file_1[c('lon', 'lat')]
  for(file in files){
    print(file)
    file_date <- sub("^.*cpc_(\\d{4}-\\d{2}-\\d{2})\\.csv$", "\\1", file)
    file_data <- read.csv(file)
  #  print(file_data)
    monthly_data[[paste0("p_", file_date)]] <- file_data$precip
  }
  monthly_data$lon <- monthly_data$lat <- NULL
#  print(monthly_data)
  monthly_data[monthly_data == -99.9] <- NA
  na_count <- rowSums(is.na(monthly_data))

  return(list(rowSums(monthly_data[,], na.rm = T),
              na_count))
}

# Function to extract month from filename
extract_month <- function(filename) {
  str_extract(basename(filename), "\\d{4}-\\d{2}")
}

replace_dots_in_colnames <- function(df) {
  colnames(df) <- gsub("\\.", "-", colnames(df))
  return(df)
}



# List files matching the pattern (adjust the pattern as needed)
files <- list.files(path = cpc_download_folder,
                    pattern = "cpc_\\d{4}-\\d{2}-\\d{2}.csv",
                    full.names = T)

#files <- files[str_detect(files, "cpc_1948")]

# Create a data frame with file paths and extracted months
file_df <- data.frame(file_path = files,
                      month = extract_month(files))


cpc_data <- read.csv(files[1])
monthly_averages <- cpc_data[c('lon', 'lat')]

for (current_month in unique(file_df$month)){
  month_files <- file_df %>% filter(month == current_month)
  month_precip <- process_monthly_files(month_files$file_path)
 # print(month_precip)
  monthly_averages[[paste0('precip_', current_month)]] <- month_precip[[1]]
  monthly_averages[[paste0('na_count_', current_month)]] <- month_precip[[2]]
}

write.csv(monthly_averages, here("data/outputs/monthly_averages_na_rm.csv"))

# calc index values
monthly_averages <- read.csv(here("data/outputs/monthly_averages_na_rm.csv"))


monthly_averages <- replace_dots_in_colnames(monthly_averages)

#monthly_averages <- monthly_averages %>% filter(lon == 258.375) %>% filter(lat == 32.875)

## calculate interval precipitation
for(year in 1948:2022){
  for(month in 1:11){
    current_interval <- month + 624
    monthly_averages[[paste0("precip_",
                             year,
                             "-",
                             current_interval )]] <-
      monthly_averages[[paste0('precip_', year, "-", str_pad(month,
                                                             2,
                                                             pad = "0"))]] +
      monthly_averages[[paste0('precip_', year, "-", str_pad(month + 1,
                                                             2,
                                                             pad = "0"))]]
  }
}



for(year in 2000:2022){
  print(year)
  for(interval in 625:635){
    current_year_precip <- monthly_averages[[paste0("precip_",
                                                    year,
                                                    "-",
                                                    interval) ]]
    baseline_precip_columns <- paste0("precip_",
                                      1948:(year - 2),
                                      "-",
                                      interval)
    baseline_avg <- rowMeans(monthly_averages[, baseline_precip_columns ])

    monthly_averages[[paste0("cpc_index_", year, "_", interval)]] <- round(current_year_precip/baseline_avg,
                                                                           5)

    baseline_30_precip_columns <- paste0("precip_",
                                      (year - 31):(year - 2),
                                      "-",
                                      interval)

    baseline_30_avg <- rowMeans(monthly_averages[, baseline_30_precip_columns ])

    monthly_averages[[paste0("cpc_index_30_", year, "_", interval)]] <- round(current_year_precip/baseline_30_avg,
                                                                                                5)


    # baseline_2020_columns <- paste0("precip_",
    #                                 1948:2020,
    #                                 "-",
    #                                 interval)
    # monthly_averages[[paste0("cpc_index_2020_baseline", year, "_", interval)]] <- round(current_year_precip/baseline_avg,
    #                                                                        5)
    #
  }
}
write.csv(monthly_averages, here("data/outputs/monthly_averages_na_rm.csv"))


## get NA count by interval
monthly_averages <- read.csv(here("data/outputs/monthly_averages_na_rm.csv"))
monthly_averages <- replace_dots_in_colnames(monthly_averages)

monthly_averages$total_interval_na_count <- rowSums(is.na(monthly_averages %>% select(contains("cpc_index_2"))))

valid_grids <- monthly_averages %>% filter(total_interval_na_count == 0)

cpc_index_columns <- names(valid_grids)[grepl("cpc_index_2", names(valid_grids))]
cpc_index_columns_30 <- names(valid_grids)[grepl("cpc_index_30_", names(valid_grids))]

valid_grids_cpc_index <- valid_grids[,cpc_index_columns]
valid_grids_cpc_index_30 <- valid_grids[,cpc_index_columns_30]

calculate_row_correlation <- function(row1, row2) {
  cor(row1, row2, method = "pearson")
}

calculate_row_correlation_plot <- function(row1, row2, intervals) {
  row1 <- row1 %>% as.numeric()
  row2 <- row2 %>% as.numeric()
  intervals <- intervals %>% as.numeric()
  cor(row1 %>% as.numeric(), row2 %>% as.numeric(), method = "pearson")
  a <- data.frame('cpc_full' = row1,
                  'cpc_30' = row2,
                  'interval' = intervals)
  View(a)
  max_index <- max(row1, row2)
  print(max_index)
  ggplot(a) +
    geom_abline(slope = 1, intercept = 0, color = "red", alpha = 0.5) +
    geom_point(aes(x = cpc_full, y = cpc_30, color = interval), alpha = 0.3) +
    scale_color_viridis_c() +
    xlim(0, max_index) +
    ylim(0, max_index) +
    ggtitle("CPC index comparison, grid 16846") +
    theme_bw()
}

# Iterate over rows and calculate correlations
valid_grids$index_corr <- apply(valid_grids, 1, function(row) {
  calculate_row_correlation(row[cpc_index_columns], row[cpc_index_columns_30])
})



valid_grids$lon <- valid_grids$lon - 360

## TX, make spatial
# library(sf)
# grids_sf <- st_read("/Users/mjcecil/Downloads/prfri/rainfall_index_grids/official_RMA_RI_grid.shp")
# numeric_cols <- c("X_MIN", "X_MAX", "Y_MIN", "Y_MAX")
# 
# for (col in numeric_cols){
#   grids_sf[[col]] <- as.numeric(grids_sf[[col]])
# }
# 
# 
# grids_sf$lon <- grids_sf$X_MIN + ((grids_sf$X_MAX - grids_sf$X_MIN)/2)
# grids_sf$lat <- grids_sf$Y_MIN + ((grids_sf$Y_MAX - grids_sf$Y_MIN)/2)
# 
# grids_sf_merge <- grids_sf %>% left_join(valid_grids, by = c("lon", "lat"))
# 
# grids_sf_merge <- grids_sf_merge %>% filter(!is.na(index_corr))
# ## map correlations in TX
# 
# apply(grids_sf_merge %>% filter(GRIDCODE == 16846), 1, function(row) {
#   intervals <- substr(cpc_index_columns, nchar(cpc_index_columns) - 2, nchar(cpc_index_columns))
#   calculate_row_correlation_plot(row[cpc_index_columns],
#                                  row[cpc_index_columns_30],
#                                  intervals)
# })
# 
# 
# ggplot(grids_sf_merge) +
#   geom_sf(aes(fill = index_corr)) +
#   scale_fill_viridis_c() +
#   theme_bw()## map scatter for min correlation
# 
# 
# 
# grid_row <- 1136
# #grid_row <- 10000
# grid_id <- 11506
# 
# 
# 
# #single_grid_df <- grids_sf_merge[grid_row,]
# single_grid_df <- grids_sf_merge %>% filter(GRIDCODE == grid_id)
# yearly_data <- data.frame(year = 1948:2020)
# 
# interval <- 627
# yearly_data$grid_precip <- sapply(yearly_data$year, function(year){
#   precip <- single_grid_df[[paste0("precip_", year, "-", interval)]][1]
# })
# 
# yearly_data_trunc <- yearly_data %>% filter(year >= 1991)
# yearly_data_trunc$grid_precip_graph <- yearly_data_trunc$grid_precip + 1
# grid_id <- single_grid_df$GRIDCODE[1]
# 
# cpc_baseline_mean <- mean(yearly_data$grid_precip)
# cpc_baseline_mean_30 <- mean(yearly_data_trunc$grid_precip)
# current_year_precip <- single_grid_df[[paste0("precip_2022-", interval)]]
# 
# ri_full <- round(current_year_precip/cpc_baseline_mean, 2)
# ri_30 <- round(current_year_precip/cpc_baseline_mean_30, 2)
# 
# ggplot(yearly_data) +
#   geom_line(aes(x = year, y = grid_precip), colour = 'blue') +
#   geom_point(aes(x = year, y = grid_precip), colour = 'blue') +
#   geom_line(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'red', alpha = 0.9) +
#   geom_point(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'red', alpha = 0.9) +
#   geom_segment(x=1948,xend=2020, y = cpc_baseline_mean, yend=cpc_baseline_mean,
#                colour = 'blue', lty = 'dashed') +
#   geom_segment(x=1991,xend=2020, y = cpc_baseline_mean_30, yend=cpc_baseline_mean_30,
#                colour = 'red', lty = 'dashed') +
#   geom_point(x = 2022, y = single_grid_df[[paste0("precip_2022-", interval)]], size = 3) +
#   theme_bw() +
# #  ggtitle(paste0("Jan Feb precip for grid ID ", grid_id)) +
#   ggtitle(paste0("1948-2022 Mar-Apr precip, grid ID ", grid_id)) +
#   xlab("") +
#   xlim(1948, 2025) +
#   ylab("total Mar-Apr precip") +
#   scale_x_continuous(breaks = seq(from = 1950, to = 2020, by = 10),
#                      labels = seq(from = 1950, to = 2020, by = 10)) +
#   scale_y_continuous(breaks = seq(from = 0, to = 120, by = 20),
#                      labels = seq(from = 0, to = 120, by = 20)) +
#   geom_segment(x=1950,xend=1970, y = 110, y_end = 110,
#                colour = 'red', lty = 'dashed') +
#   geom_text(x = 1965, y = 115, label = paste0("30 year baseline = ", round(cpc_baseline_mean_30), " mm/yr, RI = ", ri_30)) +
#   geom_segment(x=1950,xend=1970, y = 100, y_end = 100,
#                colour = 'blue', lty = 'dashed') +
#   geom_text(x = 1965, y = 105, label = paste0("full baseline = ", round(cpc_baseline_mean), " mm/yr, RI = ", ri_full)) +
#   geom_point(x = 1952, y = 90, size = 3) +
#   geom_text(x = 1963, y = 90, label = paste0("2022 precip = ", round(single_grid_df[[paste0("precip_2012-", interval)]]), " mm"))
# 
# 
# 
# 
# 
# single_grid_df$cpc_index_2012_625
# single_grid_df$cpc_index_30_2012_625

# ## single grid example
# 
# grid_15414_index_values <- (monthly_averages  %>% filter(lon == 258.375) %>% filter(lat == 32.875))[,grepl("cpc_index_", names(monthly_averages))] %>% as.numeric()
# grid_15414_df <- data.frame("index" = grid_15414_index_values)
# 
# 
# write.csv(grid_15414_df, "/Users/mcecil/prfri/grid_15414.csv")
# 
# 
# na_count_df <- monthly_averages %>% select(contains("na_count"))
# na_count_df$total_na_count <- NULL
# na_count_df[na_count_df >= 28] <- NA
# max(na_count_df, na.rm = T)
# table(na_count_df %>% as.matrix())
# 
# 
# 
# na_count_unique <- unique(monthly_averages$total_na_count)
# for(j in na_count_unique){
#   print('na count')
#   print(j)
#   df_filt <- monthly_averages %>% filter(total_na_count == j)
#   df_filt <- df_filt %>% select(contains("precip"))
#   first_row <- df_filt[1, ]
#   find_na_cols(df_filt, 1)
# }
# 
# find_na_cols <- function(df, row_index) {
#   # Get the row as a vector
#   row_data <- df[row_index, ]
# 
#   # Find the indices of NA values
#   na_indices <- which(is.na(row_data))
# 
#   # Get the corresponding column names
#   na_cols <- colnames(df)[na_indices]
# 
#   # Print the column names
#   if (length(na_cols) > 0) {
#     cat("The following columns have NA values in row", row_index, ":\n")
#     print(na_cols)
#   } else {
#     cat("No NA values found in row", row_index, "\n")
#   }
# }
# 
# 
# 
# 
# monthly_average_is_na <- is.na(monthly_averages)
