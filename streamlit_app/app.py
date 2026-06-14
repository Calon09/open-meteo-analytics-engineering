"""City Comfort Index dashboard for the Open-Meteo analytics engineering project.

Reads exclusively from the final dbt mart models in the local DuckDB database
(dim_location, fct_city_weather_day, fct_air_quality_city_day,
mart_city_weather_summary). It does not query the raw CSV files.
"""

from __future__ import annotations

from pathlib import Path

import altair as alt
import duckdb
import pandas as pd
import streamlit as st

DB_PATH = Path(__file__).resolve().parent.parent / "open_meteo.duckdb"

st.set_page_config(
    page_title="Open-Meteo City Comfort Index",
    page_icon="🌤️",
    layout="wide",
)


@st.cache_resource
def get_connection() -> duckdb.DuckDBPyConnection:
    return duckdb.connect(str(DB_PATH), read_only=True)


@st.cache_data
def load_table(table: str) -> pd.DataFrame:
    con = get_connection()
    return con.execute(f"select * from {table}").df()


if not DB_PATH.exists():
    st.error(
        f"Could not find the dbt-built DuckDB database at `{DB_PATH}`.\n\n"
        "Run the extraction script and `dbt run` first. "
        "See the README for setup instructions."
    )
    st.stop()

locations = load_table("dim_location")
summary = load_table("mart_city_weather_summary")
daily = load_table("fct_city_weather_day")
air_quality = load_table("fct_air_quality_city_day")

# Bring city names onto the fact tables, since they only carry location_id.
city_lookup = locations[["location_id", "city", "country"]]
daily = daily.merge(city_lookup, on="location_id", how="left")
air_quality = air_quality.merge(city_lookup, on="location_id", how="left")
daily["weather_date"] = pd.to_datetime(daily["weather_date"])
air_quality["air_quality_date"] = pd.to_datetime(air_quality["air_quality_date"])

# ---------------------------------------------------------------------------
# Sidebar filters
# ---------------------------------------------------------------------------
st.sidebar.header("Filters")

all_cities = sorted(locations["city"].unique())
selected_cities = st.sidebar.multiselect(
    "City", options=all_cities, default=all_cities
)

min_date = min(daily["weather_date"].min(), air_quality["air_quality_date"].min()).date()
max_date = max(daily["weather_date"].max(), air_quality["air_quality_date"].max()).date()
date_range = st.sidebar.slider(
    "Date range (weather + air quality)",
    min_value=min_date,
    max_value=max_date,
    value=(min_date, max_date),
)

if not selected_cities:
    st.warning("Select at least one city in the sidebar to see results.")
    st.stop()

summary_f = summary[summary["city"].isin(selected_cities)].copy()
daily_f = daily[
    daily["city"].isin(selected_cities)
    & (daily["weather_date"].dt.date >= date_range[0])
    & (daily["weather_date"].dt.date <= date_range[1])
].copy()
aq_f = air_quality[
    air_quality["city"].isin(selected_cities)
    & (air_quality["air_quality_date"].dt.date >= date_range[0])
    & (air_quality["air_quality_date"].dt.date <= date_range[1])
].copy()

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.title("Open-Meteo City Comfort Index")
st.caption(
    "Which Spanish cities had the most comfortable weather recently? "
    "Built on top of dbt mart models running on DuckDB."
)

