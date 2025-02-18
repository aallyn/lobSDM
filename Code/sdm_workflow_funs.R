#### Functions for cmip6 processing  ####
# This file should be sourced to provide the stepping stones for the sdm_workflows pipeline
# Used to either facilitate a {targets} workflow or to build a makefile workflow.


####  Common Resources  ####
library(tidyverse)
library(raster)
library(stringr)

# # Don't want to force this on source
#experiment <- "ssp1_26"

# Common cropping area for all the netcdf files used in this project
study_area <- extent(c(260, 320, 20, 70))

# Common month abbreviations - These exist as a base object
# month_abbrevs <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
month_abbrevs <- month.abb

# Months as 0-padded numerics
months_numeric <- str_pad(seq(from = 1, to = 12, by = 1), width = 2, side = "left", pad = 0)




# # date keys for the different cmip runs
# cmip_date_key_fun <- function(experiment){
#   cmip_date_key <- list(
#   "surf_temp" = list(
#     "historic_runs"        = read_csv('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/DateKeys_historical/surf_temp/surf_temp_historic_runs.csv', col_types = cols()),
#     "future_projections"   = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/surf_temp/surf_temp_future_projections.csv'), col_types = cols()),
#     "extended_projections" = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/surf_temp/surf_temp_over_run.csv'), col_types = cols())),
#   "surf_sal" = list(
#     "historic_runs"        = read_csv('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/DateKeys_historical/surf_sal/surf_sal_historic_runs.csv', col_types = cols()),
#     "future_projections"   = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/surf_sal/surf_sal_future_projections.csv'), col_types = cols()),
#     "extended_projections" = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/surf_sal/surf_sal_over_run.csv'), col_types = cols())),
#   "bot_temp" = list(
#     "historic_runs"        = read_csv('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/DateKeys_historical/bot_temp/bot_temp_historic_runs.csv', col_types = cols()),
#     "future_projections"   = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/bot_temp/bot_temp_future_projections.csv'), col_types = cols()),
#     "extended_projections" = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/bot_temp/bot_temp_over_run.csv'), col_types = cols())),
#   "bot_sal" = list(
#     "historic_runs"        = read_csv('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/DateKeys_historical/bot_sal/bot_sal_historic_runs.csv', col_types = cols()),
#     "future_projections"   = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/bot_sal/bot_sal_future_projections.csv'), col_types = cols()),
#     "extended_projections" = read_csv(paste0('/Users/aallyn/Library/CloudStorage/Box-Box/RES_Data/CMIP6/', experiment,'/DateKeys/bot_sal/bot_sal_over_run.csv'), col_types = cols())
#   )
#   )}



# Making it more flexible for us
cmip_path <- cs_path("res", "CMIP6")

cmip_date_key_fun <- function(experiment, grid = "StGrid_"){
  cmip_date_key <- list(
    "surf_temp" = list(
      "historic_runs"        = read_csv(paste0(cmip_path, 'DateKeys_historical/surf_temp/surf_temp_historic_runs.csv'), col_types = cols()),
      "future_projections"   = read_csv(paste0(cmip_path, experiment,'/DateKeys/surf_temp/surf_temp_future_projections.csv'), col_types = cols()),
      "extended_projections" = read_csv(paste0(cmip_path, experiment,'/DateKeys/surf_temp/surf_temp_over_run.csv'), col_types = cols())),
    "surf_sal" = list(
      "historic_runs"        = read_csv(paste0(cmip_path, 'DateKeys_historical/surf_sal/surf_sal_historic_runs.csv'), col_types = cols()),
      "future_projections"   = read_csv(paste0(cmip_path, experiment,'/DateKeys/surf_sal/surf_sal_future_projections.csv'), col_types = cols()),
      "extended_projections" = read_csv(paste0(cmip_path, experiment,'/DateKeys/surf_sal/surf_sal_over_run.csv'), col_types = cols())),
    "bot_temp" = list(
      "historic_runs"        = read_csv(paste0(cmip_path, 'DateKeys_historical/bot_temp/bot_temp_historic_runs.csv'), col_types = cols()),
      "future_projections"   = read_csv(paste0(cmip_path, experiment,'/DateKeys/bot_temp/bot_temp_future_projections.csv'), col_types = cols()),
      "extended_projections" = read_csv(paste0(cmip_path, experiment,'/DateKeys/bot_temp/bot_temp_over_run.csv'), col_types = cols())),
    "bot_sal" = list(
      "historic_runs"        = read_csv(paste0(cmip_path, 'DateKeys_historical/bot_sal/bot_sal_historic_runs.csv'), col_types = cols()),
      "future_projections"   = read_csv(paste0(cmip_path, experiment,'/DateKeys/bot_sal/bot_sal_future_projections.csv'), col_types = cols()),
      "extended_projections" = read_csv(paste0(cmip_path, experiment,'/DateKeys/bot_sal/bot_sal_over_run.csv'), col_types = cols())
    )
  )}




