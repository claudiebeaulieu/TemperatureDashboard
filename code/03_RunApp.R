################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# 1. Global Setup & Data Loading 

DATA_PATH = here::here("data", "processed", "tas_annual_gridded_berkeley.rds")

if (!file.exists(DATA_PATH)) {
  stop("Processed data file not found at: ", DATA_PATH, "\nPlease run scripts 01 and 02 first.")
}

data    = readRDS(DATA_PATH)
lon       = data$lon
lat       = data$lat
years      = data$years
tas_annual = data$data  # 3D Array: [lon, lat, time]


MAP_DEFAULT_LNG  = 0
MAP_DEFAULT_LAT  = 20
MAP_DEFAULT_ZOOM = 2


# 2. Helper Functions & Analysis Engine 
  
get_ns_indicator = function(lat) ifelse(lat >= 0, "N", "S")
get_ew_indicator = function(lon) ifelse(lon >= 0, "E", "W")

# On-demand changepoint analysis
analyze_grid_cell = function(time, temp) {
#  time -> Vector of years
#  temp -> Vector of temperature anomalies for the selected location
  
  if (all(is.na(temp)) || sum(!is.na(temp)) < 10) {
    return(NULL)
  }
  
  na_idx = !is.na(temp)
  temp = as.numeric(temp[na_idx])
  time = as.numeric(time[na_idx])
  n = length(temp)
  
  # changepoint detection
  cpts = PELT.trendARpJOIN(temp, p = 1, pen = 4*log(n), minseglen = 10)
  fitted = fit.trendARpJOIN(temp, cpts, p = 1, dates = time)
  fitted_series = as.numeric(fitted$fit)
  
  # segments boundaries
  all_cpts = sort(unique(c(1, cpts[cpts > 1 & cpts < n], n)))
  seg_starts = all_cpts[-length(all_cpts)]
  seg_ends   = all_cpts[-1]
  
  # segment slopes (°C per decade)
  delta_fit  = fitted_series[seg_ends] - fitted_series[seg_starts]
  delta_time = time[seg_ends] - time[seg_starts]
  slopes_per_dec = (delta_fit / delta_time) * 10
  
  # changepoint years
  changepoints   = time[cpts]
  
  return(list(temp = temp,
    time = time,
    fitted_trend    = fitted_series,
    changepoints    = changepoints,
    slopes = slopes_per_dec
  ))
}



# 3. UI Definition 