with st.expander("About this dashboard: grain, sources, and metric definitions", expanded=False):
    st.markdown(
        """
**Main model and grain**

- `fct_city_weather_day` — **one row per city (`location_id`) and `weather_date`**.
  This is the daily detail behind the trend chart, distribution chart, and
  daily-detail table below.
- `mart_city_weather_summary` — **one row per city**, aggregating the full
  observed period into the comfort ranking. This table does not respond to
  the date filter; it always reflects the full extracted history per city.
- `fct_air_quality_city_day` — **one row per city and `air_quality_date`**,
  used for the air quality section.
- `dim_location` — **one row per city**, used for names, country, and the map.

**Metric definitions**

- **Comfort score (0-100)**: a weighted score combining the share of
  comfortable days (45%), dry days (20%), non-hot days (15%), non-windy days
  (10%), and good-air-quality days (10%). Higher is more comfortable.
- **Comfortable day**: mean temperature between 18-26°C, and not rainy,
  windy, hot, or a poor-air-quality day.
- **Rainy day**: precipitation or rain sum greater than 0 mm.
- **Heavy rain day**: precipitation sum >= 10 mm.
- **Hot day / Extreme heat day**: max temperature >= 30°C / >= 35°C.
- **Windy day**: max wind speed >= 30 km/h.
- **Poor air quality day**: max daily European AQI >= 60.
- **Air quality coverage**: air quality readings only cover a handful of
  recent days per city (see the note in the Air Quality section), so
  `has_air_quality_data` is used to flag which weather days actually have a
  matching air quality rollup.
        """
    )

# ---------------------------------------------------------------------------
# KPI row (based on the city comfort summary mart)
# ---------------------------------------------------------------------------
st.subheader("City comfort summary")
st.caption(
    f"Aggregated over each city's full extracted period "
    f"({summary_f['first_weather_date'].min()} to {summary_f['last_weather_date'].max()})."
)

top_city = summary_f.sort_values("comfort_score", ascending=False).iloc[0]

kpi_cols = st.columns(5)
kpi_cols[0].metric("Most comfortable city", top_city["city"], f"{top_city['comfort_score']:.1f} / 100")
kpi_cols[1].metric("Avg. mean temperature", f"{summary_f['avg_temperature_celsius'].mean():.1f} °C")
kpi_cols[2].metric("Total rainy days", int(summary_f["rainy_days"].sum()))
kpi_cols[3].metric("Total hot days", int(summary_f["hot_days"].sum()))
kpi_cols[4].metric("Total windy days", int(summary_f["windy_days"].sum()))

# ---------------------------------------------------------------------------
# Comfort ranking: chart + table
# ---------------------------------------------------------------------------
col_chart, col_table = st.columns([1, 1.4])

with col_chart:
    st.markdown("**Comfort score ranking**")
    rank_chart = (
        alt.Chart(summary_f)
        .mark_bar()
        .encode(
            x=alt.X("comfort_score:Q", title="Comfort score (0-100)"),
            y=alt.Y("city:N", sort="-x", title=None),
            color=alt.Color("city:N", legend=None),
            tooltip=["city", "comfort_score", "avg_temperature_celsius", "comfortable_days", "total_days"],
        )
        .properties(height=300)
    )
    st.altair_chart(rank_chart, use_container_width=True)

with col_table:
    st.markdown("**City comfort details**")
    display_cols = {
        "city": "City",
        "comfort_score": "Comfort score",
        "avg_temperature_celsius": "Avg temp (°C)",
        "total_days": "Days observed",
        "rainy_days": "Rainy days",
        "hot_days": "Hot days",
        "windy_days": "Windy days",
        "comfortable_days": "Comfortable days",
        "poor_air_quality_days": "Poor AQ days",
        "air_quality_days": "AQ days",
    }
    table_df = (
        summary_f[list(display_cols.keys())]
        .rename(columns=display_cols)
        .sort_values("Comfort score", ascending=False)
        .reset_index(drop=True)
    )
    st.dataframe(table_df, use_container_width=True, hide_index=True)

# ---------------------------------------------------------------------------
# Daily trend chart
# ---------------------------------------------------------------------------
st.subheader("Daily temperature trend")
st.caption(
    "Mean daily temperature per city for the selected date range. "
    f"Grain: one point per `location_id` + `weather_date` in {daily_f['weather_date'].dt.date.min()} "
    f"to {daily_f['weather_date'].dt.date.max()}."
)

trend_chart = (
    alt.Chart(daily_f)
    .mark_line(point=True)
    .encode(
        x=alt.X("weather_date:T", title="Date"),
        y=alt.Y("temperature_mean_celsius:Q", title="Mean temperature (°C)"),
        color=alt.Color("city:N", title="City"),
        tooltip=["city", "weather_date:T", "temperature_mean_celsius", "is_comfortable_day"],
    )
    .properties(height=350)
)
st.altair_chart(trend_chart, use_container_width=True)

