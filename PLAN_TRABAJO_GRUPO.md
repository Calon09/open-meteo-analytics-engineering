# Plan de trabajo del proyecto en grupo: Open-Meteo

## Resumen del enunciado

El objetivo del trabajo es construir un proyecto completo de Analytics Engineering usando datos de la API publica de Open-Meteo.

El flujo esperado del proyecto es:

1. Extraer datos desde la API de Open-Meteo.
2. Guardar los datos raw en archivos CSV.
3. Cargar esos archivos en DuckDB o leerlos como fuentes externas.
4. Registrar las fuentes raw en dbt.
5. Construir modelos dbt en capas: staging, intermediate, dimensions, facts y marts.
6. Crear tests y documentacion en dbt.
7. Construir un dashboard en Streamlit usando los modelos finales, no los archivos raw.
8. Publicar el proyecto en GitHub con instrucciones claras para reproducirlo.

Stack recomendado:

- DuckDB
- dbt Core
- Python
- Streamlit

## Datos a extraer

El script starter esta en:

```text
scripts/extract_open_meteo.py
```

Se ejecuta desde la carpeta del assignment:

```bash
uv run python scripts/extract_open_meteo.py
```

Por defecto extrae datos para:

- Madrid
- Barcelona
- Valencia
- Sevilla
- Bilbao

Tambien se pueden elegir ciudades y dias:

```bash
uv run python scripts/extract_open_meteo.py \
  --cities Madrid Barcelona Paris Berlin Lisbon \
  --past-days 60 \
  --forecast-days 7
```

Archivos raw esperados:

```text
data/raw/open_meteo/raw_locations.csv
data/raw/open_meteo/raw_weather_daily.csv
data/raw/open_meteo/raw_forecast_daily.csv
data/raw/open_meteo/raw_air_quality_hourly.csv
```

## Fuentes raw sugeridas

| Fuente | Grain | Descripcion |
|---|---|---|
| `raw_locations` | una fila por ciudad | Metadatos de ciudad desde Geocoding API |
| `raw_weather_daily` | una fila por ciudad y dia | Tiempo diario reciente |
| `raw_forecast_daily` | una fila por ciudad, fecha prevista y ejecucion | Prediccion diaria |
| `raw_air_quality_hourly` | una fila por ciudad y hora | Calidad del aire por hora |

## Modelos dbt requeridos

### Staging

Crear un modelo staging por cada fuente raw:

```text
models/staging/stg_locations.sql
models/staging/stg_weather_daily.sql
models/staging/stg_forecast_daily.sql
models/staging/stg_air_quality_hourly.sql
```

Responsabilidad de staging:

- Renombrar columnas a nombres claros en `snake_case`.
- Convertir tipos de datos: fechas, timestamps, numeros.
- Eliminar duplicados si aparecen.
- Mantener el mismo grain que la fuente raw.
- Evitar logica de negocio compleja.

### Intermediate

Crear modelos que combinen y preparen los datos para analisis:

```text
models/intermediate/int_air_quality_daily.sql
models/intermediate/int_city_day_weather.sql
models/intermediate/int_weather_flags.sql
models/intermediate/int_forecast_accuracy.sql
```

Ideas de logica intermedia:

- Calcular la calidad media diaria del aire por ciudad.
- Marcar dias lluviosos, calurosos, ventosos o contaminados.
- Combinar datos meteorologicos diarios con calidad del aire diaria.
- Comparar forecast vs actual si hay datos suficientes.

### Dimensions, facts y marts

Modelos minimos:

```text
models/marts/dim_location.sql
models/marts/fct_city_weather_day.sql
```

Modelos recomendados:

```text
models/marts/fct_air_quality_city_day.sql
models/marts/fct_forecast_city_day.sql
models/marts/mart_city_weather_summary.sql
```

Grain recomendado del modelo principal:

```text
fct_city_weather_day: una fila por ciudad y fecha
```

## Tests de dbt recomendados

Anadir tests para validar:

- Primary keys unicas y no nulas.
- Fechas no nulas.
- `location_id` no nulo.
- Relaciones entre facts y `dim_location`.
- Valores aceptados para campos categoricos, si se crean.
- Rangos razonables para metricas meteorologicas:
  - temperatura
  - precipitacion
  - viento
  - AQI
  - PM10
  - PM2.5

## Dashboard en Streamlit

El dashboard debe leer desde los modelos finales de dbt, no desde los CSV raw.

Debe incluir como minimo:

- Un filtro, por ejemplo ciudad, pais, rango de fechas o metrica.
- Al menos tres graficos o tablas.
- Definiciones claras de las metricas.
- Una nota explicando el grain del modelo principal.
- Instrucciones claras para ejecutarlo o un link publico si se despliega.

## Idea recomendada de dashboard

