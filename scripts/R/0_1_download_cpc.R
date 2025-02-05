library(devtools)
install_github("ropensci/rnoaa")
library(rnoaa)
library(here)

start_date <- ymd("1948-01-01")
end_date <- ymd("2023-12-31")

date_seq <- format(seq(start_date, end_date, by = "day"),
                   "%Y-%m-%d")


for (date in date_seq[1:5]) {
  # Perform operations on each date
  cpc_data <- cpc_prcp(as.character(date), us = TRUE)
  write.csv(cpc_data, file = here(paste0("data/cpc_downloads/cpc_", date, ".csv")))
}


