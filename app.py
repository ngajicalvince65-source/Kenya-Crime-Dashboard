"""Kenya Crime Analytics Dashboard (Python and Streamlit).

Run locally:  streamlit run app.py
Data: National Police Service (Kenya) annual crime reports, 2012 to 2021 (by offence)
      and 2015 to 2021 (by county).
"""
import itertools
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from statsmodels.tsa.arima.model import ARIMA

warnings.filterwarnings("ignore")
st.set_page_config(page_title="Kenya Crime Analytics", page_icon=":material/insights:", layout="wide")

DATA = Path(__file__).parent / "data"

# Some counties are spelled differently in different years of the reports
COUNTY_FIXES = {"GARRISSA": "GARISSA", "MURANG'A": "MURANGA", "TRANSNZOIA": "TRANS NZOIA",
                "THARAKA": "THARAKA NITHI", "RAILWAY": "RAILWAYS"}
# Police formations reported alongside counties; they have no single location on the map
POLICE_UNITS = {"RAILWAYS": "Railways Police", "KAPU": "Kenya Airports Police Unit"}

# Approximate county centroids (latitude, longitude)
COUNTY_COORDS = {
    "NAIROBI": (-1.2864, 36.8172), "MOMBASA": (-4.0435, 39.6682), "KIAMBU": (-1.1718, 36.8356),
    "NAKURU": (-0.3031, 36.0800), "KISUMU": (-0.0917, 34.7680), "MERU": (0.3556, 37.6500),
    "KILIFI": (-3.6106, 39.8466), "MACHAKOS": (-1.5177, 37.2634), "BUNGOMA": (0.5635, 34.5608),
    "KISII": (-0.6774, 34.7680), "UASIN GISHU": (0.5200, 35.2800), "KAKAMEGA": (0.2827, 34.7520),
    "NYERI": (-0.4197, 37.0409), "TRANS NZOIA": (1.0508, 35.0000), "KAJIADO": (-1.8527, 36.7820),
    "MURANGA": (-0.7211, 37.0000), "KITUI": (-1.3667, 38.0167), "EMBU": (-0.5317, 37.4500),
    "BUSIA": (0.4402, 34.1110), "KIRINYAGA": (-0.4806, 37.3833), "TAITA TAVETA": (-3.3167, 38.3500),
    "KWALE": (-4.1778, 39.4667), "TANA RIVER": (-1.7500, 40.0000), "GARISSA": (-0.4569, 39.6461),
    "WAJIR": (1.7500, 40.0567), "MANDERA": (3.9366, 41.8667), "MARSABIT": (2.3284, 37.9784),
    "ISIOLO": (0.3523, 37.5817), "TURKANA": (3.1167, 35.5967), "WEST POKOT": (1.6217, 35.3500),
    "SAMBURU": (1.2153, 36.7967), "LAIKIPIA": (0.3556, 36.7833), "BARINGO": (0.4689, 36.0833),
    "NANDI": (0.1816, 35.1333), "KERICHO": (-0.3677, 35.2833), "BOMET": (-0.7973, 35.3000),
    "NYAMIRA": (-0.5667, 34.9333), "VIHIGA": (0.0750, 34.7200), "SIAYA": (-0.0672, 34.2867),
    "HOMA BAY": (-0.5500, 34.4500), "MIGORI": (-0.9000, 34.4733), "THARAKA NITHI": (0.3667, 37.9667),
    "NYANDARUA": (-0.2500, 36.6333), "MAKUENI": (-1.8000, 37.6333), "NAROK": (-1.0833, 35.8667),
    "ELGEYO MARAKWET": (0.5500, 35.4667), "LAMU": (-2.2717, 40.9020),
}


@st.cache_data
def load_data():
    yearly = pd.read_excel(DATA / "Kenya_yearly_crime_data.xlsx")
    yearly["CRIME"] = yearly["CRIME"].str.strip().str.title()
    yearly["OFFENCE"] = yearly["OFFENCE"].str.strip()
    yearly[["Year", "Number"]] = yearly[["Year", "Number"]].astype(int)
    county = pd.read_excel(DATA / "Kenya_crime_per_county.xlsx")
    county["County"] = county["County"].str.upper().str.strip().replace(COUNTY_FIXES)
    county[["Year", "Number"]] = county[["Year", "Number"]].astype(int)
    return yearly, county


