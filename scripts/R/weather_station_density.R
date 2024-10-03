library(readr)
library(dplyr)
library(raster)
library(here)

df <- readr::read_tsv("/Users/mjcecil/Downloads/[X+Y]datatable.tsv")

df_first <- df[1:120,]
df_first[df_first == -999] <- NA
df_first <- rename(df_first, lat = `1200 31 Dec 1947 - 1200 1 Jan 1948`)
df_first <- df_first %>% arrange(-lat)
total_sum_first <- df_first %>%
  unlist() %>%
  sum(., na.rm = T)

# Assuming your data frame is named 'df_first'
# Extract column names (longitudes)
longitudes <- as.numeric(names(df_first)[-1])  # Exclude the 'lat' column

# Set raster values from the data frame
m <- as.matrix(df_first[, -1])  # Exclude the 'lat' column

# Plot the raster
r_first <- raster(m)
extent(r_first) <- c(-130, -55, 20, 50)
plot(r_first)

r_first_agg <- aggregate(r_first, fact = 3, fun = sum)
plot(r_first_agg)
plot(r_first_agg, main = '1948 station density',
     zlim = c(0,20))

df_last <- df[2607430:2607549,]
df_last[df_last == -999] <- NA

df_last <- rename(df_last, lat = `1200 31 Dec 1947 - 1200 1 Jan 1948`)
df_last <- df_last %>% arrange(-lat)
total_sum_last <- df_last %>%
  unlist() %>%
  sum(., na.rm = T)

# Assuming your data frame is named 'df_last'
# Extract column names (longitudes)
longitudes <- as.numeric(names(df_last)[-1])  # Exclude the 'lat' column

# Set raster values from the data frame
m <- as.matrix(df_last[, -1])  # Exclude the 'lat' column

# Plot the raster
r_last <- raster(m)
extent(r_last) <- c(-130, -55, 20, 50)
plot(r_last)

r_last_agg <- aggregate(r_last, fact = 3, fun = sum)

r_last_agg[r_last_agg >= 20] <- 20


png(here("data/outputs/figures/weather_station_density.png"), width = 800, height = 400)
par(mfrow = c(1, 2))
plot(r_first_agg, main = '1948 station density', zlim = c(0,20))
plot(r_last_agg, main = '2007 station density', zlim = c(0,20))
dev.off()


#plot(r_last_agg - r_first_agg)