ui = navbarPage(
  title = div(
    class = "fw-bold me-4",
    style = "font-size: 1.25rem;",
    "Temperature Trends Explorer"
  ),
  collapsible = TRUE,
  theme = bs_theme(
    version = 5,
    preset = "bootstrap",
    primary = "#2b5c8f",
    base_font = font_google("Roboto"),
    heading_font = font_google("Inter")
  ),
  
  # Overview Tab
  tabPanel(
    "Overview",
    fluidRow(
      column(
        width = 12,
        div(
          class = "p-4 mb-4 bg-light rounded-3 border shadow-sm",
          div(class = "fw-bold fs-5 mb-2 text-dark", "Surface Temperature Trend Dashboard"),
          p(
            class = "mb-0 text-secondary",
            "This dashboard enables the user to interactively analyze surface temperature anomalies. Select any coordinate on the Map tab to execute real-time changepoint analysis and quantify localized warming rates (°C/decade)."
          )
        )
      )
    ),
    fluidRow(
      column(
        width = 4,
        card(
          card_header(icon("globe"), " Interactive Map Interface"),
          card_body("Select any location to analyze its temperature time series interactively.")
        )
      ),
      column(
        width = 4,
        card(
          card_header(icon("calculator"), " Real-Time Modeling"),
          card_body("Runs changepoint detection algorithm dynamically on user selected location.")
        )
      ),
      column(
        width = 4,
        card(
          card_header(icon("chart-line"), " Segment Analysis"),
          card_body("Outputs segmented trends (°C/decade) and changepoint timings.")
        )
      )
    )
  ), # Close overview tab
  
  # Maps Tab
  tabPanel(
    "Interactive Map",
    fluidRow(
      class = "g-3 align-items-stretch", # Forces both columns to stretch equally
      column(
        width = 6,
        class = "map-col",
        card(
          class = "h-100 map-card", # Added h-100 and map-card class
          full_screen = TRUE,
          card_header(
            class = "d-flex align-items-center justify-content-between py-2 px-3",
            style = "height: 65px; min-height: 65px; max-height: 65px;", # Enforces hard pixel boundary
            div(
              div(class = "fw-bold", "Interactive Map"),
              div(class = "text-muted small", style = "font-size: 0.75rem;", "Click anywhere to select a location.")
            )
          ),
          card_body(
            class = "p-0",
            leafletOutput("map", height = "550px")
          )
        )
      ),
      column(
        width = 6,
        class = "time-col",
        card(
          class = "h-100 time-card",
          full_screen = TRUE,
          card_header(
            class = "d-flex align-items-center justify-content-between py-2 px-3",
            style = "height: 65px; min-height: 65px; max-height: 65px;", # Enforces hard pixel boundary matching left
            div(class = "fw-bold", "Selected Location"),
            div(
              class = "d-flex align-items-center gap-2 mb-0",
              tags$label(`for` = "start_year", class = "form-label mb-0 small text-nowrap", "Start Year:"),
              div(
                style = "width: 130px;",
                sliderInput(
                  inputId = "start_year",
                  label   = NULL,
                  min     = min(years),
                  max     = max(years) - 15,
                  value   = min(years),
                  step    = 1,
                  sep     = ""
                )
              )
            )
          ),
          card_body(
            plotlyOutput("timeSeries", height = "400px"),
            hr(class = "my-2"),
            htmlOutput("model_summary_text")
          )
        )
      )
    )
  ) # Close interactive map tab
) # Close navbarPage


  # 4. Server logic 