def best_arima(series, max_order=2):
    """Choose the ARIMA(p, d, q) with the lowest AIC, in the spirit of R's auto.arima."""
    best = None
    for p, d, q in itertools.product(range(max_order + 1), range(2), range(max_order + 1)):
        try:
            fit = ARIMA(series, order=(p, d, q), trend="t" if d == 1 else "c").fit()
        except Exception:
            continue
        if np.isfinite(fit.aic) and (best is None or fit.aic < best.aic):
            best = fit
    return best


yearly, county = load_data()
years = sorted(yearly["Year"].unique())
categories = sorted(yearly["CRIME"].unique())

# ---------------- sidebar ----------------
with st.sidebar:
    st.title("Kenya Crime Analytics")
    page = st.radio("Page", ["Overview", "Temporal Analysis", "Geographic Analysis", "Crime Categories",
                             "Comparative Analysis", "Predictive Insights", "Data Explorer", "About"])
    st.divider()
    year_choice = st.selectbox("Year", ["All years"] + [str(y) for y in years])
    category_choice = st.selectbox("Crime category", ["All categories"] + categories)
    st.caption("Source: National Police Service (Kenya), annual crime reports.")

f_yearly = yearly.copy()
f_county = county.copy()
if year_choice != "All years":
    f_yearly = f_yearly[f_yearly["Year"] == int(year_choice)]
    f_county = f_county[f_county["Year"] == int(year_choice)]
if category_choice != "All categories":
    f_yearly = f_yearly[f_yearly["CRIME"] == category_choice]

totals = yearly.groupby("Year", as_index=False)["Number"].sum().rename(columns={"Number": "Total"})
by_category = yearly.groupby(["CRIME", "Year"], as_index=False)["Number"].sum().rename(columns={"Number": "Total"})

st.title("Kenya Crime Analytics Dashboard")
st.caption(f"Reported crime in Kenya, {years[0]} to {years[-1]}. "
           f"Showing: {year_choice.lower()}, {category_choice.lower()}.")

# ---------------- pages ----------------
if page == "Overview":
    by_offence = f_yearly.groupby("OFFENCE")["Number"].sum().sort_values(ascending=False)
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total reported crimes", f"{f_yearly['Number'].sum():,}")
    c2.metric("Average per offence", f"{f_yearly['Number'].mean():,.0f}" if len(f_yearly) else "0")
    c3.metric("Most common offence", by_offence.index[0] if len(by_offence) else "None",
              f"{by_offence.iloc[0]:,} cases" if len(by_offence) else None, delta_color="off")
    last, prev = totals["Total"].iloc[-1], totals["Total"].iloc[-2]
    c4.metric(f"All crime, {years[-2]} to {years[-1]}", f"{(last - prev) / prev:+.1%}", delta_color="off")

    left, right = st.columns([2, 1])
    trend = f_yearly.groupby("Year", as_index=False)["Number"].sum()
    left.plotly_chart(px.line(trend, x="Year", y="Number", markers=True, title="Crime trend over time",
                              labels={"Number": "Reported crimes"}), width="stretch")
    share = f_yearly.groupby("CRIME", as_index=False)["Number"].sum()
    right.plotly_chart(px.pie(share, names="CRIME", values="Number", title="Share by category", hole=0.4)
                       .update_layout(showlegend=False).update_traces(textposition="inside"),
                       width="stretch")
    top10 = by_offence.head(10).sort_values().reset_index()
    st.plotly_chart(px.bar(top10, x="Number", y="OFFENCE", orientation="h", title="Top 10 offences",
                           labels={"Number": "Reported cases", "OFFENCE": ""}), width="stretch")

elif page == "Temporal Analysis":
    st.plotly_chart(px.bar(totals, x="Year", y="Total", title="Total reported crime by year"),
                    width="stretch")
    left, right = st.columns(2)
    left.plotly_chart(px.line(by_category, x="Year", y="Total", color="CRIME", markers=True,
                              title="Trends by category"), width="stretch")
    growth = totals.assign(Growth=totals["Total"].pct_change() * 100).dropna()
    right.plotly_chart(px.bar(growth, x="Year", y="Growth", color="Growth", color_continuous_scale="RdYlGn_r",
                              title="Annual growth rate (%)"), width="stretch")
    heat = by_category.pivot(index="CRIME", columns="Year", values="Total").fillna(0)
    st.plotly_chart(px.imshow(heat, aspect="auto", color_continuous_scale="YlOrRd",
                              title="Crimes by year and category", labels={"color": "Crimes"}),
                    width="stretch")

