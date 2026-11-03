# ==========================================
# STEP 1: INSTALL PACKAGES (Run this once)
# ==========================================
# Uncomment and run these lines if packages are not installed:
# install.packages("shiny")
# install.packages("shinydashboard")
# install.packages("readxl")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("ggplot2")
# install.packages("plotly")
# install.packages("DT")
# install.packages("scales")

# ==========================================
# STEP 2: LOAD LIBRARIES
# ==========================================

library(shiny)           # For creating web applications
library(shinydashboard)  # For dashboard layout
library(readxl)          # For reading Excel files
library(dplyr)           # For data manipulation
library(tidyr)           # For data tidying
library(ggplot2)         # For creating plots
library(plotly)          # For interactive plots
library(DT)              # For interactive tables
library(scales)          # For formatting numbers
library(leaflet)         # For interactive maps
library(forecast)        # For predictive analytics
library(shinyWidgets)


# ==========================================
# DATA LOADING AND PREPROCESSING
# ==========================================

# Load the datasets (the Excel files sit in the same folder as app.R)
yearly_data <- read_excel("Kenya_yearly_crime_data.xlsx")
county_data <- read_excel("Kenya_crime_per_county.xlsx")



# Data preprocessing for yearly data
yearly_data <- yearly_data %>%
  mutate(
    Year = as.integer(Year),
    Number = as.numeric(Number),
    CRIME = as.factor(CRIME),
    OFFENCE = as.factor(OFFENCE)
  )

# Data preprocessing for county data
county_data <- county_data %>%
  mutate(
    Year = as.integer(Year),
    Number = as.numeric(Number),
    County = toupper(trimws(County))
  )


# Calculate aggregated metrics
total_crimes_by_year <- yearly_data %>%
  group_by(Year) %>%
  summarise(Total = sum(Number, na.rm = TRUE))

crimes_by_category <- yearly_data %>%
  group_by(CRIME, Year) %>%
  summarise(Total = sum(Number, na.rm = TRUE), .groups = 'drop')


# County coordinates for mapping (Kenya counties - approximate centroids)
county_coords <- data.frame(
  County = c("NAIROBI", "MOMBASA", "KIAMBU", "NAKURU", "KISUMU", 
             "MERU", "KILIFI", "MACHAKOS", "BUNGOMA", "KISII",
             "UASIN GISHU", "KAKAMEGA", "NYERI", "TRANS NZOIA", "KAJIADO",
             "MURANG'A", "KITUI", "EMBU", "BUSIA", "KIRINYAGA",
             "TAITA TAVETA", "KWALE", "TANA RIVER", "GARISSA", "WAJIR",
             "MANDERA", "MARSABIT", "ISIOLO", "TURKANA", "WEST POKOT",
             "SAMBURU", "LAIKIPIA", "BARINGO", "NANDI", "KERICHO",
             "BOMET", "NYAMIRA", "VIHIGA", "SIAYA", "HOMA BAY",
             "MIGORI", "THARAKA", "NYANDARUA", "MAKUENI", "NAROK",
             "ELGEYO MARAKWET", "LAMU"),
  lat = c(-1.286389, -4.043477, -1.1718, -0.3031, -0.0917,
          0.3556, -3.6106, -1.5177, 0.5635, -0.6774,
          0.5200, 0.2827, -0.4197, 1.0508, -1.8527,
          -0.7211, -1.3667, -0.5317, 0.4402, -0.4806,
          -3.3167, -4.1778, -1.7500, -0.4569, 1.7500,
          3.9366, 2.3284, 0.3523, 3.1167, 1.6217,
          1.2153, 0.3556, 0.4689, 0.1816, -0.3677,
          -0.7973, -0.5667, 0.0750, -0.0672, -0.5500,
          -0.9000, 0.3667, -0.2500, -1.8000, -1.0833,
          0.5500, -2.2717),
  lon = c(36.817223, 39.668206, 36.8356, 36.0800, 34.7680,
          37.6500, 39.8466, 37.2634, 34.5608, 34.7680,
          35.2800, 34.7520, 37.0409, 35.0000, 36.7820,
          37.0000, 38.0167, 37.4500, 34.1110, 37.3833,
          38.3500, 39.4667, 40.0000, 39.6461, 40.0567,
          41.8667, 37.9784, 37.5817, 35.5967, 35.3500,
          36.7967, 36.7833, 36.0833, 35.1333, 35.2833,
          35.3000, 34.9333, 34.7200, 34.2867, 34.4500,
          34.4733, 37.9667, 36.6333, 37.6333, 35.8667,
          35.4667, 40.9020)
)