#### CMIP Loading/Processing  ####




#' @title Import Collection of CMIP Files
#' 
#' @description Load the collection of CMIP6 Scenarios for a selection of variables.
#'
#' @param cmip_var Indication of what variable you want to load with raster::stack()
#' @param experiment Name of the ssp experiment you want to load
#' @param grid Subfolder string for which grid (StGrid or GlorysGrid) to load the collection from
#'
#' @return
#' @export
#'
#' @examples
import_cmip_collection <- function(
    cmip_var = c("bot_sal", "bot_temp", "surf_temp", "surf_sal"),
    experiment = experiment,
    grid = "StGrid",
    os.use = "unix"){
  
  
  # Experiment Folder
  expfolder <- paste0("CMIP6/", experiment)
  
  # CMIP Folder Path
  cmip_path  <- cs_path("RES_Data", expfolder)
  
  
  # Set folder path to single variable extractions
  # These are created in ____
  cmip_var_folder <- switch(
    EXPR = cmip_var,
    "bot_sal"   = paste0(cmip_path, "BottomSal/", grid),
    "bot_temp"  = paste0(cmip_path, "BottomT/", grid),
    "surf_temp" = paste0(cmip_path, "SST/", grid),
    "surf_sal"  = paste0(cmip_path, "SurSalinity/", grid))  
  
  # Get File List, set the source names
  cmip_names <- list.files(
    cmip_var_folder, 
    full.names = F, 
    pattern = ".nc") %>% 
    str_remove(".nc")
  
  cmip_files <- list.files(
    cmip_var_folder, 
    full.names = T, 
    pattern  = ".nc") %>% 
    setNames(cmip_names)
  
  # Set variable name for the different CMIP netcdf files
  var_name <- switch(
    EXPR = cmip_var,
    "bot_sal"   = "so",
    "bot_temp"  = "thetao",
    "surf_temp" = "tos",
    "surf_sal"  = "so")
  
  
  # Open the files and crop them all in one go
  cmip_data <- imap(
    .x = cmip_files, 
    .f = function(cmip_file, cmip_name){
      message(paste0("Opening File: ", cmip_name))
      stack_out <- raster::stack(cmip_file, varname = var_name)
    
    # # Crop it to study area
    # stack_out <- crop(stack_out, study_area)
    
    return(stack_out)})
  
  
  # Return the collection as a list
  return(cmip_data)
  
  
  
}







