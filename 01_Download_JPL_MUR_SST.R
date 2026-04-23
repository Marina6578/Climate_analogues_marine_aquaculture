# 1: Download JPL MUR SST for the bounded area
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # November 2024


# Packages ---------------------------------------------------------------------

  library(tidyverse)
  library(rerddap)


# Set up details ---------------------------------------------------------------

  output_folder <- "/Volumes/Mega_Disk/JPL_MUR_SST"
  xmin <- 140.0
  ymin <- -57.0
  xmax <- 162.0
  ymax <- -36.0
  start_date <- "2003-01-01"
  end_date <- "2014-12-31"


# Get list of dates to extract by month ----------------------------------------

  dts <- as.Date(start_date):as.Date(end_date) %>%
    as.Date() %>%
    tibble(Date = .,
           Year = year(Date),
           Month = month(Date)) %>%
    group_by(Year, Month) %>%
    group_split() %>%
    map(pluck("Date")) %>%
    map(as.character()) %>%
    map(~c(first(.x), last(.x)))


# Function to extract SST by month ---------------------------------------------

  get_sst <- function(d) {
    sstInfo <- info("jplMURSST41")
    nc <- griddap(sstInfo, latitude = c(ymin, ymax), longitude = c(xmin, xmax), time = c(as.character(d[1]), as.character(d[2])), fields = "analysed_sst")
    f <- nc$summary$filename
    out_file <- paste0(output_folder, "/jplMUR41_analysed_sst_", str_remove_all(as.character(d[1]), "-"), "-", str_remove_all(as.character(d[2]), "-"), ".nc")
    file.copy(f, out_file)
    rm(nc)
    terminal_code <- paste0("rm ", paste0(dir("/var/folders/zq/ghpkmdz12r9d_6byxr01c78r0000gq/T//RtmpqhRbcB/R/rerddap", full.names = TRUE, pattern = ".nc"), collapse = " "))
      system(terminal_code)
  }


# Deploy the function ----------------------------------------------------------

  walk(dts, get_sst)

# Goto 2_Merge_JPL_MUR_SST_and_Mean.R
