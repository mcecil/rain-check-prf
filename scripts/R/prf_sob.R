
library(stringr)
library(ggplot2)
library(gridExtra)
#detach("package:raster", unload = TRUE)
#detach("package:stats", unload = TRUE)
library(dplyr)
library(conflicted)
library(here)
library(stringr)
library(gridExtra)
library(ggpubr)

# Prefer dplyr functions when there's a conflict
conflicted::conflict_prefer("select", "dplyr")
conflicted::conflict_prefer("filter", "dplyr")
## rename files

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

folder_path <- here("data/PRF_sob/raw_files")
file_list <- list.files(folder_path, pattern = "^sobcov.*\\.txt$") 

for (file in file_list){
  print(nchar(file))
  if(nchar(file) == 15){
    file.rename(paste0(folder_path, file),
                paste0(folder_path, str_replace(file, "_20", "" ))
                )
  }
}

data_w_names <- read.csv(here("data/PRF_sob/sobcov_2024_names.csv"))
column_names <- colnames(data_w_names)


prf_df <- data.frame('year' = 2007:2023)

prf_df$policy_count <- NA
prf_df$prf_acre <- NA
prf_df$prf_liability  <- NA
prf_df$prf_subsidy  <- NA
prf_df$prf_indemnity  <- NA
prf_df$prf_premium  <- NA
prf_df$prf_loss_ratio  <- NA
prf_df$non_prf_acre  <- NA
prf_df$non_prf_liability  <- NA
prf_df$non_prf_subsidy  <- NA
prf_df$non_prf_indemnity  <- NA
prf_df$non_prf_premium  <- NA
prf_df$non_prf_loss_ratio  <- NA
prf_df$prf_acre_percent <- NA
prf_df$prf_liability_percent <- NA
prf_df$prf_subsidy_percent <- NA
prf_df$prf_indemnity_percent <- NA
prf_df$prf_subsidy_coverage <- NA