# ---------------------------------------------------------------------------
# Temperature distribution
# ---------------------------------------------------------------------------
col_dist, col_map = st.columns([1.2, 1])

with col_dist:
    st.subheader("Daily temperature distribution")
    dist_chart = (
        alt.Chart(daily_f)
        .mark_boxplot(extent="min-max")
        .encode(
            x=alt.X("city:N", title=None),
            y=alt.Y("temperature_mean_celsius:Q", title="Mean temperature (°C)"),
            color=alt.Color("city:N", legend=None),
        )
        .properties(height=350)
    )
    st.altair_chart(dist_chart, use_container_width=True)

with col_map:
    st.subheader("Selected cities")
    map_df = locations[locations["city"].isin(selected_cities)][["city", "latitude", "longitude"]].rename(
        columns={"latitude": "lat", "longitude": "lon"}
    )
    st.map(map_df, latitude="lat", longitude="lon", size=20000)

# ---------------------------------------------------------------------------
# Air quality section
# ---------------------------------------------------------------------------
st.subheader("Air quality")

coverage = (
    daily_f.groupby("city")["has_air_quality_data"]
    .agg(days_with_aq="sum", total_days="count")
    .reset_index()
)
coverage["coverage_pct"] = (100 * coverage["days_with_aq"] / coverage["total_days"]).round(1)

st.info(
    "Air quality coverage is sparse: the hourly air quality extract only overlaps with a "
    "few of the most recent weather dates per city. The table below shows, for the selected "
    "date range, how many days actually have a matching `fct_air_quality_city_day` record "
    "(`has_air_quality_data` = true)."
)

col_aq_chart, col_aq_table = st.columns([1.4, 1])

with col_aq_chart:
    if aq_f.empty:
        st.warning("No air quality records fall within the selected date range and cities.")
    else:
        aq_f["air_quality_date_label"] = aq_f["air_quality_date"].dt.strftime("%Y-%m-%d")
        aqi_chart = (
            alt.Chart(aq_f)
            .mark_bar()
            .encode(
                x=alt.X("air_quality_date_label:N", title="Date"),
                xOffset=alt.XOffset("city:N"),
                y=alt.Y("avg_european_aqi:Q", title="Avg. European AQI"),
                color=alt.Color("city:N", title="City"),
                tooltip=["city", "air_quality_date:T", "avg_european_aqi", "is_poor_air_quality_day"],
            )
            .properties(height=300)
        )
        st.altair_chart(aqi_chart, use_container_width=True)

with col_aq_table:
    st.markdown("**Air quality data coverage**")
    st.dataframe(
        coverage.rename(
            columns={
                "city": "City",
                "days_with_aq": "Days with AQ data",
                "total_days": "Days in range",
                "coverage_pct": "Coverage %",
            }
        ),
        use_container_width=True,
        hide_index=True,
    )

# ---------------------------------------------------------------------------
# Daily detail table
# ---------------------------------------------------------------------------
with st.expander("Daily detail table (fct_city_weather_day)"):
    detail_cols = {
        "city": "City",
        "weather_date": "Date",
        "temperature_mean_celsius": "Mean temp (°C)",
        "temperature_max_celsius": "Max temp (°C)",
        "temperature_min_celsius": "Min temp (°C)",
        "precipitation_mm": "Precipitation (mm)",
        "wind_speed_max_kmh": "Max wind (km/h)",
        "avg_european_aqi": "Avg AQI",
        "is_rainy_day": "Rainy",
        "is_hot_day": "Hot",
        "is_windy_day": "Windy",
        "is_comfortable_day": "Comfortable",
        "has_air_quality_data": "Has AQ data",
    }
    detail_df = (
        daily_f[list(detail_cols.keys())]
        .rename(columns=detail_cols)
        .sort_values(["City", "Date"])
        .reset_index(drop=True)
    )
    st.dataframe(detail_df, use_container_width=True, hide_index=True)