# ==========================================
# UI DEFINITION
# ==========================================

ui <- dashboardPage(
  skin = "blue",
  
  # Dashboard Header
  dashboardHeader(
    title = "Kenya Crime Analytics Dashboard",
    titleWidth = 350
  ),
  
  # Dashboard Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "tabs",
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Temporal Analysis", tabName = "temporal", icon = icon("chart-line")),
      menuItem("Geographic Analysis", tabName = "geographic", icon = icon("map")),
      menuItem("Crime Categories", tabName = "categories", icon = icon("layer-group")),
      menuItem("Comparative Analysis", tabName = "comparative", icon = icon("balance-scale")),
      menuItem("Predictive Insights", tabName = "predictive", icon = icon("brain")),
      menuItem("Data Explorer", tabName = "explorer", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    
    hr(),
    
    # Filters
    selectInput("yearFilter", "Select Year:",
                choices = c("All Years", sort(unique(yearly_data$Year))),
                selected = "All Years"),
    
    selectInput("crimeFilter", "Crime Category:",
                choices = c("All Categories", unique(yearly_data$CRIME)),
                selected = "All Categories")
  ),
  
  # Dashboard Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top: 3px solid #3c8dbc; }
        .small-box { border-radius: 5px; }
        .info-box { border-radius: 5px; }
      "))
    ),
    
    tabItems(
      # ========== OVERVIEW TAB ==========
      tabItem(
        tabName = "overview",
        fluidRow(
          valueBoxOutput("totalCrimesBox", width = 3),
          valueBoxOutput("avgCrimesBox", width = 3),
          valueBoxOutput("mostCommonBox", width = 3),
          valueBoxOutput("trendBox", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Crime Trends Over Time",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("overviewTrendPlot", height = 350)
          ),
          box(
            title = "Crime Distribution by Category",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("overviewPiePlot", height = 350)
          )
        ),
        
        fluidRow(
          box(
            title = "Top 10 Most Common Offences",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("top10OffencesPlot", height = 350)
          )
        )
      ),
      
      # ========== TEMPORAL ANALYSIS TAB ==========
      tabItem(
        tabName = "temporal",
        fluidRow(
          box(
            title = "Year-over-Year Crime Comparison",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("yoyComparison", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Crime Category Trends",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("categoryTrends", height = 400)
          ),
          box(
            title = "Growth Rate Analysis",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("growthRatePlot", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Heatmap: Crimes by Year and Category",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("temporalHeatmap", height = 500)
          )
        )
      ),
      
      # ========== GEOGRAPHIC ANALYSIS TAB ==========
      tabItem(
        tabName = "geographic",
        fluidRow(
          box(
            title = "Interactive Crime Map of Kenya",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            leafletOutput("crimeMap", height = 600)
          ),
          box(
            title = "County Rankings",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            sliderInput("topNCounties", "Top N Counties:",
                        min = 5, max = 20, value = 10, step = 1),
            plotlyOutput("countyRankings", height = 540)
          )
        ),
        
        fluidRow(
          box(
            title = "County-wise Crime Distribution",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("countyDistribution", height = 400)
          )
        )
      ),
      
      # ========== CRIME CATEGORIES TAB ==========
      tabItem(
        tabName = "categories",
        fluidRow(
          box(
            title = "Crime Category Breakdown",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            selectInput("selectedCategory", "Select Crime Category:",
                        choices = unique(yearly_data$CRIME),
                        selected = unique(yearly_data$CRIME)[1])
          )
        ),
        
        fluidRow(
          box(
            title = "Offence Distribution within Category",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("offenceDistribution", height = 400)
          ),
          box(
            title = "Temporal Pattern",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("categoryTemporal", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Treemap Visualization",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("treemapPlot", height = 500)
          )
        )
      ),
      
      # ========== COMPARATIVE ANALYSIS TAB ==========
      tabItem(
        tabName = "comparative",
        fluidRow(
          box(
            title = "Multi-Year Comparison",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            pickerInput("compareYears", "Select Years to Compare:",
                        choices = sort(unique(yearly_data$Year)),
                        selected = sort(unique(yearly_data$Year))[1:2],
                        multiple = TRUE,
                        options = list(`actions-box` = TRUE))
          )
        ),
        
        fluidRow(
          box(
            title = "Side-by-Side Comparison",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("sideBySideComparison", height = 500)
          )
        ),
        
        fluidRow(
          box(
            title = "Percentage Change Analysis",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("percentageChange", height = 400)
          ),
          box(
            title = "Statistical Summary",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            DTOutput("comparativeStats")
          )
        )
      ),
      
      # ========== PREDICTIVE INSIGHTS TAB ==========
      tabItem(
        tabName = "predictive",
        fluidRow(
          box(
            title = "Crime Forecast (Next 3 Years)",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("forecastPlot", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Trend Analysis",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("trendDecomposition", height = 400)
          ),
          box(
            title = "Key Insights",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            htmlOutput("keyInsights")
          )
        )
      ),
      
      # ========== DATA EXPLORER TAB ==========
      tabItem(
        tabName = "explorer",
        fluidRow(
          box(
            title = "Yearly Crime Data",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("yearlyDataTable")
          )
        ),
        
        fluidRow(
          box(
            title = "County Crime Data",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("countyDataTable")
          )
        )
      ),
      
      # ========== ABOUT TAB ==========
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About This Dashboard",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            htmlOutput("aboutContent")
          )
        )
      )
    )
  )
)