#' @title Monthly Mean from Climatology
#' 
#' @details Uses the names of each daily layer in the OISST climatology pattern
#' to group the data by month and return a monthly climatology.
#'
#' @param clim_source Raster stack for climatology you want re-grouped to monthly
#' @param month_layer_key If null uses OISST key. Should be named list indicating which layers
#' belong to which group for the desired output. Ex. January is layers 1:31 in OISST Climatology,
#' month_layer_key <- list("Jan" = c(1:31), ...)
#'
#' @return Raster stack of means from original climatology source using new temporal groups.
#'
months_from_clim <- function(clim_source, month_layer_key = NULL){
  
  
  ####  Default Key to get months from Modified ordinal Day
  
  # Uses number key to match months to corresponding the day of year,
  # day of year in climatology honors the 60th as only feb 29th
  # in this system march 1st is always 61, and Dec 31st is always 366
  
  if(is.null(month_layer_key)){
    mod_months <- list(
      "Jan" = c(1:31),    "Feb" = c(32:60),   "Mar" = c(61:91),
      "Apr" = c(92:121),  "May" = c(122:152), "Jun" = c(153:182),
      "Jul" = c(183:213), "Aug" = c(214:244), "Sep" = c(245:274),
      "Oct" = c(275:305), "Nov" = c(306:335), "Dec" = c(336:366))
    
    # Put a capital X in front of each number to  match raster stack names
    mod_months <- map(mod_months, ~ str_c("X", .x))
    message("Using default key for modified ordinal days 0-366")
    month_layer_key <- mod_months} 
  
  
  # Map through the months to get mean of each one from climatology
  monthly_avgs <- map(month_layer_key, function(layer_indices){
      month_mean <- mean(clim_source[[layer_indices]])}) %>%
    stack() %>%
    setNames(names(month_layer_key))
  
  #return the monthly average stack
  return(monthly_avgs)
 }
















#### CMIP Processing  ####


#' @title Get CMIP Dates from DateKeys
#' 
#' @description Use the date keys that were made using xarray to correctly match the raster
#' names to the dates they should be.
#'
#' @param cmip_source name of the cmip file
#' @param cmip_var name of the variable/folder 
#' @param time_dim the length of the time dimension as a back up check for wonky files
#'
#' @return
#' @export
#'
#' @examples
get_cmip_dates <- function(cmip_source, cmip_var, time_dim, swap_stgrid = FALSE){
  # Check that the CMIP6 ID's are in the catalog: 
  # source/member/institution/experiement IDs
  
  # The date keys were originally made with stgrid files,
  # dates will be the same, but we need to handle the file prefix for matching to work
  if(swap_stgrid == TRUE){cmip_source <- str_replace(cmip_source, "GlorysGrid_", "stGrid_")}
  
  # Do the historic runs
  if(cmip_source %in% names(cmip_date_key[[cmip_var]]$historic_runs)){ 
    
    # From the date key, for the variable, get the historic runs and source info
    cmip_dates <- cmip_date_key[[cmip_var]][["historic_runs"]][, cmip_source] %>% 
      pull(1) %>% 
      as.Date() 
  
  # Do the future projections
  } else if(cmip_source %in% names(cmip_date_key[[cmip_var]]$future_projections)){ 
        
    cmip_dates <- cmip_date_key[[cmip_var]][["future_projections"]][, cmip_source] %>% 
          pull(1) %>% 
          as.Date() 
  
  # and lastly, extended projections
  } else if(cmip_source %in% names(cmip_date_key[[cmip_var]]$extended_projections)){ 
            
    cmip_dates <- cmip_date_key[[cmip_var]][["extended_projections"]][, cmip_source] %>% 
          pull(1) %>% 
          as.Date() 
            
  # What to do if not any of them?
  } else if(time_dim == 780){
    
    cmip_dates <- map(
      str_pad(c(1:12), 2, pad = "0", side = "left"), 
      ~ paste0("X", c(1950:2014), ".", .x)) %>% 
      unlist() %>% 
      sort()
          
    } else if(time_dim == 1032){
      mip_dates <- map(
        str_pad(c(1:12), 2, pad = "0", side = "left"), 
        ~ paste0("X", c(2015:2100), ".", .x)) %>% 
        unlist() %>% 
        sort()
      }
  
  return(cmip_dates)}




