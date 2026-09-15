################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# Script to run the dashboard.


# 1. Global setup & data loading 

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


# 2. Helper functions & analysis engine 
  
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



# 3. UI definition 

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
  
  # Overview tab
  tabPanel(
    "Overview",
    fluidRow(
      column(
        width = 12,
        
        div(
          class = "alert alert-warning d-flex align-items-center mb-4 shadow-sm",
          role = "alert",
          icon("triangle-exclamation", class = "me-2 fs-4"),
          div(
            tags$strong("Under Construction: "),
            "This dashboard is currently under active development. Features, visual design, and underlying datasets are subject to change."
          )
        ),
        
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
  
  # Maps tab
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

server = function(input, output, session) {
  
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
  
  # Render interactive time series Plotly 
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

app = shinyApp(ui = ui, server = server)

# If executed directly by a user in RStudio, launch the UI:
if (interactive() && sys.nframe() == 0) {
  print(app)
}