elif page == "Geographic Analysis":
    per_county = f_county.groupby("County", as_index=False)["Number"].sum()
    mapped = per_county[per_county["County"].isin(COUNTY_COORDS)].copy()
    mapped["lat"] = mapped["County"].map(lambda c: COUNTY_COORDS[c][0])
    mapped["lon"] = mapped["County"].map(lambda c: COUNTY_COORDS[c][1])
    left, right = st.columns([3, 2])
    fig = px.scatter_map(mapped, lat="lat", lon="lon", size="Number", color="Number", hover_name="County",
                         color_continuous_scale="YlOrRd", size_max=40, zoom=5, height=600,
                         center={"lat": 0.2, "lon": 37.9}, labels={"Number": "Reported crimes"})
    fig.update_layout(map_style="open-street-map", margin=dict(l=0, r=0, t=30, b=0),
                      title="Reported crime by county")
    left.plotly_chart(fig, width="stretch")
    top_n = right.slider("Top N counties", 5, 20, 10)
    ranked = mapped.nlargest(top_n, "Number").sort_values("Number")
    right.plotly_chart(px.bar(ranked, x="Number", y="County", orientation="h", height=540,
                              title=f"Top {top_n} counties", labels={"Number": "Reported crimes", "County": ""}),
                       width="stretch")
    units = per_county[per_county["County"].isin(POLICE_UNITS)]
    if len(units):
        st.caption("Not mapped (police formations, not counties): " + ", ".join(
            f"{POLICE_UNITS[r.County]} ({r.Number:,})" for r in units.itertuples()))
    top_by_year = (county[county["County"].isin(COUNTY_COORDS)].groupby(["Year", "County"], as_index=False)["Number"]
                   .sum().sort_values("Number", ascending=False).groupby("Year").head(10))
    st.plotly_chart(px.bar(top_by_year, x="County", y="Number", color=top_by_year["Year"].astype(str),
                           barmode="group", title="Ten highest counties in each year",
                           labels={"Number": "Reported crimes", "color": "Year"}), width="stretch")

elif page == "Crime Categories":
    chosen = st.selectbox("Crime category to explore", categories)
    cat = yearly[yearly["CRIME"] == chosen]
    offences = cat.groupby("OFFENCE", as_index=False)["Number"].sum().sort_values("Number", ascending=False)
    left, right = st.columns(2)
    left.plotly_chart(px.pie(offences, names="OFFENCE", values="Number", title="Offences within the category"),
                      width="stretch")
    right.plotly_chart(px.line(cat.groupby(["Year", "OFFENCE"], as_index=False)["Number"].sum(), x="Year",
                               y="Number", color="OFFENCE", markers=True, title="Offences over time"),
                       width="stretch")
    st.plotly_chart(px.treemap(offences, path=["OFFENCE"], values="Number", title=f"Treemap of {chosen}"),
                    width="stretch")

elif page == "Comparative Analysis":
    chosen_years = st.multiselect("Years to compare", years, default=years[-2:])
    if len(chosen_years) < 2:
        st.info("Select at least two years.")
    else:
        comp = (yearly[yearly["Year"].isin(chosen_years)].groupby(["Year", "CRIME"], as_index=False)["Number"].sum())
        st.plotly_chart(px.bar(comp, x="CRIME", y="Number", color=comp["Year"].astype(str), barmode="group",
                               title="Categories side by side", labels={"color": "Year", "CRIME": ""}),
                        width="stretch")
        left, right = st.columns(2)
        a, b = min(chosen_years), max(chosen_years)
        wide = comp.pivot(index="CRIME", columns="Year", values="Number").fillna(0)
        change = ((wide[b] - wide[a]) / wide[a].replace(0, np.nan) * 100).dropna().sort_values().reset_index()
        change.columns = ["CRIME", "Change"]
        left.plotly_chart(px.bar(change, x="Change", y="CRIME", orientation="h", color="Change",
                                 color_continuous_scale="RdYlGn_r", title=f"Percentage change, {a} to {b}",
                                 labels={"CRIME": "", "Change": "%"}), width="stretch")
        stats = (yearly[yearly["Year"].isin(chosen_years)].groupby("Year")["Number"]
                 .agg(Total="sum", Average="mean", Median="median", Largest="max", Smallest="min").round(1))
        right.subheader("Summary by year")
        right.dataframe(stats, width="stretch")