server <- function(input, output, session) {
  
  # Render initial base map 
  output$map = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addSearchOSM(options = searchOptions(zoom = 5)) %>%
      setView(lng = MAP_DEFAULT_LNG, lat = MAP_DEFAULT_LAT, zoom = MAP_DEFAULT_ZOOM)
  })
  
  # Reactive data & computation layer 
  selected_analysis = reactive({
    click = input$map_click
    req(click)
    req(input$start_year)
    
    # Extract time series
    lon_idx = which.min(abs(lon - click$lng))
    lat_idx = which.min(abs(lat - click$lat))
    
    selected_lon = lon[lon_idx]
    selected_lat = lat[lat_idx]
    
    raw_temp   = tas_annual[lon_idx, lat_idx, ]
    full_years = years
    
    # Crop time series by user-selected start year
    year_mask   = full_years >= input$start_year
    subset_years = full_years[year_mask]
    subset_temp  = raw_temp[year_mask]
    
    # Run dynamic analysis on subset time series
    analysis = analyze_grid_cell(subset_years, subset_temp)
    
    list(
      lon      = selected_lon,
      lat      = selected_lat,
      analysis = analysis
    )
  })
  # Highlight selected location 
  observeEvent(input$map_click, {
    cell = selected_analysis()
    req(cell)
    
    res_lon = if (length(lon) > 1) abs(lon[2] - lon[1]) / 2 else 0.5
    res_lat = if (length(lat) > 1) abs(lat[2] - lat[1]) / 2 else 0.5
    
    leafletProxy("map") %>%
      clearShapes() %>%
      addRectangles(
        lng1 = cell$lon - res_lon, lat1 = cell$lat - res_lat,
        lng2 = cell$lon + res_lon, lat2 = cell$lat + res_lat,
        color = "red", weight = 2, fillOpacity = 0.3
      )
  })
  
  # Summary HTML output 
  output$model_summary_text <- renderUI({
    cell = selected_analysis()
    req(cell)
    
    analysis = cell$analysis
    if (is.null(analysis)) {
      return(HTML('<div class="summary-text" style="padding:10px;">No climate data available for this ocean/unmeasured location.</div>'))
    }
    
    ns_indicator = get_ns_indicator(cell$lat)
    ew_indicator = get_ew_indicator(cell$lon)
    
    cpts   = analysis$changepoints
    slopes = analysis$slopes
    
    # Filter out min/max endpoints to identify internal changepoints
    internal_cpts = cpts[!cpts %in% c(min(analysis$time), max(analysis$time))]
    cpt_str       = if (length(internal_cpts) > 0) paste(internal_cpts, collapse = ", ") else "None"
    
    # Format segment slopes string
    seg_strings = sprintf("<li><strong>Segment %d:</strong> %+.3f °C/decade</li>", seq_along(slopes), slopes)
    
    summary_html = sprintf(
      "Location: <strong>%.1f° %s, %.1f° %s</strong><br>Detected Changepoints: <strong>%s</strong><br>Segment Slopes:<ul style='margin-top:4px; margin-bottom:0px;'>%s</ul>",
      abs(as.numeric(cell$lat)), ns_indicator,
      abs(as.numeric(cell$lon)), ew_indicator,
      cpt_str,
      paste(seg_strings, collapse = "")
    )
    
    HTML(paste0('<div class="summary-text" style="padding:10px; background-color:#f8f9fa; border-radius:5px;">', 
                summary_html, 
                '</div>'))
  })
  
  # Render Interactive Time Series Plotly ------------------------------------
  output$timeSeries = renderPlotly({
    cell = selected_analysis()
    req(cell)
    
    analysis = cell$analysis
    if (is.null(analysis)) return(NULL)
    
    plot_df = data.frame(
      time        = as.numeric(analysis$time),
      temperature = as.numeric(analysis$temp),
      fittrend    = as.numeric(analysis$fitted_trend)
    )
    
    ns_indicator = get_ns_indicator(cell$lat)
    ew_indicator = get_ew_indicator(cell$lon)
    
    internal_cpts = analysis$changepoints[!analysis$changepoints %in% c(min(analysis$time), max(analysis$time))]
    
    colors = c("Observations" = "black", "Trend" = "red")
    
    min_yr = min(plot_df$time)
    max_yr = max(plot_df$time)
    
    p = ggplot(plot_df, aes(x = time, y = temperature)) +
      geom_line(aes(color = "Observations"), linewidth = 0.25) +
      geom_line(aes(y = fittrend, color = "Trend")) +
      scale_color_manual(values = colors, name = NULL) +
      scale_x_continuous(
        breaks = seq(
          floor(min_yr / 10) * 10,
          ceiling(max_yr / 10) * 10,
          by = 10
        )
      ) +
      theme_bw() +
      theme(
        legend.key.size   = unit(1.5, 'cm'),
        legend.position   = c(0.13, 0.84),
        legend.text       = element_text(size = 12),
        legend.background = element_blank(),
        legend.key        = element_blank(),
        axis.text         = element_text(size = 13),
        axis.text.x       = element_text(angle = 45, hjust = 1, vjust = 1),
        axis.title        = element_text(size = 13),
        plot.margin       = margin(10, 10, 10, 10)
      ) +
      labs(
        x = "Year",
        y = "Temperature Anomaly (°C)"
      )
    
    if (length(internal_cpts) > 0) {
      p = p + geom_vline(
        xintercept = internal_cpts + 1, 
        linetype   = "dashed", 
        color      = "grey50", 
        linewidth  = 0.6
      )
    }
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      layout(
        hovermode = "x unified",
        title = list(text = ""),
        xaxis = list(
          title     = list(text = "Year", font = list(size = 13)),
          tickfont  = list(size = 11),
          tickangle = -45,
          dtick     = 10
        ),
        yaxis = list(
          title    = list(text = "Temperature Anomaly (°C)", font = list(size = 13)),
          tickfont = list(size = 11)
        ),
        legend = list(
          x           = 0.02,
          y           = 0.98,
          bgcolor     = 'rgba(0, 0, 0, 0)',
          bordercolor = 'transparent'
        ),
        margin = list(t = 20, r = 20, b = 60, l = 60)
      ) %>%
      config(displayModeBar = TRUE, scrollZoom = TRUE)
  })
}

