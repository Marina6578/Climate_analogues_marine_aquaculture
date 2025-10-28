# Helper and utility functions for processing CMIP6 data
	# For working with CMIP6 netCDFs

# Written by Dave Schoeman (david.schoeman@gmail.com)
	# March-May 2022; modified October 20023


# Packages ---------------------------------------------------------------------

  library(ncdf4)
  library(PCICt)
  library(sf)
  library(tictoc)
  library(terra)
  library(MBC)
  library(easyNCDF)
  library(parallel)
  library(purrr)
  library(furrr)
  library(tidyverse)


# If output folder doesn't exist,  create it -----------------------------------

  make_folder <- function(folder) {
    if(!isTRUE(file.info(folder)$isdir)) dir.create(folder, recursive=TRUE)
    return(folder)
  }


# Get bits of CMIP6 file names -------------------------------------------------

	get_CMIP6_bits <- function(file_name) {
    bits <- str_split(basename(file_name), "_") %>%
			unlist()
		date_start_stop <- bits[7] %>%
		  str_split("[.]") %>%
		  map(1) %>%
			unlist() %>%
			str_split("-") %>%
			unlist()
		if(str_detect(file_name, "_.mon_")) {
		  date_start_stop <- paste0(date_start_stop, c("01", "31"))
		  } # Fix dates for monthly data
		if(str_detect(file_name, "_.year_")) {
		  date_start_stop <- paste0(date_start_stop, c("0101", "1231"))
		  } # Fix dates for annual data
		date_start_stop <- as.Date(date_start_stop, format = "%Y%m%d")
		output <- list(Variable = bits[1],
									 Frequency = bits[2],
									 Model = bits[3],
									 Scenario = bits[4],
									 Variant = bits[5],
									 Grid = bits[6],
									 Year_start = date_start_stop[1],
									 Year_end = date_start_stop[2])
		return(output)
		# e.g., map_df(dir(folder), get_CMIP6_bits)
		}


# Get date-type details from netCDF --------------------------------------------

	netCDF_date_deets <- function(nc_file) {
		require(PCICt)
		require(ncdf4)
		nc <- nc_open(nc_file)
		u <- nc$dim$time$units
		dts <- nc$dim$time$vals
		cdr <- nc$dim$time$calendar
		or <- strsplit(u, " ") %>%
			unlist() %>%
			.[3] %>%
			strsplit("-") %>%
			unlist()
		actual_dts <- as.PCICt(dts*60*60*24, cal = cdr, format = "%m%d%Y", origin = paste(or, collapse = "-")) %>%
			substr(1, 10) %>%
			as.Date()
		return(list(strtDate = actual_dts[1], endDate = actual_dts[length(actual_dts)], calendar = cdr))
	}


# Function to extract unique model–scenario combinations -----------------------

	get_model_scenario_combos <- function(f) {
	  basename(f) %>%
	    map(get_CMIP6_bits) %>%
	    bind_rows() %>%
	    distinct() %>%
	    dplyr::select(Model, Scenario)
	  }


# Get dates from an opened netCDF object ---------------------------------------

	nc_dates <- function(nc) {
	  require(PCICt)
	  require(ncdf4)
	  u <- nc$dim$time$units
	  dts <- nc$dim$time$vals
	  cdr <- nc$dim$time$calendar
	  or <- strsplit(u, " ") %>%
	    unlist() %>%
	    .[3] %>%
	    strsplit("-") %>%
	    unlist()
	  actual_dts <- as.PCICt(dts*60*60*24, cal = cdr, format = "%m%d%Y", origin = paste(or, collapse = "-")) %>%
	    substr(1, 10) %>%
	    as.Date()
	  return(actual_dts)
	}


# Get data from one year only --------------------------------------------------

	get_Year <- function(nc_file, yr, infold, outfold) {
		system(paste0("cdo selyear,", yr, " ", infold, "/", nc_file, " ", outfold, "/", nc_file))
		}