#' @title Get Climate Reference from CMIP6
#' 
#' @description Return monthly climatology from CMIP6 Data for specified reference period.
#'
#' @param cmip_stack Raster stack of CMIP6 Data Variable
#' @param clim_years Length 2 vector of start and end year for reference period
#'
#' @return Raster stack of monthly climatology for input CMIP6 Variable
#'
cmip_to_clim <- function(cmip_stack = cmip_cropped, clim_years = NULL){
  
  # Use 1982:2011 as default years unless specified
  if(is.null(clim_years)){
    clim_years <- as.character(c(1991:2020))
    message("Using 1991-2020 as Climate Reference Period")
  
    } else {
      clim_years <- as.character(clim_years)
      message(paste0("Using ", clim_years[1], "-", clim_years[2], " as Climate Reference Period"))}
  
  
  # Pull out the names of the cmip layers for matching
  cmip_layers <- names(cmip_stack)
  
  
  
  # # Check the string length for the names to determine format
  # if(str_length(cmip_layers[1]) < 11){
  #   message(paste0("Problem with CMIP Naming Structure"))
  #   return("Ignoring for now")}
  
  
  
  # Pull layers of cmip data for the years of interest for climatology
  cmip_clim_years  <- cmip_stack[[which(str_sub(cmip_layers, 2,5) %in% clim_years)]]
  clim_year_layers <- names(cmip_clim_years)
  
  # Get strings to match the months, set names as abbreviations for later
  month_labels <- str_pad(c(1:12), width = 2, pad = "0", "left")
  month_labels <- setNames(month_labels, month_abbrevs)
  
  # Loop through the months, getting mean across the climatology period
  cmip_clim <- map(month_labels, function(month_index){
    
    # Indices for the month
    cmip_month_indices <- which(str_sub(clim_year_layers, 7,8) == month_index)
    
    # Mean across years
    monthly_clim <- mean(cmip_clim_years[[cmip_month_indices]])
    return(monthly_clim)
    
  }) %>% stack()
  
  # Return the new climatology stack
  return(cmip_clim)

}





#' @title CMIP Monthly Anomalies from Climatology
#'
#' @param cmip_data CMIP Observations
#' @param cmip_clim  Matching Climatology for a given reference period
#'
#' @return Raster stack of dimensions equal to cmip_data but with anomaly values
#' 
cmip_get_anomalies <- function(cmip_data, cmip_clim){
  
  
  # Map though the month key to pull their data, return quantile stack
  month_index <- str_pad(c(1:12), 2, "left", "0")
  
 
  ####  Map through the months
  # month_index are how they are as dates in Xyyyy.mm.dd
  # month abbrevs are how they are named in climatology
  monthly_anoms <- map2(month_index, month_abbrevs, function(month_index, month_abbrev){
    
    # Use month abbreviation to get month from climatology
    clim_month_data <- cmip_clim[[month_abbrev]]
    
    # Use month_index for CMIP layers to match the month
    cmip_layers <- names(cmip_data)
    cmip_month_indices <- which(str_sub(cmip_layers, 7, 8) == month_index)
    cmip_month_labels  <- cmip_layers[cmip_month_indices]
    
    # Pull all layers from the cropped cmip stack with that month
    month_layers <- cmip_data[[cmip_month_indices]]
    
    # Subtract climate average to get anomalies
    month_anoms <- month_layers - clim_month_data
    month_anoms <- setNames(month_anoms, cmip_month_labels)
    
    # Return anomalies for that month across years
    return(month_anoms)
    
    
  }) %>% stack()
  
  return(monthly_anoms)
  
  
}



####  Bias Correction  Functions  ####


#' @title Resample Resolution to Destination Grid Res
#' 
#' @description Takes two raster stacks, resamples starting_grid to resolution of
#' desired_grid. Default method is bilinear interpolation.
#'
#' @param starting_grid Raster stack whose desired resolution you wish to change
#' @param desired_grid Raaster stack with the desired output resolution to use as example grid
#' @param method Optional string indicating method to use for raster::resample(method = method)
#'
#' @return Raster stack with resolution of desired_grid and data from starting_grid
#' 
resample_grid <- function(starting_grid = cmip_anoms, 
                          desired_grid = oisst_month_avgs, 
                          method = "bilinear"){
  starting_grid<- raster::rotate(starting_grid)
  resample(starting_grid, desired_grid[[1]], method = method)
}