for(year in prf_df$year){
  print(year)
  row_index <- which(prf_df$year == year)
  year_2 <- substr(as.character(year), 3, 4)
  data <- read.csv(here(paste0("data/PRF_sob/raw_files/sobcov", year_2, ".txt")),
                   sep = '|')
  names(data) <- column_names
  
  names(data) <- tolower(names(data))
  data$commodity.name <- tolower(data$commodity.name)
  data$quantity.type<- tolower(data$quantity.type)
  
  pasture_names <- grepl("pasture", unique(data$commodity.name))
  pasture_name <- unique(data$commodity.name)[which(pasture_names)[1]]
  prf_data <- data %>% filter(commodity.name == pasture_name)
  print(nrow(prf_data))
  non_prf_data <- data %>% filter(commodity.name != pasture_name)
  
  acre_names <- grepl("acre", unique(data$quantity.type))
  acre_name <- unique(data$quantity.type)[which(acre_names)[1]]
  
  
  non_prf_data_acres <- non_prf_data %>% filter(quantity.type == acre_name)
  print(nrow(non_prf_data))
  
  prf_policy_count <- sum(prf_data$policies.sold.count)
  
  prf_acre <- sum(prf_data$net.reported.quantity, na.rm = T)
  prf_liability <- sum(prf_data$liability.amount....)
  prf_subsidy <- sum(prf_data$subsidy.amount....)
  prf_indemnity <- sum(prf_data$indemnity.amount....)
  prf_premium <- sum(prf_data$total.premium.amount....)
  prf_loss_ratio <- prf_indemnity/prf_premium
  
  non_prf_acre <- sum(non_prf_data_acres$net.reported.quantity, na.rm = T)
  non_prf_liability <- sum(non_prf_data$liability.amount....  , na.rm = T)
  non_prf_subsidy <- sum(non_prf_data$subsidy.amount....  , na.rm = T)
  non_prf_indemnity <- sum(non_prf_data$indemnity.amount....  , na.rm = T)
  non_prf_premium <- sum(non_prf_data$total.premium.amount....  , na.rm = T)
  non_prf_loss_ratio <- non_prf_indemnity/non_prf_premium
  
  prf_subsidy_coverage <- 100 * (prf_subsidy/prf_premium)
  prf_acre_percent <- 100*(prf_acre /(prf_acre + non_prf_acre))
  prf_liability_percent <- 100*(prf_liability /(prf_liability + non_prf_liability))
  prf_subsidy_percent <- 100*(prf_subsidy /(prf_subsidy + non_prf_subsidy))
  prf_indemnity_percent <- 100*(prf_indemnity /(prf_indemnity + non_prf_indemnity))
  
  prf_df$policy_count[row_index] <- prf_policy_count
  prf_df$prf_acre[row_index] <- prf_acre
  prf_df$prf_liability[row_index]  <- prf_liability
  prf_df$prf_subsidy[row_index]  <- prf_subsidy
  prf_df$prf_indemnity[row_index]  <- prf_indemnity
  prf_df$prf_premium[row_index]  <- prf_premium
  prf_df$prf_loss_ratio[row_index]  <- prf_loss_ratio
  prf_df$non_prf_acre[row_index]  <- non_prf_acre
  prf_df$non_prf_liability[row_index]  <- non_prf_liability
  prf_df$non_prf_subsidy[row_index]  <- non_prf_subsidy
  prf_df$non_prf_indemnity[row_index]  <- non_prf_indemnity
  prf_df$non_prf_premium[row_index]  <- non_prf_premium
  prf_df$non_prf_loss_ratio[row_index]  <- non_prf_loss_ratio
  
  prf_df$prf_subsidy_coverage[row_index] <- prf_subsidy_coverage
  prf_df$prf_acre_percent[row_index] <- prf_acre_percent
  prf_df$prf_liability_percent[row_index] <- prf_liability_percent
  prf_df$prf_subsidy_percent[row_index] <- prf_subsidy_percent
  prf_df$prf_indemnity_percent[row_index] <- prf_indemnity_percent
}

write.csv(prf_df, here('data/outputs/prf_stats.csv'))

prf_df <- read.csv(here('data/outputs/prf_stats.csv'))

colors <- c("test" = "orange")


p_policies <- ggplot(prf_df) + 
  geom_line(aes(x = year, y = policy_count/1000, col = "Policy count"), lwd = 1) + 
  geom_point(aes(x = year, y = policy_count/1000, col = "Policy count"), shape = 1, size = 2) + 
  ylab('Policies sold (thousands)') +
  ggtitle('(a)') + 
  scale_color_manual(values = c("Policy count" = 'orange')) + 
  labs(colour="") +
  theme_bw() + clean_chart_clutter_explore 

p_acres <- ggplot(prf_df) + 
  geom_line(aes(x = year, y = prf_acre/1000000, col = "PRF"), lwd = 1) + 
  geom_point(aes(x = year, y = prf_acre/1000000, col = "PRF"), shape = 1, size = 2) + 
  geom_line(aes(x = year, y = non_prf_acre/1000000, col = "non-PRF"), lwd = 1) + 
  geom_point(aes(x = year, y = non_prf_acre/1000000, col = "non-PRF"), shape = 1, size = 2) + 
  ylab('Acres \n(millions)') +
  xlab("") +
  ggtitle('(a)') + 
  scale_color_manual(values = c("PRF" = 'orange',
                                "non-PRF" = 'grey')) + 
  labs(colour="") +
  theme_bw() + clean_chart_clutter_explore + 
  theme(
    legend.position = c(0.2, 0.5),
    legend.background = element_rect(fill = NA, colour = NA)  # Make background transparent
  ) +

  scale_x_continuous(
    breaks = seq(min(prf_df$year), max(prf_df$year), by = 1),  # Ticks for every year
    labels = function(x) ifelse(x %% 5 == 0, x, "")  # Labels for every 5 years
  ) + 
  scale_y_continuous(
    breaks = seq(0, 300, by = 20),  # Ticks for every 20 units
    labels = function(y) ifelse(y %% 100 == 0, y, "")  # Labels for every 100 units
  ) + 
  ylim(0, 300) 
  


