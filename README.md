# Kenya Crime Analytics Dashboard

[![Open in Streamlit](https://static.streamlit.io/badges/streamlit_badge_black_white.svg)](https://kenya-crime-ngaji.streamlit.app)

**Live dashboard:** https://kenya-crime-ngaji.streamlit.app

```math
\begin{aligned}
&\textbf{Interactive analysis of reported crime in Kenya, 2012 to 2021} \\[4pt]
&\text{Growth rate}_t = \frac{\text{Total}_t - \text{Total}_{t-1}}{\text{Total}_{t-1}} \times 100 \\[4pt]
&\text{Forecast: } \hat{y}_{T+h} \text{ from the ARIMA}(p,d,q) \text{ model with the lowest AIC}, \quad h = 1, 2, 3 \text{ years, with 95 percent intervals}
\end{aligned}
```

## Overview
A Python and Streamlit dashboard that analyses reported crime in Kenya using the National Police Service annual crime reports. It covers 18 crime categories and 71 offences from 2012 to 2021, and reported crime by county from 2015 to 2021. Users can filter by year and crime category, map crime across counties, compare years, and see a three-year forecast of total crime.

## Pages
| Page | What it shows |
|---|---|
| Overview | Total crimes, average per offence, most common offence, latest annual change, trend over time, share by category, top 10 offences |
| Temporal Analysis | Totals by year, trends by category, annual growth rate, heatmap of crimes by year and category |
| Geographic Analysis | Interactive map of crime by county, top counties ranking (5 to 20), ten highest counties in each year |
| Crime Categories | Offence breakdown, trends over time and a treemap for any category |
| Comparative Analysis | Side-by-side comparison of chosen years, percentage change by category, summary statistics |
| Predictive Insights | Three-year ARIMA forecast with a 95 percent interval, linear trend and key insights |
| Data Explorer | Filtered tables of both datasets, downloadable as CSV |

## Methods
- **Data preparation:** county names spelled differently across years are harmonised (for example Garrissa and Garissa, Murang'a and Muranga). The Railways Police and the Kenya Airports Police Unit appear in the county table but are police formations, so they are reported separately and not mapped.
- **Forecasting:** ARIMA(p, d, q) models with p and q from 0 to 2 and d of 0 or 1 are fitted with statsmodels, and the model with the lowest AIC produces a three-year forecast with a 95 percent interval. With ten annual observations the forecast is indicative.
- **Trend:** a least-squares linear trend of total crime on year.
- **Mapping:** counties are plotted at approximate centroids, with marker size and colour scaled to reported crime.

## Data
| File | Contents |
|---|---|
| `data/Kenya_yearly_crime_data.xlsx` | Reported cases by crime category and offence, 2012 to 2021 (680 rows) |
| `data/Kenya_crime_per_county.xlsx` | Reported crime by county and police formation, 2015 to 2021 (343 rows) |

Source: National Police Service (Kenya), annual crime reports.

## Run locally
```bash
pip install -r requirements.txt
streamlit run app.py
```

## Tools
Python, Streamlit, pandas, Plotly, statsmodels, Streamlit Community Cloud

## Author
Ngaji Calvince Otieno