La opcion mas sencilla y solida para empezar es un **City Comfort Index**.

Pregunta principal:

```text
Que ciudades tuvieron el clima mas agradable durante el periodo seleccionado?
```

Metricas posibles:

- Temperatura media.
- Numero de dias comodos.
- Dias lluviosos.
- Dias ventosos.
- Dias de calor extremo.
- Calidad media del aire.
- Score general de confort.

Graficos posibles:

- Ranking de ciudades por comfort score.
- Evolucion temporal del comfort score.
- Distribucion de temperaturas diarias.
- Tabla con los dias mas agradables o menos agradables.

Alternativa:

**Weather Risk Monitor**, centrado en riesgo meteorologico:

- Dias de lluvia fuerte.
- Dias de viento fuerte.
- Dias de calor extremo.
- Horas o dias con mala calidad del aire.
- Score de riesgo por ciudad.

## Reparto inicial del trabajo entre 4 personas

### Persona 1: Extraccion y carga de datos

Responsabilidad:

Dejar funcionando la parte de extraccion y carga inicial.

Tareas:

- Ejecutar `scripts/extract_open_meteo.py`.
- Decidir junto al grupo las ciudades y periodo de analisis.
- Comprobar que se generan los cuatro CSV raw.
- Crear o adaptar un script para cargar los CSV en DuckDB, si se decide cargar tablas fisicas.
- Verificar que DuckDB puede leer los datos.
- Documentar los comandos de extraccion y carga en el README.

Primer entregable:

```text
CSV raw generados y datos accesibles desde DuckDB.
```

### Persona 2: Sources y staging en dbt

Responsabilidad:

Crear la base limpia del proyecto dbt.

Tareas:

- Crear `sources.yml` con las cuatro fuentes raw.
- Crear los modelos staging:
  - `stg_locations`
  - `stg_weather_daily`
  - `stg_forecast_daily`
  - `stg_air_quality_hourly`
- Renombrar columnas.
- Castear fechas, timestamps y numeros.
- Mantener el grain original.
- Crear tests basicos de staging.

Primer entregable:

```text
Sources definidos, staging models creados y dbt run funcionando para staging.
```

### Persona 3: Intermediate, facts y marts

Responsabilidad:

Construir la logica analitica principal.

Tareas:

- Crear `int_air_quality_daily`.
- Crear `int_city_day_weather`.
- Crear `int_weather_flags`.
- Crear `dim_location`.
- Crear `fct_city_weather_day`.
- Crear `fct_air_quality_city_day`, si aporta valor.
- Crear `mart_city_weather_summary`.
- Definir las metricas principales del dashboard.

Primer entregable:

```text
Modelo final mart listo para ser usado por Streamlit.
```

### Persona 4: Dashboard, README e integracion

Responsabilidad:

Convertir los modelos finales en una entrega usable y presentable.

Tareas:

- Crear `streamlit_app/app.py`.
- Conectar Streamlit con DuckDB.
- Leer desde los modelos finales de dbt.
- Crear filtros por ciudad y/o fecha.
- Crear al menos tres visualizaciones o tablas.
- Explicar las metricas dentro del dashboard.
- Mantener el README final del repositorio.
- Incluir instrucciones para:
  - extraer datos
  - cargar datos
  - ejecutar dbt
  - lanzar Streamlit
  - ver el dashboard

Primer entregable:

```text
Dashboard funcional con instrucciones claras de ejecucion.
```

## Primeros acuerdos que debe tomar el grupo

Antes de avanzar demasiado, conviene decidir:

1. Ciudades que se van a analizar.
2. Periodo de datos, por ejemplo 30, 60 o 90 dias.
3. Si se usara solo DuckDB local.
4. Si el dashboard sera City Comfort Index o Weather Risk Monitor.
5. Nombres definitivos de los modelos dbt.
6. Grain principal del proyecto.
7. Como se repartiran las ramas o tareas en GitHub.

## Primer objetivo comun

El primer hito deberia ser:

```text
Extraccion funcionando + datos cargados/leibles + sources y staging en dbt + primer dbt run exitoso.
```

Cuando eso este listo, el proyecto ya tendra una base solida para que cada persona avance en paralelo.

## Entregable final

El repositorio final debe incluir:

- Script o pipeline de extraccion.
- Archivos raw o instrucciones para reproducirlos.
- Proyecto dbt completo.
- Tests y documentacion de dbt.
- Dashboard de Streamlit.
- README con instrucciones claras.
- Explicacion corta de las decisiones de modelado.
- Link publico al dashboard o instrucciones locales para ejecutarlo.

Preguntas que el README final debe responder:

```text
Como ejecuto la extraccion?
Como cargo los datos?
Como ejecuto dbt?
Como abro el dashboard?
Que modelos finales alimentan el dashboard?
```