#' @title Bias Correction - Delta Method
#' 
#' @description Bias correct climate data using a reference climatology. Performs the delta-method 
#' where anomalies in climate data are applied directly to reference climate.
#'
#' @param cmip_grid Input Grid we want to bias correct the observations for
#' @param reference_climatology The climatology for real-life data to bias correct with
#'
#' @return Raster stack of bias corrected observations
#' 
delta_method_bias_correct <- function(cmip_grid = cmip_anoms_regridded, 
                                      reference_climatology = oisst_month_avgs_91){
  
  # 1. Change climatology names to the numeric ones to streamline the matching
  reference_climatology <- setNames(reference_climatology, months_numeric)
  
  
  # 2. Get dates from cmip in non-raster format - necessary?
  # cmip_dates  <- as.Date(gsub("[.]", "-", gsub("X", "", names(cmip_grid)))) # as dates
  # cmip_dates  <- gsub("[.]", "-", gsub("X", "", names(cmip_grid)))          # as char
  cmip_dates  <- names(cmip_grid)
  
  
  # 3. For each time step, add the anomalies to the climate average from ref data
  # Alright, apply the anomalies (deltas) of the climate model to OISST climatology. 
  cmip_proj_out <- map(seq(1:nlayers(cmip_grid)), function(layer_index) { 
    
    # Grab the first CMIP layer
    cmip_anom_layer <- cmip_grid[[layer_index]]
    
    # Get the corresponding layer number for the reference climatology
    month_digits   <- str_sub( names(cmip_anom_layer)[1] , 7,8)
    layer_match    <- which(str_detect(names(reference_climatology), month_digits))
    ref_clim_layer <- reference_climatology[[layer_match]]
    
    # Add ref clim to anomalies to bias correct them, returns bias-corrected temperature
    delta_out <- cmip_anom_layer + ref_clim_layer}) %>% 
      stack()
  
  # Add their names back
  names(cmip_proj_out) <- cmip_dates
  
  # Sort the order so its in order by year and month
  new_order <- sort(names(cmip_proj_out))
  cmip_proj_out <- cmip_proj_out[[ new_order ]]
  
  return(cmip_proj_out)
  
  
}











####  Processing Mean/5th/95th  ####




#' @title Return Desired Quantile from Collection of Bias Corrected Data
#'
#' @param time_period String determining behavior for historic or projection data. Impacts date 
#' names and subsetting.
#' @param time_period_collection The list of raster stacks corresponding to a collection of bias 
#' corrected historic or projected climate
#' @param quantile_product The desired quantile to return from the function
#'
#' @return
#' @export
#'
#' @examples
time_period_quantile <- function(time_period = c("historic", "projection"),
                                 time_period_collection = historic_bias_corr,
                                 quantile_product = c("mean", "5th", "95th")){
  
  # Number of time steps
  ts_vector <- switch(
    EXPR = time_period,
    "historic" = c(1:780),
    "projection" = c(1:1032)
  )
  
  # What the names should be for output stack, year and month
  name_key <- switch(
    EXPR = time_period,
    "historic"   = map(str_pad(c(1:12), 2, pad = "0", side = "left"), ~ paste0("X", c(1950:2014), ".", .x)) %>% unlist() %>% sort(),
    "projection" = map(str_pad(c(1:12), 2, pad = "0", side = "left"), ~ paste0("X", c(2015:2100), ".", .x)) %>% unlist() %>% sort()
  )
  
  # What quantile function to use
  quant_fun <- switch(
    EXPR = quantile_product,
    "mean" = function(month_subset_ras){calc(month_subset_ras, fun = mean,  na.rm = T)},
    "5th"  = function(month_subset_ras){calc(month_subset_ras, function(rasters){
      quantile(rasters, probs = 0.05, na.rm = T)})},
    "95th" = function(month_subset_ras){calc(month_subset_ras, function(rasters){
      quantile(rasters, probs = 0.95, na.rm = T)})}
  )
  
  

  # Map through the time steps getting the desired quantile at each step
  time_period_quantile <- map(ts_vector, function(time_step){
    
    # Pull the time step
    month_subset_ras <- map(time_period_collection, ~ .x[[time_step]]) %>% stack()
    
    # Grab the desired quantile
    ras_quant <- quant_fun(month_subset_ras)
    return(ras_quant)
    
  }) %>% setNames(name_key) # Set the layer names
  
  
  # return the quantile
  return(time_period_quantile)


}





















