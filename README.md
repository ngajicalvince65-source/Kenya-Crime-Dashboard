# Kenya Crime Analytics Dashboard

**Live dashboard:** https://calvince-ngaji.shinyapps.io/kenya-crime-dashboard/

```math
\begin{aligned}
&\textbf{Interactive analysis of reported crime in Kenya, 2012 to 2021} \\[4pt]
&\text{Growth rate}_t = \frac{\text{Total}_t - \text{Total}_{t-1}}{\text{Total}_{t-1}} \times 100 \\[4pt]
&\text{Forecast: } \hat{y}_{T+h} \text{ from an automatically selected ARIMA model}, \quad h = 1, 2, 3 \text{ years, with 95 percent intervals}
\end{aligned}
```

## Overview
An R Shiny dashboard that analyses reported crime in Kenya using the National Police Service annual crime reports. It covers 18 crime categories and 71 offences from 2012 to 2021, and crime counts by county from 2015 to 2021. Users can filter by year and crime category, map crime across counties, compare years, and see a three-year forecast of total crime.

## Features
| Page | What it shows |
|---|---|
| Overview | Total crimes, average per offence, most common offence, recent trend, crime trend over time, share by category, top 10 offences |
| Temporal Analysis | Year-over-year totals, trends by category, annual growth rate, heatmap of crimes by year and category |
| Geographic Analysis | Interactive Leaflet map of crime by county, county rankings (top 5 to 20), county distribution by year |
| Crime Categories | Offence breakdown, trends and treemap for any selected category |
| Comparative Analysis | Side-by-side comparison of chosen years, percentage change by category, summary statistics |
| Predictive Insights | Three-year ARIMA forecast with a 95% interval, linear trend line, key insights |
| Data Explorer | Searchable, filterable tables of the yearly and county data |

## Methods
- **Forecasting:** `forecast::auto.arima` selects an ARIMA model for annual total crime, and `forecast()` projects three years ahead with 80% and 95% intervals (the chart shows the 95% interval).
- **Trend:** a linear regression of total crime on year.
- **Mapping:** counties are plotted at approximate centroids, with circle size and colour scaled to the number of reported crimes.

## Data
| File | Contents |
|---|---|
| `Kenya_yearly_crime_data.xlsx` | Reported cases by crime category and offence, 2012 to 2021 (680 rows) |
| `Kenya_crime_per_county.xlsx` | Reported crimes by county, 2015 to 2021 (343 rows) |

Source: National Police Service (Kenya), annual crime reports.

## Run locally
Open R or RStudio in this folder and run:
```r
install.packages(c("shiny", "shinydashboard", "shinyWidgets", "readxl", "dplyr", "tidyr",
                   "ggplot2", "plotly", "DT", "scales", "leaflet", "forecast"))
shiny::runApp()
```

## Tools
R, Shiny, shinydashboard, Plotly, Leaflet, DT, dplyr, tidyr, forecast, shinyapps.io

## Author
Ngaji Calvince Otieno
