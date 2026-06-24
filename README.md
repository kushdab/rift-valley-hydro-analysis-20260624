# Rift Valley Hydro Analysis

Statistical modelling of historical water table levels and their correlation
with rainfall in the Rift Valley region (simulated 1990-2025 dataset).

## Features

- Synthetic but realistic monthly hydro dataset (rainfall, water table depth, evapotranspiration)
- Pearson correlation matrix across lagged and rolling-average rainfall variables
- Multiple linear regression model for water table depth
- Augmented Dickey-Fuller stationarity test
- ARIMA seasonal time-series model with 24-month forecast
- Four publication-ready figures saved to `figures/`

## Installation

```r
# Install R (>= 4.2) from https://cran.r-project.org
# All required packages are auto-installed on first run
```

Required R packages (auto-installed):
- ggplot2, dplyr, tidyr, lubridate
- corrplot, forecast, tseries, gridExtra, zoo

## Usage

```bash
# Clone the repository
git clone https://github.com/your-org/rift-valley-hydro-analysis-20260624.git
cd rift-valley-hydro-analysis-20260624

# Run the analysis
Rscript analysis.R
```

Or open `analysis.R` in RStudio and click **Source**.

Output figures are written to `figures/`:

| File | Description |
|---|---|
| `01_timeseries.png` | Monthly rainfall and water table time series |
| `02_correlation.png` | Pearson correlation heat-map |
| `03_annual_trends.png` | Annual rainfall and water table trend lines |
| `04_arima_forecast.png` | 24-month ARIMA water table forecast |

## Project Structure

```
rift-valley-hydro-analysis-20260624/
├── analysis.R        # Main analysis script
├── figures/          # Generated plots (created at runtime)
├── README.md
└── .gitignore
```

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