# Get data from range of years --------------------------------------------------

	get_Years <- function(nc_file, yr1, yr2, infold, outfold) {
		bits <- get_CMIP6_bits(nc_file)
			y1 <- year(bits$Year_start)
			y2 <- year(bits$Year_end)
		if(y1 < yr1 | y2 > yr2) {
		  new_name <- nc_file %>%
		    str_split(paste0("_", as.character(y1))) %>%
		    map(1) %>%
		    unlist() %>%
		    paste0(., "_", yr1, "0101-", yr2, "1231.nc")
			system(paste0("cdo selyear,", yr1, "/", yr2, " ", infold, "/", nc_file, " ", outfold, "/", new_name))
			# file.remove(paste0(infold, "/", nc_file))
			} else {
				cat("Nothing to do!")
				cat("\n")
				}
		}


# Function to convert a raster mask to a netCDF --------

	# Based on http://geog.uoregon.edu/bartlein/courses/geog490/week04-netCDF.html#create-and-write-a-netcdf-file
	mask2netCDF4 <- function(x, pth = paste0(getwd(), "/", "Data"),
	                           ncName = "mask.nc",
	                           dname = "tos",
	                           dlname = "tos")	{
	  nc_name <- paste0(pth, "/", ncName) # Input netCDF
	  # Temporary files
  	  nc1 <- nc_name %>%
  	    str_replace(".nc", "_tmp1.nc")
      nc2 <- nc_name %>%
        str_replace(".nc", "_tmp2.nc")
	  r1out <- x[] # Write mask as a matrix
	  # Set up the temporal and spatial dimensions
  	  lon <- terra::xFromCol(x, 1:ncol(x)) # Lons - from raster
  	  nlon <- length(lon)
  	  lat <- yFromRow(x, 1:nrow(x)) # Lats from raster
  	  nlat <- length(lat)
  	  time <- time_length(interval(ymd_hms("1850-01-01-00:00:00"), "1850-01-01"), unit = "day")
  	  nt <- length(time)
  	  tunits <- "days since 1850-01-011 00:00:00.0 -0:00"
	  # Use this to build a multi-layer array
	    tmp_array <- array(r1out, dim=c(nlon, nlat, nt)) # Write as an array
	  # Set neCDF variables and dimensions
  	  londim <- ncdim_def("lon","degrees_east", as.double(lon), calendar = "365_day", longname = "longitude")
  	  latdim <- ncdim_def("lat","degrees_north", as.double(lat), calendar = "365_day", longname = "latitude")
  	  timedim <- ncdim_def("time", tunits, as.double(time), calendar = "365_day", longname = "time")
  	  fillvalue <- missvalue <- 1.00000002004088e+20 # Na values
  	  tmp_def <- ncvar_def(dname,"deg_C", list(londim, latdim, timedim), missvalue, dlname, prec = "double")
	  # Create netCDF file and assign arrays
  	  ncout <- nc_create(nc1, list(tmp_def)) # Don't force it to be netCDF4, or CDO will fail
  	  ncvar_put(ncout, tmp_def, tmp_array)
	  # Put additional attributes into dimension and data variables
  	  ncatt_put(ncout, "lon", "axis", "X")
  	  ncatt_put(ncout, "lat", "axis", "Y")
  	  ncatt_put(ncout, "time", "axis", "T")
  	  system(paste0("nccopy -k 4 ", nc1, " ", nc2)) # Convert to netCDF4 "classic model" mode for CDO to be able to read it
  	  system(paste0("cdo -invertlat ", nc2, " ", nc_name)) # Convert to netCDF4 "classic model" mode for CDO to be able to read it
  	  system(paste0("rm ", nc1, " ", nc2))
	}



# Utility function to check the integrity of processed netCDFs ------------

	check_ncdf <- function(f) {
	  r <- rast(f)
	  st_date <- time(r)[1]
	  end_date <- time(r)[nlyr(r)]
	  correct = (1 + year(end_date) - year(st_date)) * 365 == nlyr(r)
	  if(!correct) {print(basename(f))} else {print("Nope, all good")}
	  }