elif page == "Predictive Insights":
    series = pd.Series(totals["Total"].to_numpy(dtype=float), index=totals["Year"])
    fit = best_arima(series.to_numpy())
    fc = fit.get_forecast(3)
    future = [years[-1] + h for h in (1, 2, 3)]
    ci = np.asarray(fc.conf_int(alpha=0.05))
    fig = go.Figure()
    fig.add_scatter(x=series.index, y=series.values, mode="lines+markers", name="Reported")
    fig.add_scatter(x=future + future[::-1], y=list(ci[:, 1]) + list(ci[::-1, 0]), fill="toself",
                    fillcolor="rgba(214,39,40,0.15)", line=dict(width=0), name="95% interval")
    fig.add_scatter(x=future, y=np.asarray(fc.predicted_mean), mode="lines+markers", name="Forecast",
                    line=dict(dash="dash", color="#d62728"))
    fig.update_layout(title=f"Three-year forecast, ARIMA{fit.model.order} chosen by AIC",
                      xaxis_title="Year", yaxis_title="Total reported crimes")
    st.plotly_chart(fig, width="stretch")
    left, right = st.columns(2)
    slope, intercept = np.polyfit(series.index, series.values, 1)
    trend_fig = go.Figure()
    trend_fig.add_scatter(x=series.index, y=series.values, mode="lines+markers", name="Reported")
    trend_fig.add_scatter(x=series.index, y=intercept + slope * series.index, name="Linear trend",
                          line=dict(dash="dash"))
    trend_fig.update_layout(title="Linear trend", xaxis_title="Year", yaxis_title="Total reported crimes")
    left.plotly_chart(trend_fig, width="stretch")
    top_cat = yearly.groupby("CRIME")["Number"].sum().idxmax()
    right.subheader("Key insights")
    right.markdown(
        f"- **{years[-1]} total:** {series.iloc[-1]:,.0f} reported crimes\n"
        f"- **Largest category over the period:** {top_cat}\n"
        f"- **Linear trend:** {slope:+,.0f} crimes per year\n"
        f"- **Forecast for {future[0]}:** {np.asarray(fc.predicted_mean)[0]:,.0f} "
        f"(95% interval {ci[0, 0]:,.0f} to {ci[0, 1]:,.0f})\n\n"
        "With only ten annual points, the forecast interval is wide and should be read as indicative.")

elif page == "Data Explorer":
    st.subheader("Reported crime by offence")
    st.dataframe(f_yearly, width="stretch", hide_index=True)
    st.download_button("Download (CSV)", f_yearly.to_csv(index=False).encode(), "kenya_crime_by_offence.csv")
    st.subheader("Reported crime by county")
    st.dataframe(f_county, width="stretch", hide_index=True)
    st.download_button("Download (CSV)", f_county.to_csv(index=False).encode(), "kenya_crime_by_county.csv")

else:
    st.subheader("About this dashboard")
    st.markdown(
        "This dashboard analyses reported crime in Kenya using the National Police Service annual crime "
        f"reports: {yearly['CRIME'].nunique()} crime categories and {yearly['OFFENCE'].nunique()} offences "
        f"from {years[0]} to {years[-1]}, and reported crime by county from {county['Year'].min()} to "
        f"{county['Year'].max()}.\n\n"
        "**Data preparation:** county names spelled differently across years were harmonised (for example "
        "Garrissa and Garissa), and the Railways Police and the Kenya Airports Police Unit are reported "
        "separately because they are police formations rather than counties.\n\n"
        "**Developer:** Ngaji Calvince Otieno\n\n"
        "**Built with:** Python, Streamlit, pandas, Plotly and statsmodels.")