# Function to re-stack the different scenarios as singular timelines by stat/quantile:
#takes the list of raster stacks, organized by year, and the corresponding names as a vector or 
# by passing the named list to imap()



####  Memory Checking  ####

####  Memory check Functions  ####
# Source: https://medium.com/@williamr/reducing-memory-usage-in-r-especially-for-regressions-8ed8070ae4d8
# Main function 
.ls.objects <- function (pos = 1, pattern, order.by,
                         decreasing=FALSE, head=FALSE, n=5) {
  napply <- function(names, fn) sapply(names, function(x)
    fn(get(x, pos = pos)))
  names <- ls(pos = pos, pattern = pattern)
  obj.class <- napply(names, function(x) as.character(class(x))[1])
  obj.mode <- napply(names, mode)
  obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
  obj.prettysize <- napply(names, function(x) {
    capture.output(format(utils::object.size(x), units = "auto")) })
  obj.size <- napply(names, object.size)
  obj.dim <- t(napply(names, function(x)
    as.numeric(dim(x))[1:2]))
  vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
  obj.dim[vec, 1] <- napply(names, length)[vec]
  out <- data.frame(obj.type, obj.size, obj.prettysize, obj.dim)
  names(out) <- c("Type", "Size", "PrettySize", "Rows", "Columns")
  if (!missing(order.by))
    out <- out[order(out[[order.by]], decreasing=decreasing), ]
  if (head)
    out <- head(out, n)
  out
}


# Shorthand function for easy access of memory use
lsos <- function(..., n = 10) {
  .ls.objects(..., order.by = "Size", decreasing = TRUE, head = TRUE, n = n)
}




####  OISST Processing  ####


#' @title Import OISST Climatology
#' 
#' @description Load OISST climatology from box as a raster stack
#'
#' @param climatology_period Choices: "1991-2020" or "1982-2011" or "1985-2014" for bias correction against CMIP6
#' @param os.use Specification for gmRi::shared.path for Mac/Windows paths
#'
#' @return Rster stack of OISST Daily Climatology cropped to study area

import_oisst_clim <- function(climatology_period = "1985-2014"){
  
  # Path to OISST on Box
  oisst_path <- cs_path("RES_Data", "OISST/oisst_mainstays/daily_climatologies/")
  
  # Path to specific climatology
  climatology_path <- switch(climatology_period,
                             "1991-2020" = paste0(oisst_path, "daily_clims_1991to2020.nc"),
                             "1982-2011" = paste0(oisst_path, "daily_clims_1982to2011.nc"),
                             "1985-2014" = paste0(oisst_path, "daily_clims_1985to2014.nc"))
  
  # Load the Raster Stack
  clim_stack <- stack(climatology_path)
  
  # Crop it to study area and return
  clim_cropped <- crop(clim_stack, study_area)
  return(clim_cropped)
}



####  SODA Processing  ####



