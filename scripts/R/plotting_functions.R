

## functions for plotting and exporting tables

ViewWithCommas <- function(df) {
  df_formatted <- df
  # Format numeric columns with commas
  numeric_cols <- sapply(df_formatted, is.numeric)
  df_formatted[numeric_cols] <- lapply(df_formatted[numeric_cols], comma)
  View(df_formatted)
}

load_rda_to_variable <- function(file_path, variable_name) {
  # Load the .rda file
  loaded_objects <- load(file_path)
  
  # Assign the loaded object to the specified variable name
  if (length(loaded_objects) != 1) {
    stop("The .rda file must contain exactly one object.")
  }
  
  assign(variable_name, get(loaded_objects), envir = .GlobalEnv)
}

clean_chart_clutter <- 
  theme(    
    panel.grid.major = element_blank(),      # Remove panel grid lines
    panel.grid.minor = element_blank(),      # Remove panel grid lines
    panel.background = element_blank(),      # Remove panel background
    axis.text.x = element_text(angle = 0, vjust = 0.75), # Rotate x axis label 
    axis.title.y = element_text(angle = 0, vjust = 0.5),      # Rotate y axis so don't have to crank head
    axis.line = element_line(colour = "grey"),       # Add axis line
    legend.position="bottom"  
  )

scale_x_date_custom <- function(data, date_var, type = "year") {
  if(type == "year"){
    data[[date_var]] <- as.Date(paste0(data[[date_var]], "-01-01"))
  }
  scale_x_date(
    date_breaks = "1 year", # Set breaks to occur every year
    date_labels = "%Y", # Format the labels to show only the year
    expand = c(0, 0), # Optionally remove padding
    limits = as.Date(c(min(data[[date_var]]), max(data[[date_var]]))) # Ensure start and end dates are included
  )
}

ggsave.latex <- function(..., caption = NULL, label = NULL, 
                         figure.placement = "hbt", floating = TRUE, 
                         caption.placement = "bottom", 
                         latex.environments = "center") {
  ggsave(...)
  cat("\n\n")
  
  if (floating) {
    cat("\\begin{figure}[", figure.placement, "]\n", sep = "")
  }
  
  cat("    \\begin{", latex.environments, "}\n", sep = "")
  
  if (!is.null(caption) && caption.placement == "top") {
    cat("        \\caption{", caption, "}\n", sep = "")
  }
  
  args <- list(...)
  
  if (is.null(args[["filename"]])) {
    if (is.null(args[["plot"]])) {
      names(args)[which(names(args) == "")[1]] <- "plot"
    }
    args[["filename"]] <- paste(args[["path"]], ggplot2:::digest.ggplot(args[["plot"]]), ".pdf", sep = "")
  } else {
    args[["filename"]] <- paste(args[["path"]], args[["filename"]], sep = "")
  }
  
  if (is.null(args[["width"]])) {
    if (is.null(args[["height"]])) {
      cat("        \\includegraphics[height = 7in, width = 7in]{", args[["filename"]], "}\n", sep = "")
    } else {
      cat("        \\includegraphics[height = ", args[["height"]], ifelse(is.null(args[["units"]]), "in", args[["units"]]), ", width = 7in]{", args[["filename"]], "}\n", sep = "")
    }
  } else {
    if (is.null(args[["height"]])) {
      cat("        \\includegraphics[height = 7in, width = ", args[["width"]], ifelse(is.null(args[["units"]]), "in", args[["units"]]), "]{", args[["filename"]], "}\n", sep = "")
    } else {
      cat("        \\includegraphics[height = ", args[["height"]], ifelse(is.null(args[["units"]]), "in", args[["units"]]), ", width = ", args[["width"]], ifelse(is.null(args[["units"]]), "in", args[["units"]]), "]{", args[["filename"]], "}\n", sep = "")
    }
  }
  
  if (!is.null(caption) && caption.placement == "bottom") {
    cat("        \\caption{", caption, "}\n", sep = "")
  }
  
  if (!is.null(label)) {
    cat("        \\label{", label, "}\n", sep = "")
  }
  
  cat("    \\end{", latex.environments, "}\n", sep = "")
  
  if (floating) {
    cat("\\end{figure}\n")
  }
  
  cat("\n\n")
}

ggsave_ol <- function(plot, name, caption, height = 5, width = 8, placement = "hbt", cap_placement = "bottom"){
  
  plot <- plot +   theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )
  
  a <- ggsave.latex(plot,
                    filename = here(paste0("data/outputs/figures/latex/", name, ".pdf")),  # Output file name
                    caption = caption,
                    label = paste0("fig:", name),
                    height = height,  # in inches
                    width = width,   # in inches
                    figure.placement = placement,
                    caption.placement = cap_placement
  )
  
  b <- ggsave.latex(plot,
                    filename = here(paste0("data/outputs/figures/latex/", name, ".png")),  # Output file name
                    caption = caption,
                    label = paste0("fig:", name),
                    height = height,  # in inches
                    width = width,   # in inches
                    figure.placement = placement,
                    caption.placement = cap_placement
  )
}


sanitize_text_function <- function(x) {
  sapply(x, function(y) {
    if (grepl("^\\*", y)) { 
      gsub("^(\\*)|(\\*)$", "\\\\textbf{\\1}", y) 
    } else {
      gsub("\\$", "\\\\$", y) 
    }
  })
}

xtable_output <- function(df, table_name, caption){
  n_columns <- ncol(df)
  alignment <-   paste0(rep("r", ncol(df) + 1), collapse = "")
  colnames(df) <- sapply(colnames(df), function(x){
    new_col_name <- paste0("\\textbf{", x, "}")
  })
  ## add bold headers
  xtable_df <- xtable(df, 
                      caption =   caption,
                      label = paste0("tab:", table_name),
                      align = alignment # Alignment: r for each column
  )
  
  hline_locations <- c(-1, 0, 0, nrow(df))
  
  ## print to file
  sink(here(paste0("data/outputs/tables/" , table_name, ".tex")) ) # Save output to a file
  print(xtable_df,
        type = "latex", 
        floating = TRUE, 
        table.placement = "htbp", 
        booktabs = TRUE,
        include.rownames = FALSE,  # Remove row names
        sanitize.text.function = sanitize_text_function,  # Prevent escaping of LaTeX formatting
        floating.environment = "table",  # Use "table" environment for floating
        hline.after = hline_locations  # Horizontal lines: top, header, bottom
  )
  
  sink()
  
  ## print to console
  print(xtable_df,
        type = "latex", 
        floating = TRUE, 
        table.placement = "htbp", 
        booktabs = TRUE,
        include.rownames = FALSE,  # Remove row names
        sanitize.text.function = sanitize_text_function,  # Prevent escaping of LaTeX formatting
        floating.environment = "table",  # Use "table" environment for floating
        hline.after = c(-1, 0, nrow(df))  # Horizontal lines: top, header, bottom
  )
}
