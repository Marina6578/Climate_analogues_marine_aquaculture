# 4: Merging the Raw CMIP6 data (projections and historical), then trim to the years you want
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# April 2024; edited October 2024

  # We will trim times to the period 1982-2100 because 1982 is the start date of OISST climatologies and few models project beyond 2100.
  # Assumes that you have ONLY historical data and ssp projections; if you have more complex scenarios, you will need to edit the code below

  # *** For simplicity, this code assumes that ALL netCDFs are in the same input folder, and that the input folder contains no other files ***
  # *** Assumes that we have only surface data ***


# Source the helpers -----------------------------------------------------------

	source("Helpers.R")


# Folders and other parameters to set ------------------------------------------

  input_folder <- "/Volumes/Jet_Drive/CMIP_Raw"
  output_folder <- make_folder("/Volumes/Jet_Drive_too/CMIP_merged")
  w <- availableCores(omit = 8)  # Number of workers (parallel processes) to use
  frq <- "Oday" # Can be daily ("Oday"/"Aday"), monthly ("Omon"/"Amon") or annual ("Oyear"/"Ayear"); where "O" indicates ocean, and "A" indicates atmosphere
  hist_year_start <- 1982 # For comparison to OISST, if needed
  hist_year_end <- 2014 # End of CMIP6 historical
  ssp_year_start <- 2015 # Standard for CMIP6
  ssp_year_end <- 2100 # Most models end here...alter if you are working with longer series


# Merge by model and scenario --------------------------------------------------

  # Merge all files you have to hand by variable-frequency-model-scenario combination, except overshoot
    l <- dir(input_folder) %>%
    str_subset("historical", negate = TRUE) %>% # Consider only projections
    str_subset("ssp534-over", negate = TRUE) %>% # Exclude the overshoot scenario, which needs special attention
      map(get_CMIP6_bits) %>%
      map(`[`, c("Variable", "Frequency", "Scenario", "Model")) %>%
      map(bind_cols) %>%
      bind_rows() %>%
      distinct() %>%
      as.list() %>%
      unname()

    do_merge <- function(v, fr, s, m) {
      print(paste0(v, "_", fr, "_", s, "_", m))
      hist_files <- dir(input_folder, full.names = TRUE) %>%
        str_subset(paste0("(?=.*", v, "_", ")(?=.*", fr, "_", ")(?=.*", m, "_", ")(?=.*historical_", ")")) # in reg exp ".*" means any string
      ssp_files <- dir(input_folder, full.names = TRUE) %>%
        str_subset(paste0("(?=.*", v, "_", ")(?=.*", fr, "_", ")(?=.*", m, "_", ")(?=.*", s, "_", ")")) # in reg exp ".*" means any string of any length, so this formulation requires the variable, model and scenario to be in THAT order in a string, with each followed by "_", but with no other real constraints

      files <- c(hist_files, ssp_files)

    # Ignore any files that don't are out of scope for our start and end years
      too_old <- files %>%
        basename() %>%
        map(~get_CMIP6_bits(.x)) %>%
        map("Year_end") %>%  # Get Year_start from each element of the list
        map(~ifelse(as.Date(.x) < as.Date(paste0(hist_year_start, "-01-01")), TRUE, FALSE)) %>%
        unlist() %>%
        files[.]
      too_new <- files %>%
        basename() %>%
        map(~get_CMIP6_bits(.x)) %>%
        map("Year_start") %>%  # Get Year_start from each element of the list
        map(~ifelse(as.Date(.x) > as.Date(paste0(ssp_year_end, "-01-01")), TRUE, FALSE)) %>%
        unlist() %>%
        files[.]
      if(length(c(too_old, too_new)) > 0) {
        files <- files %>% str_subset(paste0(c(too_old, too_new), collapse = "|"), negate = TRUE)
        }
    # Make output file name and merge
      out_file <- ssp_files[1] %>%
        str_replace(input_folder, output_folder) %>%
        str_replace(str_split(basename(.), "_") %>%
                      unlist() %>%
                      pluck(7),
                    paste0(hist_year_start, "0101-", ssp_year_end, "1231.nc"))
      cdo_code <- paste0("cdo -L -selyear,", hist_year_start, "/", ssp_year_end, " -mergetime -selname,", "'", v , "' ", paste0(files, collapse = " "), " ", out_file)
        system(cdo_code)
    }
    plan(multisession, workers = w)
      future_pwalk(l, do_merge)
    plan(sequential)