#' @title Import SODA Monthly Climatology
#' 
#' @description Load raster stack of SODA climatology for desired variable. Choices
#' are "surf_sal", "surf_temp", "bot_sal", "bot_temp". Area is also cropped to study area.
#'
#' @param soda_var variable name to use when stacking data
#' @param os.use windows mac toggle for box path
#' @param start_yr Starting year for climatology, 1985 or 1990
#'
#' @return Raster stack for monthly climatology, cropped to study area
#' @export
#'
#' @examples
import_soda_clim <- function(soda_var = c("surf_sal", "surf_temp", "bot_sal", "bot_temp"),
                             os.use = "unix",
                             start_yr = "1985"){
  
  # Variable key
  var_key <- c("bot_sal" = "bottom salinity", "bot_temp" = "bottom temperature",
               "surf_sal" = "surface salinity", "surf_temp" = "surface temperature")
  
  # Box path to SODA data
  soda_path <- shared.path(os.use = os.use, group = "RES_Data", folder = "SODA")
  
  # Climatology Path
  clim_path <- switch(start_yr,
                      "1985" = paste0(soda_path, "SODA_monthly_climatology1985to2014.nc"),
                      "1990" = paste0(soda_path, "SODA_monthly_climatology1990to2019.nc") )
  
  # message for what went on while testing
  load_message <- switch(start_yr,
                         "1985" = paste0("Loading 1985-2014 SODA Climatology Data for ", var_key[soda_var]),
                         "1990" = paste0("Loading 1990-2019 SODA Climatology Data for ", var_key[soda_var]) )
  message(load_message)
  
  
  # Open Stack with selected variable
  soda_clim_stack <- raster::stack(x = clim_path, varname = soda_var)
  
  # Crop it to study area - rotate here or no?
  
  # No rotation
  # study_area_180 <- extent(c(-120, -60, 20, 70))
  # clim_cropped <- crop(soda_clim_stack, study_area_180)
  
  # shift it to match 0-360
  soda_clim_shifted <- map(unstack(soda_clim_stack), ~ shift(rotate(shift(.x, 180)), 180) ) %>% stack()
  
  # Crop it to study area - rotate here or no?
  study_area <- extent(c(260, 320, 20, 70))
  clim_cropped <- crop(soda_clim_shifted, study_area)
  
  return(clim_cropped)
  
  
}






#### Prototypes  ####


# Was used for the cmip data, but creates more work than time_period_quantile

#' #' @title Raster Quantiles from Timestep Stacks
#' #' 
#' #' @description Get the Mean/5th/95th percentile at each time step from an ensemble of climate
#' #' projections. Typically used with map() to iterate through years. This function operates on
#' #' the name structure of the months.
#' #'
#' #' @param year_stacks Raster stack containing a full year of each CMIP model's data
#' #'
#' #' @return
#' #' 
#' timestep_stats <- function(year_stacks){
#'   
#'   # Map though the month key to pull their data, return quantile stack
#'   month_key <- str_pad(c(1:12), 2, "left", "0")
#'   month_labels <- paste0("X", month_key)
#'   
#'   
#'   # Get stack containing mean values
#'   monthly_percentiles_05 <- map(month_key, function(month_index){
#'     
#'     # What layers match the month
#'     raster_layers <- str_sub(names(year_stacks), 7, 8) #month letters in X2020.01.01
#'     which_days    <- which(str_detect(raster_layers, month_index) == TRUE)
#'     
#'     # Pull the days out
#'     month_subset_ras <- year_stacks[[which_days]]
#'     
#'     # Use calc to get mean + percentiles
#'     ras.quant <- calc(month_subset_ras, mean,  na.rm = T)
#'     
#'   }) %>% 
#'     setNames(month_labels) %>% 
#'     stack()
#'   
#'   # Get stack containing 5th percentile values
#'   monthly_percentiles_mean <- map(month_key, function(month_index){
#'     
#'     # What layers match the month
#'     raster_layers <- names(year_stacks)
#'     which_days <- which(str_detect(raster_layers, month_index) == TRUE)
#'     
#'     # Pull the days out
#'     month_subset_ras <- year_stacks[[which_days]]
#'     
#'     # Use calc to get mean + percentiles
#'     ras.05   <- calc(month_subset_ras, quantile, probs = 0.05, na.rm = T)
#'     
#'   }) %>% 
#'     setNames(month_labels) %>% 
#'     stack()
#'   
#'   # 95th percentile stack
#'   monthly_percentiles_95 <- map(month_key, function(month_index){
#'     
#'     # What layers match the month
#'     raster_layers <- names(year_stacks)
#'     which_days <- which(str_detect(raster_layers, month_index) == TRUE)
#'     
#'     # Pull the days out
#'     month_subset_ras <- year_stacks[[which_days]]
#'     
#'     # Use calc to get mean + percentiles
#'     ras.95   <- calc(month_subset_ras, quantile, probs = 0.95, na.rm = T)
#'   }) %>% 
#'     setNames(month_labels) %>% 
#'     stack()
#'   
#'   # For each year return a list of each month for the three quantiles
#'   year_quants <- list(
#'     "percentile_05" = monthly_percentiles_05,
#'     "mean"          = monthly_percentiles_mean,
#'     "percentile_95" = monthly_percentiles_95)
#'   
#'   
#'   return(year_quants)
#'   
#'   
#' }