# 5. App launch 

shinyApp(ui = ui, server = server)


#' 
#' # Data Loading and Preparation 
#' #load('./data/annual_Berkeley_anom.RData') 
#' #load('./results/ResultsBerkeley.RData')
#' 
#' # Extract relevant time period (1970-2024: indices 121-175)
#' time_data <- time[121:175]
#' temperature_data <- tas_annual[, , 121:175]
#' 
#' # Reshape temperature data from 3D array to matrix
#' # Dimensions: (lon × lat) rows × time columns
#' temperature_matrix <- matrix(
#'   temperature_data,
#'   nrow = dim(temperature_data)[1] * dim(temperature_data)[2],
#'   ncol = dim(temperature_data)[3]
#' )
#' 
#' # Create combined data frame with spatial and temporal dimensions
#' combined_data <- cbind(
#'   expand.grid(
#'     lon = 1:dim(temperature_data)[1],
#'     lat = 1:dim(temperature_data)[2]
#'   ),
#'   time = rep(time_data, each = dim(temperature_data)[1] * dim(temperature_data)[2]),
#'   temperature = as.vector(temperature_matrix)
#' )
#' 
#' # Add fitted trend from changepoint analysis
#' combined_data$fittrend <- as.vector(results$fittrend)
#' 
#' # Remove incomplete cases (NaN values)
#' combined_data <- combined_data[complete.cases(combined_data), ]
#' 
#' # Transform coordinate systems
#' # Longitude: 1-360 → -180 to 180
#' combined_data$lon <- combined_data$lon - 180
#' combined_data$lon[combined_data$lon > 180] <- combined_data$lon[combined_data$lon > 180] - 360
#' 
#' # Latitude: 1-180 → -90 to 90
#' combined_data$lat <- combined_data$lat - 90
#' 
#' # Global Constants 
#' MAP_DEFAULT_LNG <- -122
#' MAP_DEFAULT_LAT <- 37.0902
#' MAP_DEFAULT_ZOOM <- 5
#' GRID_RESOLUTION <- 1  # 1° × 1° grid
#' 
#' # Helper Functions #############################################################
#' #' 
#' #' #' Detect changes in a vector (placeholder - implement your change detection)
#' #' #'
#' #' #' @param x Numeric vector
#' #' #' @return Logical vector indicating change points
#' #' #' @note Replace this with your actual changepoint detection algorithm
#' #' changed <- function(x) {
#' #'   # Simple implementation: detect when difference changes sign or magnitude
#' #'   # Replace with your actual implementation
#' #'   if (length(x) < 2) return(rep(FALSE, length(x)))
#' #'   
#' #'   changes <- c(TRUE, abs(diff(x)) > mean(abs(diff(x)), na.rm = TRUE))
#' #'   changes
#' #' }
#' 
#' #' Create a single grid cell polygon for map visualization
#' #'
#' #' @param lon1 Lower longitude boundary
#' #' @param lat1 Lower latitude boundary
#' #' @param lon2 Upper longitude boundary
#' #' @param lat2 Upper latitude boundary
#' #' @return SpatialPolygons object representing the grid cell
#' create_grid_cell <- function(lon1, lat1, lon2, lat2) {
#'   coords <- matrix(
#'     c(lon1, lat1, 
#'       lon2, lat1, 
#'       lon2, lat2, 
#'       lon1, lat2, 
#'       lon1, lat1), 
#'     ncol = 2, 
#'     byrow = TRUE
#'   )
#'   sp::SpatialPolygons(list(sp::Polygons(list(sp::Polygon(coords)), ID = "1")))
#' }
#' 
#' #' Get hemisphere indicator (N/S) from latitude
#' #'
#' #' @param lat Latitude value
#' #' @return Character "N" or "S"
#' get_ns_indicator <- function(lat) {
#'   ifelse(lat >= 0, "N", "S")
#' }
#' 
#' #' Get hemisphere indicator (E/W) from longitude
#' #'
#' #' @param lon Longitude value
#' #' @return Character "E" or "W"
#' get_ew_indicator <- function(lon) {
#'   ifelse(lon >= 0, "E", "W")
#' }
#' 
#' #' Calculate slope per decade from consecutive years
#' #'
#' #' @param trend_start Trend value at start year
#' #' @param trend_end Trend value at end year
#' #' @param years Number of years between measurements (default 1)
#' #' @return Slope in °C per decade
#' calculate_slope_per_decade <- function(trend_start, trend_end, years = 1) {
#'   (trend_end - trend_start) * 10 / years
#' }
#' 
#' #' Detect changepoint times in trend differences
#' #'
#' #' @param trend_vector Vector of fitted trend values
#' #' @param time_vector Corresponding time vector
#' #' @param digits Number of digits for rounding (default 5)
#' #' @return Vector of changepoint times
#' detect_changepoints <- function(trend_vector, time_vector, digits = 5) {
#'   differences <- diff(trend_vector)
#'   time_vector[changed(round(differences, digits = digits))]
#' }
#' 
#' #' Generate trend summary text
#' #'
#' #' @param slope_beg Slope at beginning period
#' #' @param slope_end Slope at end period
#' #' @param cptime Vector of changepoint times
#' #' @return Character string with trend summary
#' generate_trend_summary <- function(slope_beg, slope_end, cptime) {
#'   if (round(slope_beg, digits = 3) == round(slope_end, digits = 3)) {
#'     paste0(
#'       "The magnitude of the trend is ", 
#'       format(slope_end, scientific = FALSE, digits = 3), 
#'       "°C per decade."
#'     )
#'   } else {
#'     paste0(
#'       "The trend before ", format(cptime[2]), " is ",
#'       format(slope_beg, scientific = FALSE, digits = 3), "°C per decade\n",
#'       "and ", format(slope_end, scientific = FALSE, digits = 3), 
#'       "°C per decade after."
#'     )
#'   }
#' }
#' 
#' #' Plot temperature time series with trend for aggregated data
#' #'
#' #' @param data Data frame with columns: time, avg_temperature
#' #' @param title Plot title
#' #' @return Plotly object
#' plot_aggregated_trend <- function(data, title) {
#'   # Fit linear model
#'   lm_model <- lm(avg_temperature ~ time, data = data)
#'   data$trend <- predict(lm_model)
#'   
#'   # Calculate trend statistics
#'   trend_per_decade <- coef(lm_model)[2] * 10
#'   p_value <- summary(lm_model)$coefficients[2, 4]
#'   significance <- ifelse(
#'     p_value < 0.05, 
#'     "The trend is significant.", 
#'     "The trend is not significant."
#'   )
#'   
#'   # Create ggplot
#'   p <- ggplot(data, aes(x = time, y = avg_temperature)) +
#'     geom_line(color = "black", size = 0.4) +
#'     geom_line(aes(y = trend), color = "red", size = 1) +
#'     theme_minimal() +
#'     labs(
#'       title = title,
#'       x = "Year",
#'       y = "Average Temperature Anomaly (°C)"
#'     ) +
#'     theme(
#'       plot.title = element_text(size = 16, face = "bold", family = "Merriweather"),
#'       axis.title = element_text(size = 13),
#'       axis.text = element_text(size = 11),
#'       plot.margin = margin(10, 10, 10, 10)
#'     )
#'   
#'   # Convert to plotly with custom layout
#'   ggplotly(p, tooltip = c("x", "y")) %>%
#'     layout(
#'       hovermode = "x unified",
#'       title = list(
#'         text = paste0(
#'           title, "<br><sup>Trend: ", 
#'           round(trend_per_decade, 3), 
#'           "°C/decade — ", significance, "</sup>"
#'         ),
#'         font = list(size = 16, family = "Merriweather")
#'       ),
#'       xaxis = list(title = "Year", tickfont = list(size = 11)),
#'       yaxis = list(
#'         title = "Average Temperature (°C)", 
#'         tickfont = list(size = 11)
#'       ),
#'       margin = list(t = 60, r = 20, b = 50, l = 60)
#'     ) %>%
#'     config(displayModeBar = TRUE, scrollZoom = TRUE)
#' }
#' 
#' # UI Definition ################################################################
#' ui <- navbarPage(
#'   title = "Temperature Dashboard",
#'   theme = bs_theme(
#'     version = 5,
#'     bootswatch = NULL,
#'     bg = "#f8f9fa",
#'     fg = "#1e1e1e",
#'     primary = "#89CFF0",
#'     base_font = font_google("Roboto"),
#'     heading_font = font_google("Inter")
#'   ),
#'   header = tags$head(
#'     tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
#'   ),
#'   
#'   # Overview Tab 
#'   tabPanel(
#'     "Overview",
#'     
#'     # Hero Section
#'     fluidRow(
#'       column(
#'         width = 12, 
#'         class = "intro",
#'         h1(class = "o-title", "Explore Changes in Surface Temperature Trends"),
#'         p(
#'           class = "o-para", 
#'           "Welcome to this monitoring dashboard for trends in surface temperature.",
#'           "You can click on a location on the map to interact with local temperature",
#'           "trends and assess whether any changepoints took place since 1970.",
#'           "Temperature data comes from Berkeley Earth."
#'         )
#'       )
#'     ),
#'     
#'     # Information Cards
#'     fluidRow(
#'       class = "info-cards-row",
#'       
#'       # About Card
#'       card(
#'         class = "about",
#'         card_header(icon("globe"), "About This Dashboard"),
#'         card_body(
#'           p("This interactive dashboard enables exploration of changes in surface",
#'             "temperature trends using high-resolution gridded data from Berkeley Earth."),
#'           hr(),
#'           h5("Key Features:"),
#'           tags$ul(
#'             tags$li("Interactive map-based exploration"),
#'             tags$li("Changepoint detection analysis"),
#'             tags$li("Location-specific time series")
#'           )
#'         )
#'       ),
#'       
#'       # Methodology Card
#'       card(
#'         class = "methods",
#'         card_header(icon("chart-line"), "Methodology"),
#'         card_body(
#'           tags$dl(
#'             tags$dt("Data Source:"),
#'             tags$dd("Berkeley Earth Surface Temperature"),
#'             tags$dt("Time Period:"),
#'             tags$dd("1970-2024 (55 years)"),
#'             tags$dt("Spatial Resolution:"),
#'             tags$dd("1° × 1° grid"),
#'             tags$dt("Analysis Method:"),
#'             tags$dd("Changepoint detection is used to identify whether any changes",
#'                     "in temperature trends took place at each location"),
#'             tags$dt("Reference:"),
#'             tags$dd("Claudie Beaulieu, Adelicia Johnson, Rebecca Killick, John Lanzante",
#'                     "and Thomas Knutson. Space-time signatures of surface warming",
#'                     "accelerations since 1970, 28 October 2025, PREPRINT (Version 1)",
#'                     "available at Research Square",
#'                     "[https://doi.org/10.21203/rs.3.rs-7731926/v1]")
#'           )
#'         )
#'       ),
#'       
#'       # User Guide Card
#'       card(
#'         class = "usage",
#'         card_header(icon("question-circle"), "User Guide"),
#'         card_body(
#'           tags$ul(
#'             tags$li("Navigate to the ", tags$strong("Maps"), " tab"),
#'             tags$li("Click any location on the map or use the search bar"),
#'             tags$li("View local temperature time series with fitted trends"),
#'             tags$li("Explore changepoint times and warming rates"),
#'             tags$li("Download data for selected locations")
#'           )
#'         )
#'       )
#'     )
#'   ),
#'   
#'   # Maps Tab 
#'   tabPanel(
#'     "Maps",
#'     fluidRow(
#'       
#'       # Map Column
#'       column(
#'         width = 6, 
#'         class = "map-col",
#'         card(
#'           class = "map-card",
#'           full_screen = TRUE,
#'           card_header("Interactive Map"),
#'           div(
#'             class = "map-outer-body",
#'             card_body(
#'               div(
#'                 class = "map-body",
#'                 tabsetPanel(
#'                   tabPanel("Map", leafletOutput("map", height = "500px"))
#'                 )
#'               )
#'             )
#'           )
#'         )
#'       ),
#'       
#'       # Time Series Column
#'       column(
#'         width = 6, 
#'         class = "time-col",
#'         card(
#'           class = "time-card",
#'           full_screen = TRUE,
#'           card_header(class = "time-header", "Surface Temperature Time Series"),
#'           div(
#'             class = "time-body",
#'             card_body(
#'               tabsetPanel(
#'                 tabPanel(
#'                   "Selected Location",
#'                   div(
#'                     class = "selected-graph",
#'                     plotlyOutput("timeSeries", height = "450px"),
#'                     hr(),
#'                     htmlOutput("model_summary_text")
#'                   )
#'                 )
#'               )
#'             )
#'           )
#'         )
#'       )
#'     )
#'   )
#' )
#' 
#' # Server Logic #################################################################
#' server <- function(input, output, session) {
#'   
#'   # Render Initial Map ---------------------------------------------------------
#'   output$map <- renderLeaflet({
#'     leaflet() %>%
#'       addTiles() %>%
#'       addSearchOSM(options = searchOptions(zoom = 5)) %>%
#'       setView(lng = MAP_DEFAULT_LNG, lat = MAP_DEFAULT_LAT, zoom = MAP_DEFAULT_ZOOM)
#'   })
#'   
#'   # Handle Map Click Events ----------------------------------------------------
#'   observeEvent(input$map_click, {
#'     click <- input$map_click
#'     
#'     # Calculate grid cell boundaries
#'     lon_floor <- floor(click$lng)
#'     lat_floor <- floor(click$lat)
#'     grid_cell <- create_grid_cell(
#'       lon_floor, lat_floor, 
#'       lon_floor + 1, lat_floor + 1
#'     )
#'     
#'     # Highlight selected cell on map
#'     leafletProxy("map") %>%
#'       clearShapes() %>%
#'       addPolygons(data = grid_cell, color = "red", fillOpacity = 0.3)
#'     
#'     # Filter data for selected location
#'     selected_data <- combined_data %>%
#'       filter(lat == lat_floor, lon == lon_floor)
#'     
#'     # Process selected location data
#'     if (nrow(selected_data) > 0) {
#'       
#'       # Get hemisphere indicators
#'       ns_indicator <- get_ns_indicator(selected_data$lat[1])
#'       ew_indicator <- get_ew_indicator(selected_data$lon[1])
#'       
#'       # Calculate slopes per decade
#'       slope_beginning <- calculate_slope_per_decade(
#'         selected_data$fittrend[1], 
#'         selected_data$fittrend[2]
#'       )
#'       slope_end <- calculate_slope_per_decade(
#'         selected_data$fittrend[54], 
#'         selected_data$fittrend[55]
#'       )
#'       
#'       # Detect changepoints
#'       changepoint_times <- detect_changepoints(
#'         selected_data$fittrend, 
#'         selected_data$time
#'       )
#'       
#'       # Generate and display summary text
#'       output$model_summary_text <- renderText({
#'         HTML(paste0('<div class="summary-text">', 
#'                     generate_trend_summary(slope_beginning, slope_end, changepoint_times),
#'                     '</div>'))
#'       })
#'       
#'       # Render time series plot
#'       output$timeSeries <- renderPlotly({
#'         colors <- c("Observations" = "black", "Trend" = "red")
#'         
#'         # Create ggplot
#'         p <- ggplot(selected_data, aes(x = time, y = temperature)) +
#'           geom_line(aes(color = "Observations"), size = 0.25) +
#'           geom_line(aes(y = fittrend, color = "Trend")) +
#'           scale_color_manual(values = colors, name = NULL) +
#'           scale_x_continuous(
#'             breaks = seq(
#'               floor(min(selected_data$time) / 10) * 10,
#'               ceiling(max(selected_data$time) / 10) * 10,
#'               by = 10
#'             )
#'           ) +
#'           theme_bw() +
#'           theme(
#'             legend.key.size = unit(1.5, 'cm'),
#'             legend.position = c(0.13, 0.84),
#'             legend.text = element_text(size = 12),
#'             legend.background = element_rect(
#'               colour = "transparent", 
#'               fill = 'lightgrey'
#'             ),
#'             axis.text = element_text(size = 13),
#'             axis.text.x = element_text(angle = 0, hjust = 0.5),
#'             axis.title = element_text(size = 13),
#'             plot.title = element_text(size = 16, face = 'bold'),
#'             plot.margin = margin(10, 10, 10, 10)
#'           ) +
#'           labs(
#'             title = sprintf(
#'               "Temperature Data at %d° %s, %d° %s",
#'               abs(selected_data$lat[1]), ns_indicator,
#'               abs(selected_data$lon[1]), ew_indicator
#'             ),
#'             x = "Year",
#'             y = "Temperature Anomaly (°C)"
#'           )
#'         
#'         # Convert to plotly with enhanced layout
#'         ggplotly(p, tooltip = c("x", "y")) %>%
#'           layout(
#'             hovermode = "x unified",
#'             title = list(
#'               text = sprintf(
#'                 "Temperature Data at %d° %s, %d° %s",
#'                 abs(selected_data$lat[1]), ns_indicator,
#'                 abs(selected_data$lon[1]), ew_indicator
#'               ),
#'               font = list(size = 16, family = "Merriweather"),
#'               yanchor = "top",
#'               y = 0.98
#'             ),
#'             xaxis = list(
#'               title = list(text = "Year", font = list(size = 13)),
#'               tickfont = list(size = 11),
#'               dtick = 10
#'             ),
#'             yaxis = list(
#'               title = list(
#'                 text = "Temperature Anomaly (°C)", 
#'                 font = list(size = 13)
#'               ),
#'               tickfont = list(size = 11)
#'             ),
#'             legend = list(
#'               x = 0.02,
#'               y = 0.98,
#'               bgcolor = 'rgba(211, 211, 211, 0.5)',
#'               bordercolor = 'transparent'
#'             ),
#'             margin = list(t = 60, r = 20, b = 50, l = 60)
#'           ) %>%
#'           config(displayModeBar = TRUE, scrollZoom = TRUE)
#'       })
#'       
#'     } else {
#'       # Handle no data case
#'       output$timeSeries <- renderPlot({ NULL })
#'       output$model_summary_text <- renderText({
#'         "No data available for this location."
#'       })
#'     }
#'   })
#'   
#'   # Hemisphere and Global Averages (Optional) ----------------------------------
#'   # Uncomment these sections if you want to add hemisphere/global views
#'   
#'   # north_data <- combined_data %>%
#'   #   filter(lat >= 0) %>%
#'   #   group_by(time) %>%
#'   #   summarize(avg_temperature = mean(temperature, na.rm = TRUE), .groups = "drop")
#'   # 
#'   # output$northAverage <- renderPlotly({
#'   #   plot_aggregated_trend(
#'   #     north_data, 
#'   #     "Northern Hemisphere Average Temperature Anomaly"
#'   #   )
#'   # })
#'   # 
#'   # south_data <- combined_data %>%
#'   #   filter(lat <= 0) %>%
#'   #   group_by(time) %>%
#'   #   summarize(avg_temperature = mean(temperature, na.rm = TRUE), .groups = "drop")
#'   # 
#'   # output$southAverage <- renderPlotly({
#'   #   plot_aggregated_trend(
#'   #     south_data, 
#'   #     "Southern Hemisphere Average Temperature Anomaly"
#'   #   )
#'   # })
#'   # 
#'   # global_data <- combined_data %>%
#'   #   group_by(time) %>%
#'   #   summarize(avg_temperature = mean(temperature, na.rm = TRUE), .groups = "drop")
#'   # 
#'   # output$globalAverage <- renderPlotly({
#'   #   plot_aggregated_trend(global_data, "Global Average Temperature Anomaly")
#'   # })
#' }
#' 
#' # Run Application ##############################################################
#' shinyApp(ui = ui, server = server)
