library(tidyverse)
library(lubridate)
library(stringr)
library(sf)
#detach(package:raster)
library(dplyr)
library(here)
library(ggtext)
library(conflicted)

# Prefer dplyr functions when there's a conflict
conflicted::conflict_prefer("select", "dplyr")
conflicted::conflict_prefer("filter", "dplyr")

clean_chart_clutter_explore <- 
  theme(    
    panel.grid.major = element_blank(),      # Remove panel grid lines
    panel.grid.minor = element_blank(),      # Remove panel grid lines
    panel.background = element_blank(),      # Remove panel background
    axis.line = element_line(colour = "grey"),       # Add axis line
    axis.title.y = element_text(angle = 0, vjust = 0.5),      # Rotate y axis so don't have to crank head
    legend.position="bottom",
    text = element_text(size = 22),
    axis.text = element_text(size = 22),
    legend.text = element_text(size = 22)
  ) 

## get NA count by interval
replace_dots_in_colnames <- function(df) {
  colnames(df) <- gsub("\\.", "-", colnames(df))
  return(df)
}

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
grids_sf <- st_read(here("data/rainfall_index_grids/official_RMA_RI_grid.shp"))
numeric_cols <- c("X_MIN", "X_MAX", "Y_MIN", "Y_MAX")

for (col in numeric_cols){
  grids_sf[[col]] <- as.numeric(grids_sf[[col]])
}


grids_sf$lon <- grids_sf$X_MIN + ((grids_sf$X_MAX - grids_sf$X_MIN)/2)
grids_sf$lat <- grids_sf$Y_MIN + ((grids_sf$Y_MAX - grids_sf$Y_MIN)/2)

grids_sf_merge <- grids_sf %>% left_join(valid_grids, by = c("lon", "lat"))

grids_sf_merge <- grids_sf_merge %>% dplyr::filter(`na_count_1948-01` < 31)
## map correlations in TX





## Brewster TX plot
#grid_row <- 1136
# grid_id <- 11506
# interval <- 627

## Brewster TX plot 2
#grid_row <- 10000
# grid_id <- 11810
# interval <- 630

## Moffat CO plot
grid_id <- 24684
interval <- 627

#single_grid_df <- grids_sf_merge[grid_row,]
single_grid_df <- grids_sf_merge %>% filter(GRIDCODE == grid_id)
yearly_data <- data.frame(year = 1948:2020)

yearly_data$grid_precip <- sapply(yearly_data$year, function(year){
  precip <- single_grid_df[[paste0("precip_", year, "-", interval)]][1]
})

yearly_data_trunc <- yearly_data %>% filter(year >= 1991)
yearly_data_trunc$grid_precip_graph <- yearly_data_trunc$grid_precip + 1
grid_id <- single_grid_df$GRIDCODE[1]

cpc_baseline_mean <- mean(yearly_data$grid_precip)
cpc_baseline_mean_30 <- mean(yearly_data_trunc$grid_precip)
current_year_precip <- single_grid_df[[paste0("precip_2022-", interval)]]

ri_full <- round(current_year_precip/cpc_baseline_mean, 2)
ri_30 <- round(current_year_precip/cpc_baseline_mean_30, 2)

cpc_baseline_mean_70 <- 0.70 * cpc_baseline_mean
cpc_baseline_mean_30_70 <- 0.70 * cpc_baseline_mean_30


assay <- "Some Assay"

Lines <- list(bquote(paste(.(assay)," ", AC[50], " (",mu,"M)",sep="")))
Lines_full <- list(bquote(paste("full baseline = ", .(round(cpc_baseline_mean)), " mm/yr, ")))
Lines_full_2 <- list(bquote(paste(RI[full], " = ", bold(.(round(current_year_precip))), "/", .(round(cpc_baseline_mean)) , " = ", .(ri_full) ,sep="")))
Lines_30 <- list(bquote(paste("30 year baseline = ", .(round(cpc_baseline_mean_30)), " mm/yr, ") ))
Lines_30_2 <- list(bquote(paste(RI[30], " = ", bold(.(round(current_year_precip))), "/", .(round(cpc_baseline_mean_30)) , " = ", .(ri_30) ,sep="")))

precip_2022 <- round(single_grid_df[[paste0("precip_2022-", interval)]])
baseline_full_label <- round(cpc_baseline_mean)

interval_dict <- month_ranges <- list(
  "625" = "Jan - Feb",
  "626" = "Feb - Mar",
  "627" = "Mar - Apr",
  "628" = "Apr - May",
  "629" = "May - Jun",
  "630" = "Jun - Jul",
  "631" = "Jul - Aug",
  "632" = "Aug - Sep",
  "633" = "Sep - Oct",
  "634" = "Oct - Nov",
  "635" = "Nov - Dec"
)

interval_label <- interval_dict[[as.character(interval)]]

y_max <- max(yearly_data$grid_precip) * 1
annotate_size <- 7

