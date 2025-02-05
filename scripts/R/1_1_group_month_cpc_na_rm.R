library(tidyverse)
library(lubridate)
library(stringr)
library(here)

cpc_download_folder <- here("data/cpc_downloads")

# Function to process a month's worth of CPC files
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

# Function to update column names
replace_dots_in_colnames <- function(df) {
  colnames(df) <- gsub("\\.", "-", colnames(df))
  return(df)
}

# List files matching the pattern (adjust the pattern as needed)
files <- list.files(path = cpc_download_folder,
                    pattern = "cpc_\\d{4}-\\d{2}-\\d{2}.csv",
                    full.names = T)

# Create a data frame with file paths and extracted months
file_df <- data.frame(file_path = files,
                      month = extract_month(files))


cpc_data <- read.csv(files[1])
monthly_averages <- cpc_data[c('lon', 'lat')]

for (current_month in unique(file_df$month)){
  month_files <- file_df %>% filter(month == current_month)
  month_precip <- process_monthly_files(month_files$file_path)
  monthly_averages[[paste0('precip_', current_month)]] <- month_precip[[1]]
  monthly_averages[[paste0('na_count_', current_month)]] <- month_precip[[2]]
}


## save output with monthly precipitation sums
write.csv(monthly_averages, here("data/outputs/monthly_averages_na_rm.csv"))

# calc index values
monthly_averages <- read.csv(here("data/outputs/monthly_averages_na_rm.csv"))
monthly_averages <- replace_dots_in_colnames(monthly_averages)

## calculate interval precipitation
for(year in 1948:2023){
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



for(year in 2000:2023){
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