# Was also used for OISST, but is not necessary with time_period_quantile


#' #' @title Reassemble Timeseries from List of Ensemble Quantiles
#' #' 
#' #' @description 
#' #'
#' #' @param year_stack Output Raster stack or list of raster stacks from timestep_stats()
#' #' @param year_lab Matching string indicating the year or timestep to go with each list item
#' #' @param stat_group String indicating which statistic to extract ("mean", "percentile05", 
#' #' "percentile95")
#' #'
#' #' @return
#' #' 
#' timestep_to_full <- function(year_stack, year_lab, stat_group){
#'   stat_out   <- year_stack[[stat_group]] 
#'   orig_names <- str_replace(names(stat_out), "X", "")
#'   new_names  <- paste0(paste0("X", year_lab, "_"), orig_names)
#'   stat_out   <- setNames(stat_out, new_names)
#' }


#' #' @title Load CMIP6 NetCDF data.
#' #' 
#' #' @description Load CMIP6 data off BOX by path to specific file(s) in RES_Data/CMIP6/.
#' #' Default loads the CMIP6 SST subset used for testing. 
#' #'
#' #' @param cmip_file Either "tester", or path to cmip stack within RES_Data/CMIP6
#' #'
#' #' @return Raster stack of CMIP Data, cropped to study area.
#' #'
#' import_cmip_sst <- function(cmip_file = "tester"){
#'   
#'   # General path to all the cmip data on Box
#'   cmip_path    <- shared.path(os.use = "unix", group = "RES_Data", folder = "CMIP6/")
#'   
#'   # Load the stack(s) cropped to the study area
#'   if(cmip_file == "tester"){
#'     message(paste0("Loading CMIP6 File: tos_Omon_CanESM5_historical_r1i1p2f1_gn_195501-201412.nc.1x1.nc"))
#'     cmip_full   <- stack(paste0(cmip_path, "TestFiles/tos_Omon_CanESM5_historical_r1i1p2f1_gn_195501-201412.nc.1x1.nc"))
#'     cmip_cropped <- crop(cmip_full, study_area)
#'   
#'     } else if(length(cmip_file) == 1){
#'         message(paste0("Loading CMIP6 File: ", cmip_file))
#'         cmip_full <- stack(paste0(cmip_path, cmip_file))
#'         cmip_cropped <- crop(cmip_full, study_area)
#'   
#'       } else if(length(cmip_file > 1)){
#'           cmip_cropped <- map(cmip_file, function(x){
#'             message(paste0("Loading Multiple CMIP Files, Returning List"))
#'             cmip_full   <- stack(paste0(cmip_path, x))
#'             cmip_cropped <- crop(cmip_full, study_area)}) %>% 
#'             setNames(cmip_file)
#'   }
#'   
#'   
#'   return(cmip_cropped)
#'   
#' }
#' 
#' 
#' 
#' # Never used
#' #' # Re-stack all the bias-corrected cmip datasets by time step
#' # stores years in a list
#' 
#' 
#' #' @title Re-Stack CMIP Delta Bias Corrected Data
#' #' 
#' #' @description Takes bias corrected data sources and re-stacks them to align on the same 
#' #' time steps. This sets up the stacks for assessing 5th and 95th percentile and mean data.
#' #'
#' #' @param cmip_inputs 
#' #' 
#' #'
#' #' @return
#' #' 
#' restack_cmip_projections <- function(cmip_inputs = cmip_delta_bias_corrected){
#'   
#'   # Get the number of total time steps from a given stack
#'   
#'   
#'   # map around that length and pull out the layers of each
#'   # Put them in stacks by time step, try to keep the names of their sources?
#'   
#'   
#' }