p <- ggplot(yearly_data) +
  geom_line(aes(x = year, y = grid_precip), colour = 'blue', size = 1) +
  geom_point(aes(x = year, y = grid_precip), colour = 'blue') +
  geom_line(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'orange', alpha = 0.9, size = 1) +
  geom_point(data = yearly_data_trunc, aes(x = year, y = grid_precip_graph), colour = 'orange', alpha = 0.9) +
  geom_segment(x=1948, xend=2020, y = cpc_baseline_mean, yend=cpc_baseline_mean,
               colour = 'blue', lty = 'dashed', size = 1) +
  geom_segment(x=1948, xend=2022, y = cpc_baseline_mean_70, yend=cpc_baseline_mean_70,
               colour = 'blue', lty = 'dotdash', size = 1) +
  geom_segment(x=1991, xend=2020, y = cpc_baseline_mean_30, yend=cpc_baseline_mean_30,
               colour = 'orange', lty = 'dashed', size = 1) +
  geom_segment(x= 1948, xend=2022, y = cpc_baseline_mean_30_70, yend=cpc_baseline_mean_30_70,
               colour = 'orange', lty = 'dotdash', size = 1) +
  geom_point(x = 2022, y = single_grid_df[[paste0("precip_2022-", interval)]], size = 3) +
  theme_bw() +
  #  ggtitle(paste0("Jan Feb precip for grid ID ", grid_id)) +
  ggtitle(paste0("Total Interval Rainfall for grid ID ", grid_id, " (Moffat County, CO)")) +
  xlab("") +
  xlim(1948, 2025) +
  ylab(paste0(interval_label, "\nprecip", "\n(mm)")) +
  scale_x_continuous(breaks = seq(from = 1950, to = 2020, by = 10),
                     labels = seq(from = 1950, to = 2020, by = 10)) +
  scale_y_continuous(breaks = seq(from = 0, to = y_max, by = 20),
                     labels = seq(from = 0, to = y_max, by = 20)) +
  geom_segment(x=1990, xend=2010, y = 0.07 * y_max, yend = 0.07 * y_max,
               colour = 'orange', lty = 'dashed', size = 1) +
  annotate("text", x = 1990, y = 0.09 * y_max, label =  do.call(expression, Lines_30),
            hjust = 0, parse = T, size = annotate_size) +
  annotate("text", x = 1990, y = 0 * y_max, label =  do.call(expression, Lines_30_2),
           hjust = 0, parse = T, size = annotate_size) +
  geom_segment(x=1950, xend=1970, y = 0.07 * y_max, yend = 0.07 * y_max,
               colour = 'blue', lty = 'dashed', size = 1) +
  annotate("text", x = 1950, y = 0.09 * y_max, label = do.call(expression, Lines_full), 
            hjust = 0, size = annotate_size) +
  annotate("text", x = 1950, y = 0 * y_max, label = do.call(expression, Lines_full_2), 
           hjust = 0, size = annotate_size) +
  #geom_point(aes(x = 2000, y = 0.75 * y_max), size = 3) +
  # annotate("text", x = 2002, y = 0.75 * y_max, label = paste0("2022 precip = ", precip_2022 , " mm"),
  #           hjust = 0, size = annotate_size) +
  annotate("rect", xmin = 2010, xmax = 2025, ymin = 0.6 * y_max, ymax = 0.8 * y_max, 
           color = "black", fill = "white") + 
  annotate("text", x = 2012, y = 0.7 * y_max, 
           label = paste0("2022 precip = \n", precip_2022, " mm"),
           hjust = 0, size = annotate_size) + 
  annotate("segment", x =2022, xend = 2022, y = 0.6 * y_max, yend = 0.35 * y_max, 
           arrow = arrow(length = unit(0.3, "cm")), size = 1) +  # Create the box with black border
  ylim(0, y_max) + clean_chart_clutter_explore +
  annotate("rect", xmin = 1945, xmax = 1960, ymin = 0.2 * y_max, ymax = 0.35 * y_max, 
           color = "black", fill = "white") +  # Create the box with black border
  annotate("text", x = 1950, y = 0.275 * y_max, label = "Payout \nthresholds", 
           hjust = 0.5, vjust = 0.5, size = annotate_size)  +
  annotate("segment", x = 1954, xend = 1958, y = 0.3 * y_max, yend = 0.3 * y_max, 
           arrow = arrow(length = unit(0.3, "cm")), size = 1) 
plot(p)

png(here(paste0("data/outputs/figures/cpc_baseline_grid_", grid_id, "_interval_", interval, ".png")),
    width = 1000,
    height = 600)
print(p)
dev.off()

pdf(here(paste0("data/outputs/figures/cpc_baseline_grid_", grid_id, "_interval_", interval, ".pdf")),
    width = 1000/72,
    height = 600/72)
print(p)
dev.off()