# Deal with overshoot scenario, if it exists -----------------------------------

    # Merge overshoot files for each model, etc.
    l <- dir(input_folder) %>%
      str_subset("ssp534-over") %>% # Exclude the overshoot scenario, which needs special attention
      map(get_CMIP6_bits) %>%
      map(`[`, c("Variable", "Frequency", "Scenario", "Model")) %>%
      map(bind_cols) %>%
      bind_rows() %>%
      distinct() %>%
      as.list() %>%
      unname()

    do_merge_over <- function(v, fr, s, m) {
      print(paste0(v, "_", fr, "_", s, "_", m))
      pre_over_file <- dir(output_folder, full.names = TRUE) %>% # Note, we use the merged SSP585 as historical, here
        str_subset(paste0("(?=.*", v, "_", ")(?=.*", fr, "_", ")(?=.*", m, "_", ")(?=.*ssp585_", ")")) # in reg exp ".*" means any string
      ssp_files <- dir(input_folder, full.names = TRUE) %>%
        str_subset(paste0("(?=.*", v, "_", ")(?=.*", fr, "_", ")(?=.*", m, "_", ")(?=.*", s, "_", ")")) # in reg exp ".*" means any string of any length, so this formulation requires the variable, model and scenario to be in THAT order in a string, with each followed by "_", but with no other real constraints
      yr1 <- ssp_files[1] %>%
        basename() %>%
        get_CMIP6_bits() %>%
        pluck("Year_start") %>%
        year()
      hist_files <- pre_over_file %>%
        str_replace(output_folder, input_folder) %>%
        str_replace(paste0(ssp_year_end, "1231"), paste0((yr1 - 1), "1231")) %>%
        str_replace("ssp585", "ssp534-over")
      cdo_code <- paste0("cdo -L selyear,", hist_year_start, "/", (yr1 - 1), " ", pre_over_file, " ", hist_files)
        system(cdo_code)

      files <- c(hist_files, ssp_files)

      # Ignore any files that don't are out of scope for end years
      too_new <- files %>%
        basename() %>%
        map(~get_CMIP6_bits(.x)) %>%
        map("Year_start") %>%  # Get Year_start from each element of the list
        map(~ifelse(as.Date(.x) > as.Date(paste0(ssp_year_end, "-01-01")), TRUE, FALSE)) %>%
        unlist() %>%
        files[.]
      if(length(too_new) > 0) {
        files <- files %>% str_subset(too_new, negate = TRUE)
      }
      # Make output file name and merge
      out_file <- ssp_files[1] %>%
        str_replace(input_folder, output_folder) %>%
        str_replace(str_split(basename(.), "_") %>%
                      unlist() %>%
                      pluck(7),
                    paste0(hist_year_start, "0101-", ssp_year_end, "1231.nc"))
      cdo_code <- paste0("cdo -L -selyear,", hist_year_start, "/", ssp_year_end, " -mergetime -selname,", "'", v , "' ", paste0(files, collapse = " "), " ", out_file)
      system(cdo_code)
    }
    plan(multisession, workers = w)
      future_pwalk(l, do_merge_over)
    plan(sequential)

    # Some overshoot projections seem to have duplicated data for 01 March of leap years, so check and delete duplicated dates, where necessary

    files <- dir(output_folder, full.names = TRUE, pattern = "ssp534-over")
    delete_dups <- function(f) {
      dts <- rast(f) %>%
        time()
      dups <- tibble(Date = dts) %>%
        mutate(n = row_number(.),
               Lead = lead(Date),
               ID = ifelse(Date == Lead, n, NA)) %>%
        drop_na(ID) %>%
        pull(ID)
      if(length(dups) > 0) {
        tmp_file <- f %>%
          str_replace(".nc", "_tmp.nc")
        cdo_code <- paste0("cdo -L -delete,timestep=", paste0(dups, collapse = ","), " ", f, " ", tmp_file)
          system(cdo_code)
        system_code <- paste0("rm ", f)
          system(system_code)
        file.rename(tmp_file, f)
        }
      }
    plan(multisession, workers = w)
      future_walk(files, delete_dups)
    plan(sequential)

# Goto 5_ESM_Anomalies.R