# ==========================================
# SERVER LOGIC
# ==========================================

server <- function(input, output, session) {
  
  # ========== REACTIVE DATA ==========
  
  filtered_yearly_data <- reactive({
    data <- yearly_data
    
    if (input$yearFilter != "All Years") {
      data <- data %>% filter(Year == as.integer(input$yearFilter))
    }
    
    if (input$crimeFilter != "All Categories") {
      data <- data %>% filter(CRIME == input$crimeFilter)
    }
    
    return(data)
  })
  
  filtered_county_data <- reactive({
    data <- county_data
    
    if (input$yearFilter != "All Years") {
      data <- data %>% filter(Year == as.integer(input$yearFilter))
    }
    
    return(data)
  })
  
  # ========== OVERVIEW TAB OUTPUTS ==========
  
  output$totalCrimesBox <- renderValueBox({
    total <- sum(filtered_yearly_data()$Number, na.rm = TRUE)
    valueBox(
      value = format(total, big.mark = ","),
      subtitle = "Total Crimes",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$avgCrimesBox <- renderValueBox({
    avg <- mean(filtered_yearly_data()$Number, na.rm = TRUE)
    valueBox(
      value = format(round(avg, 0), big.mark = ","),
      subtitle = "Average per Offence",
      icon = icon("chart-bar"),
      color = "yellow"
    )
  })
  
  output$mostCommonBox <- renderValueBox({
    most_common <- filtered_yearly_data() %>%
      group_by(OFFENCE) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total)) %>%
      slice(1)
    
    valueBox(
      value = most_common$OFFENCE,
      subtitle = paste("Most Common:", format(most_common$Total, big.mark = ",")),
      icon = icon("crown"),
      color = "purple"
    )
  })
  
  output$trendBox <- renderValueBox({
    if (input$yearFilter == "All Years") {
      recent_years <- total_crimes_by_year %>%
        arrange(desc(Year)) %>%
        slice(1:2)
      
      if (nrow(recent_years) == 2) {
        change <- ((recent_years$Total[1] - recent_years$Total[2]) / recent_years$Total[2]) * 100
        trend_icon <- if(change > 0) "arrow-up" else "arrow-down"
        trend_color <- if(change > 0) "red" else "green"
        
        valueBox(
          value = paste0(round(abs(change), 1), "%"),
          subtitle = if(change > 0) "Increase" else "Decrease",
          icon = icon(trend_icon),
          color = trend_color
        )
      } else {
        valueBox(
          value = "N/A",
          subtitle = "Trend Analysis",
          icon = icon("question"),
          color = "blue"
        )
      }
    } else {
      valueBox(
        value = "Single Year",
        subtitle = "Select 'All Years' for trend",
        icon = icon("info"),
        color = "blue"
      )
    }
  })
  
  output$overviewTrendPlot <- renderPlotly({
    data <- filtered_yearly_data() %>%
      group_by(Year) %>%
      summarise(Total = sum(Number, na.rm = TRUE))
    
    plot_ly(data, x = ~Year, y = ~Total, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#3c8dbc', width = 3),
            marker = list(size = 10, color = '#3c8dbc')) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Total Crimes"),
        hovermode = "x unified"
      )
  })
  
  output$overviewPiePlot <- renderPlotly({
    data <- filtered_yearly_data() %>%
      group_by(CRIME) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total))
    
    plot_ly(data, labels = ~CRIME, values = ~Total, type = 'pie',
            textposition = 'inside',
            textinfo = 'label+percent',
            insidetextfont = list(color = '#FFFFFF'),
            marker = list(colors = RColorBrewer::brewer.pal(min(nrow(data), 9), "Set3"),
                          line = list(color = '#FFFFFF', width = 1))) %>%
      layout(showlegend = TRUE)
  })
  
  output$top10OffencesPlot <- renderPlotly({
    data <- filtered_yearly_data() %>%
      group_by(OFFENCE) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total)) %>%
      slice(1:10)
    
    plot_ly(data, x = ~reorder(OFFENCE, Total), y = ~Total, type = 'bar',
            marker = list(color = ~Total, colorscale = 'Reds',
                          line = list(color = 'rgb(8,48,107)', width = 1.5))) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Number of Cases"),
        margin = list(l = 150)
      ) %>%
      layout(xaxis = list(tickangle = -45))
  })
  
  # ========== TEMPORAL ANALYSIS TAB OUTPUTS ==========
  
  output$yoyComparison <- renderPlotly({
    data <- yearly_data %>%
      group_by(Year) %>%
      summarise(Total = sum(Number, na.rm = TRUE))
    
    plot_ly(data, x = ~Year, y = ~Total, type = 'bar',
            marker = list(color = ~Total, colorscale = 'Blues',
                          line = list(color = 'rgb(8,48,107)', width = 1))) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Total Crimes"),
        bargap = 0.2
      )
  })
  
  output$categoryTrends <- renderPlotly({
    data <- crimes_by_category
    
    plot_ly(data, x = ~Year, y = ~Total, color = ~CRIME, type = 'scatter', mode = 'lines+markers') %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Total Crimes"),
        hovermode = "x unified",
        legend = list(orientation = "v", x = 1.02, y = 1)
      )
  })
  
  output$growthRatePlot <- renderPlotly({
    data <- yearly_data %>%
      group_by(Year) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(Year) %>%
      mutate(GrowthRate = (Total - lag(Total)) / lag(Total) * 100)
    
    plot_ly(data, x = ~Year, y = ~GrowthRate, type = 'bar',
            marker = list(color = ~GrowthRate,
                          colorscale = list(c(0, 'red'), c(0.5, 'yellow'), c(1, 'green')),
                          line = list(color = 'rgb(8,48,107)', width = 1))) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Growth Rate (%)")
      )
  })
  
  output$temporalHeatmap <- renderPlotly({
    data <- crimes_by_category %>%
      pivot_wider(names_from = Year, values_from = Total, values_fill = 0)
    
    matrix_data <- as.matrix(data[, -1])
    rownames(matrix_data) <- data$CRIME
    
    plot_ly(z = matrix_data, x = colnames(matrix_data), y = rownames(matrix_data),
            type = "heatmap", colorscale = "YlOrRd") %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Crime Category")
      )
  })
  
  # ========== GEOGRAPHIC ANALYSIS TAB OUTPUTS ==========
  
  output$crimeMap <- renderLeaflet({
    county_summary <- filtered_county_data() %>%
      group_by(County) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      left_join(county_coords, by = "County") %>%
      filter(!is.na(lat) & !is.na(lon))
    
    pal <- colorNumeric(palette = "YlOrRd", domain = county_summary$Total)
    
    leaflet(county_summary) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon, lat = ~lat,
        radius = ~sqrt(Total) / 10,
        color = ~pal(Total),
        fillOpacity = 0.7,
        popup = ~paste0("<strong>", County, "</strong><br>",
                        "Total Crimes: ", format(Total, big.mark = ","))
      ) %>%
      addLegend("bottomright", pal = pal, values = ~Total,
                title = "Crime Count",
                opacity = 1)
  })
  
  output$countyRankings <- renderPlotly({
    data <- filtered_county_data() %>%
      group_by(County) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total)) %>%
      slice(1:input$topNCounties)
    
    plot_ly(data, x = ~Total, y = ~reorder(County, Total), type = 'bar',
            orientation = 'h',
            marker = list(color = '#3c8dbc')) %>%
      layout(
        xaxis = list(title = "Total Crimes"),
        yaxis = list(title = ""),
        margin = list(l = 120)
      )
  })
  
  output$countyDistribution <- renderPlotly({
    data <- county_data %>%
      group_by(County, Year) %>%
      summarise(Total = sum(Number, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(Total)) %>%
      group_by(Year) %>%
      slice(1:10)
    
    plot_ly(data, x = ~County, y = ~Total, color = ~as.factor(Year),
            type = 'bar') %>%
      layout(
        xaxis = list(title = "", tickangle = -45),
        yaxis = list(title = "Total Crimes"),
        barmode = 'group'
      )
  })
  
  # ========== CRIME CATEGORIES TAB OUTPUTS ==========
  
  output$offenceDistribution <- renderPlotly({
    data <- yearly_data %>%
      filter(CRIME == input$selectedCategory) %>%
      group_by(OFFENCE) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total))
    
    plot_ly(data, labels = ~OFFENCE, values = ~Total, type = 'pie',
            textposition = 'inside',
            textinfo = 'label+percent') %>%
      layout(showlegend = TRUE)
  })
  
  output$categoryTemporal <- renderPlotly({
    data <- yearly_data %>%
      filter(CRIME == input$selectedCategory) %>%
      group_by(Year, OFFENCE) %>%
      summarise(Total = sum(Number, na.rm = TRUE), .groups = 'drop')
    
    plot_ly(data, x = ~Year, y = ~Total, color = ~OFFENCE,
            type = 'scatter', mode = 'lines+markers') %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Cases"),
        hovermode = "x unified"
      )
  })
  
  output$treemapPlot <- renderPlotly({
    data <- yearly_data %>%
      filter(CRIME == input$selectedCategory) %>%
      group_by(OFFENCE) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total))
    
    plot_ly(data,
            labels = ~OFFENCE,
            parents = "",
            values = ~Total,
            type = 'treemap',
            textposition = "middle center",
            marker = list(colorscale = 'RdYlBu')) %>%
      layout(title = paste("Treemap of", input$selectedCategory))
  })
  
  # ========== COMPARATIVE ANALYSIS TAB OUTPUTS ==========
  
  output$sideBySideComparison <- renderPlotly({
    if (length(input$compareYears) < 2) {
      return(plot_ly() %>% layout(title = "Please select at least 2 years"))
    }
    
    data <- yearly_data %>%
      filter(Year %in% input$compareYears) %>%
      group_by(Year, CRIME) %>%
      summarise(Total = sum(Number, na.rm = TRUE), .groups = 'drop')
    
    plot_ly(data, x = ~CRIME, y = ~Total, color = ~as.factor(Year),
            type = 'bar') %>%
      layout(
        xaxis = list(title = "Crime Category", tickangle = -45),
        yaxis = list(title = "Total Crimes"),
        barmode = 'group',
        legend = list(title = list(text = "Year"))
      )
  })
  
  output$percentageChange <- renderPlotly({
    if (length(input$compareYears) != 2) {
      return(plot_ly() %>% layout(title = "Please select exactly 2 years"))
    }
    
    years_sorted <- sort(input$compareYears)
    
    data <- yearly_data %>%
      filter(Year %in% years_sorted) %>%
      group_by(Year, CRIME) %>%
      summarise(Total = sum(Number, na.rm = TRUE), .groups = 'drop') %>%
      pivot_wider(names_from = Year, values_from = Total, values_fill = 0) %>%
      mutate(PercentChange = ((!!sym(as.character(years_sorted[2])) - 
                                 !!sym(as.character(years_sorted[1]))) / 
                                !!sym(as.character(years_sorted[1]))) * 100)
    
    plot_ly(data, x = ~PercentChange, y = ~reorder(CRIME, PercentChange),
            type = 'bar', orientation = 'h',
            marker = list(color = ~PercentChange,
                          colorscale = list(c(0, 'green'), c(0.5, 'yellow'), c(1, 'red')),
                          line = list(color = 'rgb(8,48,107)', width = 1))) %>%
      layout(
        xaxis = list(title = "Percentage Change (%)"),
        yaxis = list(title = ""),
        margin = list(l = 150)
      )
  })
  
  output$comparativeStats <- renderDT({
    if (length(input$compareYears) == 0) {
      return(data.frame(Message = "Please select years to compare"))
    }
    
    stats <- yearly_data %>%
      filter(Year %in% input$compareYears) %>%
      group_by(Year) %>%
      summarise(
        `Total Crimes` = sum(Number, na.rm = TRUE),
        `Average per Offence` = round(mean(Number, na.rm = TRUE), 2),
        `Median` = median(Number, na.rm = TRUE),`Max Single Offence` = max(Number, na.rm = TRUE),
        `Min Single Offence` = min(Number, na.rm = TRUE)
      )
    
    datatable(stats, options = list(pageLength = 10, dom = 't'))
  })
  
  # ========== PREDICTIVE INSIGHTS TAB OUTPUTS ==========
  
  output$forecastPlot <- renderPlotly({
    ts_data <- total_crimes_by_year %>%
      arrange(Year) %>%
      pull(Total) %>%
      ts(start = min(total_crimes_by_year$Year), frequency = 1)
    
    fit <- auto.arima(ts_data)
    forecasted <- forecast(fit, h = 3)
    
    years <- c(total_crimes_by_year$Year, 
               max(total_crimes_by_year$Year) + 1:3)
    
    plot_ly() %>%
      add_lines(x = total_crimes_by_year$Year, 
                y = total_crimes_by_year$Total,
                name = "Historical",
                line = list(color = '#3c8dbc')) %>%
      add_lines(x = max(total_crimes_by_year$Year) + 1:3,
                y = as.numeric(forecasted$mean),
                name = "Forecast",
                line = list(color = 'red', dash = 'dash')) %>%
      add_ribbons(x = max(total_crimes_by_year$Year) + 1:3,
                  ymin = as.numeric(forecasted$lower[,2]),
                  ymax = as.numeric(forecasted$upper[,2]),
                  name = "95% CI",
                  fillcolor = 'rgba(255,0,0,0.2)',
                  line = list(color = 'transparent')) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Total Crimes"),
        hovermode = "x unified"
      )
  })
  
  output$trendDecomposition <- renderPlotly({
    data <- total_crimes_by_year %>%
      arrange(Year)
    
    if (nrow(data) >= 3) {
      model <- lm(Total ~ Year, data = data)
      data$Trend <- predict(model, data)
      
      plot_ly(data, x = ~Year) %>%
        add_lines(y = ~Total, name = "Actual", line = list(color = '#3c8dbc')) %>%
        add_lines(y = ~Trend, name = "Trend Line", line = list(color = 'red', dash = 'dash')) %>%
        layout(
          xaxis = list(title = "Year"),
          yaxis = list(title = "Total Crimes"),
          hovermode = "x unified"
        )
    } else {
      plot_ly() %>% layout(title = "Insufficient data for trend analysis")
    }
  })
  
  output$keyInsights <- renderUI({
    total_recent <- total_crimes_by_year %>%
      arrange(desc(Year)) %>%
      slice(1) %>%
      pull(Total)
    
    most_common_category <- yearly_data %>%
      group_by(CRIME) %>%
      summarise(Total = sum(Number, na.rm = TRUE)) %>%
      arrange(desc(Total)) %>%
      slice(1)
    
    HTML(paste0(
      "<div style='padding: 20px;'>",
      "<h4><i class='fa fa-lightbulb'></i> Key Insights</h4>",
      "<ul style='font-size: 14px; line-height: 2;'>",
      "<li><strong>Most Recent Year Total:</strong> ", format(total_recent, big.mark = ","), " crimes</li>",
      "<li><strong>Dominant Category:</strong> ", most_common_category$CRIME, 
      " (", format(most_common_category$Total, big.mark = ","), " cases)</li>",
      "<li><strong>Data Coverage:</strong> ", 
      min(yearly_data$Year), " to ", max(yearly_data$Year), "</li>",
      "<li><strong>Analysis:</strong> The forecast suggests ",
      ifelse(tail(total_crimes_by_year$Total, 1) > head(total_crimes_by_year$Total, 1),
             "an upward trend", "a downward trend"),
      " in crime rates.</li>",
      "</ul>",
      "</div>"
    ))
  })
  
  # ========== DATA EXPLORER TAB OUTPUTS ==========
  
  output$yearlyDataTable <- renderDT({
    datatable(
      filtered_yearly_data(),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        searchHighlight = TRUE
      ),
      filter = 'top'
    )
  })
  
  output$countyDataTable <- renderDT({
    datatable(
      filtered_county_data(),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        searchHighlight = TRUE
      ),
      filter = 'top'
    )
  })
  
  # ========== ABOUT TAB OUTPUT ==========
  
  output$aboutContent <- renderUI({
    HTML(paste0(
      "<div style='padding: 20px;'>",
      "<h3>Kenya Crime Analytics Dashboard</h3>",
      "<p style='font-size: 16px; line-height: 1.8;'>",
      "This interactive dashboard provides comprehensive analysis of crime data in Kenya, ",
      "utilizing official crime reports and county-level statistics from National Police Service (NPS) annual crime reports.</p>",
      
      "<h4>Developer Information:</h4>",
      "<div style='background-color: #f0f8ff; padding: 15px; border-left: 4px solid #3c8dbc; margin: 20px 0;'>",
      "<p style='font-size: 15px; margin: 5px 0;'><strong>Name:</strong> Ngaji Calvince Otieno</p>",
      "<p style='font-size: 14px; margin: 5px 0;'><strong>Current Programs:</strong></p>",
      "<ul style='font-size: 14px; line-height: 1.8;'>",
      "<li>MSc in Data Science, University of Nairobi (2025-2027)<br>",
      "<em>Scholarship: Food Systems Resilience Project (FSRP)</em></li>",
      "<li>PhD in Biostatistics, Moi University<br>",
      "<em>Scholarship: DAAD-German Academic Exchange Service</em></li>",
      "</ul>",
      "<p style='font-size: 14px; margin: 5px 0;'><strong>Completed:</strong> MSc in Social Statistics, University of Nairobi (2023)</p>",
      "</div>",
      
      "<h4>Dashboard Features:</h4>",
      "<ul style='font-size: 14px; line-height: 2;'>",
      "<li><strong>Overview:</strong> High-level metrics and trends</li>",
      "<li><strong>Temporal Analysis:</strong> Year-over-year comparisons and growth patterns</li>",
      "<li><strong>Geographic Analysis:</strong> Interactive maps and county rankings</li>",
      "<li><strong>Crime Categories:</strong> Deep dive into specific crime types</li>",
      "<li><strong>Comparative Analysis:</strong> Multi-year comparisons</li>",
      "<li><strong>Predictive Insights:</strong> Forecasting and trend analysis</li>",
      "<li><strong>Data Explorer:</strong> Raw data access with filtering</li>",
      "</ul>",
      
      "<h4>Data Sources:</h4>",
      "<p style='font-size: 14px;'>",
      "Kenya Annual Crime Reports<br>",
      "County-level Crime Statistics<br>",
      "Years covered: ", min(yearly_data$Year), " - ", max(yearly_data$Year),
      "</p>",
      
      "<h4>Technology Stack:</h4>",
      "<p style='font-size: 14px;'>",
      "R Shiny, Plotly, Leaflet, DT, ggplot2, and various statistical packages",
      "</p>",
      
      "<p style='margin-top: 30px; font-size: 12px; color: #666; text-align: center;'>",
      "<em>Developed for MSc Data Science Visualization Project | University of Nairobi | 2025</em>",
      "</p>",
      "</div>"
    ))
  })
}



# ==========================================
# RUN THE APPLICATION
# ==========================================

shinyApp(ui = ui, server = server)