p_money <- ggplot(prf_df) + 
  geom_line(aes(x = year, y = prf_premium/1000000, col = "Premia"), lwd = 1) + 
  geom_point(aes(x = year, y = prf_premium/1000000, col = "Premia"), shape = 1, size = 2) + 
  geom_line(aes(x = year, y = prf_indemnity/1000000, col = "Indemnities"), lwd = 1) + 
  geom_point(aes(x = year, y = prf_indemnity/1000000, col = "Indemnities"), shape = 1, size = 2) + 
  ylab('$\n(millions)') +
  ggtitle('(c)') + 
  scale_color_manual(values = c("Premia" = 'slateblue',
                                "Indemnities" = 'green3')) + 
  labs(colour="") +
  theme_bw() + clean_chart_clutter_explore + 
  theme(legend.position = c(0.2, 0.5)) + 
  scale_x_continuous(
    breaks = seq(min(prf_df$year), max(prf_df$year), by = 1),  # Ticks for every year
    labels = function(x) ifelse(x %% 5 == 0, x, "")  # Labels for every 5 years
  ) 

p_cost <- ggplot(prf_df) + 
  geom_hline(yintercept = 1, col = 'grey') +
  geom_line(aes(x = year, y = prf_loss_ratio, col = "PRF"), lwd = 1) + 
  geom_point(aes(x = year, y = prf_loss_ratio, col = "PRF"), shape = 1, size = 2) + 
 # geom_line(aes(x = year, y = non_prf_loss_ratio, col = "non-PRF"), lwd = 1) + 
 # geom_point(aes(x = year, y = non_prf_loss_ratio, col = "non-PRF"), shape = 1, size = 2) + 
  ylab('Loss \nratio') +
  ggtitle('(b)') + 
  xlab("") +
  scale_color_manual(values = c("PRF" = 'orange')) + 
  labs(colour="") + ylim(0,2) + 
  theme_bw() + clean_chart_clutter_explore +
  theme(legend.position = "none") + 
  scale_x_continuous(
    breaks = seq(min(prf_df$year), max(prf_df$year), by = 1),  # Ticks for every year
    labels = function(x) ifelse(x %% 5 == 0, x, "")  # Labels for every 5 years
  )

p <- grid.arrange(p_acres, arrangeGrob(p_cost, p_money, ncol = 1),
                  ncol = 2)



## 3 figure plot
# p2 <- ggarrange(p_cost, p_money, ncol = 1, nrow = 2, align = 'v')
# a <- ggarrange(p_acres, p2, ncol = 2, nrow = 1)
# 
# 
# png('prf_sob.png',
#     width = 1000,
#     height = 400)
# plot(a)
# dev.off()

## 2 figure plot
p2 <- ggarrange(p_acres, p_cost, ncol = 2, nrow = 1, align = 'h')


png(here('data/outputs/figures/prf_sob.png'),
    width = 1000,
    height = 160)
plot(p2)
dev.off()


pdf(here('data/outputs/figures/prf_sob.pdf'), width = 1000 / 72, height = 160 / 72)
plot(p2)
dev.off()

# 
# pdf(here('data/outputs/figures/prf_sob_plots.pdf'))
# for(name in colnames(prf_df)){
#   if(name == "year"){
#     next
#   }
#   if(name == "y"){
#     next
#   }
#   print(name)
#   prf_df$y <- prf_df[[name]]
#   a <- ggplot(prf_df) + 
#     geom_line(aes(x = year, y = y)) + 
#     ylim(0, max(prf_df$y)) + 
#     ylab(name) + 
#     ggtitle(paste0(name, " by year")) +
#     theme_bw()
#   plot(a)
# }
# 
# dev.off()

