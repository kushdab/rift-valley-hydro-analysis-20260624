# rift-valley-hydro-analysis-20260624
# Statistical modeling of water table levels and rainfall correlation
# in the Rift Valley region

# ── 0. Dependencies ────────────────────────────────────────────────────────────
required_pkgs <- c("ggplot2", "dplyr", "tidyr", "lubridate",
                   "corrplot", "forecast", "tseries", "gridExtra")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
}
invisible(lapply(required_pkgs, install_if_missing))

library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(corrplot)
library(forecast)
library(tseries)
library(gridExtra)

set.seed(20260624)

# ── 1. Simulate Rift Valley hydro data (1990-2025) ─────────────────────────────
months_seq <- seq(as.Date("1990-01-01"), as.Date("2025-12-01"), by = "month")
n <- length(months_seq)

# Seasonal rainfall (mm) – bimodal East African pattern (Mar-May, Oct-Dec)
month_num <- month(months_seq)
rainfall_seasonal <- 60 + 45 * sin((month_num - 3) * pi / 5) +
                         30 * sin((month_num - 9) * pi / 4)
rainfall_trend    <- seq(0, -12, length.out = n)          # mild drying trend
rainfall_noise    <- rnorm(n, 0, 18)
rainfall          <- pmax(rainfall_seasonal + rainfall_trend + rainfall_noise, 0)

# Water table depth (m below surface) – higher depth = lower table
# Responds to rainfall with 2-month lag; long-term decline
water_table <- numeric(n)
water_table[1] <- 8.5
for (i in seq(2, n)) {
  lag_rain <- if (i > 2) rainfall[i - 2] else rainfall[1]
  water_table[i] <- 0.92 * water_table[i - 1] -
                    0.018 * lag_rain +
                    0.004 * (i / 12) +        # long-term decline
                    rnorm(1, 0, 0.25)
}
water_table <- pmax(water_table, 1.5)

# Evapotranspiration proxy (mm)
et <- 90 + 25 * sin((month_num - 1) * pi / 6) + rnorm(n, 0, 8)

hydro_df <- tibble(
  date         = months_seq,
  year         = year(months_seq),
  month        = month_num,
  rainfall_mm  = round(rainfall, 1),
  water_table_m= round(water_table, 3),
  et_mm        = round(et, 1)
) %>%
  mutate(rain_lag2 = lag(rainfall_mm, 2),
         rain_lag3 = lag(rainfall_mm, 3),
         rain_3mo  = zoo::rollmean(rainfall_mm, 3, fill = NA, align = "right"))

# ── 2. Summary statistics ──────────────────────────────────────────────────────
cat("\n=== Rift Valley Hydro Analysis ===\n")
cat(sprintf("Period      : %s to %s\n", min(hydro_df$date), max(hydro_df$date)))
cat(sprintf("Observations: %d monthly records\n", n))
cat("\n--- Rainfall (mm) ---\n")
print(summary(hydro_df$rainfall_mm))
cat("\n--- Water Table Depth (m) ---\n")
print(summary(hydro_df$water_table_m))

# ── 3. Correlation analysis ────────────────────────────────────────────────────
clean_df <- hydro_df %>% drop_na()
cor_matrix <- cor(clean_df %>% select(rainfall_mm, rain_lag2, rain_lag3,
                                       rain_3mo, et_mm, water_table_m))
cat("\n--- Pearson Correlation Matrix ---\n")
print(round(cor_matrix, 3))

# ── 4. Linear regression model ────────────────────────────────────────────────
model_lm <- lm(water_table_m ~ rain_lag2 + rain_3mo + et_mm +
                 I(as.numeric(date)),
               data = clean_df)
cat("\n--- Linear Regression Summary ---\n")
print(summary(model_lm))

# ── 5. Annual aggregation ──────────────────────────────────────────────────────
annual_df <- hydro_df %>%
  group_by(year) %>%
  summarise(total_rainfall  = sum(rainfall_mm, na.rm = TRUE),
            mean_wt         = mean(water_table_m, na.rm = TRUE),
            min_wt          = min(water_table_m, na.rm = TRUE),
            .groups = "drop")

# Pearson correlation between annual rainfall and mean water table
anno_cor <- cor.test(annual_df$total_rainfall, annual_df$mean_wt)
cat(sprintf("\nAnnual rainfall vs water-table depth: r = %.3f, p = %.4f\n",
            anno_cor$estimate, anno_cor$p.value))

# ── 6. ARIMA forecast on water table ──────────────────────────────────────────
wt_ts <- ts(hydro_df$water_table_m, start = c(1990, 1), frequency = 12)
adf_result <- adf.test(wt_ts, alternative = "stationary")
cat(sprintf("\nADF test p-value: %.4f (%s)\n", adf_result$p.value,
            ifelse(adf_result$p.value < 0.05, "stationary", "non-stationary")))

arima_fit  <- auto.arima(wt_ts, seasonal = TRUE, stepwise = TRUE, approximation = TRUE)
wt_forecast <- forecast(arima_fit, h = 24)
cat("\n--- ARIMA Model ---\n")
print(arima_fit)

# ── 7. Visualisations ─────────────────────────────────────────────────────────
dir.create("figures", showWarnings = FALSE)

# 7a. Time series overview
p1 <- ggplot(hydro_df, aes(date, rainfall_mm)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  labs(title = "Monthly Rainfall – Rift Valley", x = NULL, y = "Rainfall (mm)") +
  theme_minimal()

p2 <- ggplot(hydro_df, aes(date, water_table_m)) +
  geom_line(colour = "darkorange", linewidth = 0.6) +
  scale_y_reverse() +
  labs(title = "Water Table Depth", x = NULL, y = "Depth (m, reversed)") +
  theme_minimal()

ggsave("figures/01_timeseries.png",
       plot = grid.arrange(p1, p2, nrow = 2), width = 12, height = 7, dpi = 150)

# 7b. Correlation heatmap
png("figures/02_correlation.png", width = 800, height = 700)
corrplot(cor_matrix, method = "color", type = "upper",
         addCoef.col = "black", tl.col = "black",
         title = "Correlation Matrix – Hydro Variables", mar = c(0,0,2,0))
dev.off()

# 7c. Annual totals & water table trend
p3 <- ggplot(annual_df, aes(year, total_rainfall)) +
  geom_col(fill = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, colour = "navy") +
  labs(title = "Annual Rainfall Trend", x = "Year", y = "Total Rainfall (mm)") +
  theme_minimal()

p4 <- ggplot(annual_df, aes(year, mean_wt)) +
  geom_line(colour = "firebrick", linewidth = 1) +
  geom_smooth(method = "lm", se = TRUE, colour = "darkred") +
  scale_y_reverse() +
  labs(title = "Mean Annual Water Table Depth", x = "Year", y = "Depth (m)") +
  theme_minimal()

ggsave("figures/03_annual_trends.png",
       plot = grid.arrange(p3, p4, nrow = 1), width = 12, height = 5, dpi = 150)

# 7d. ARIMA forecast plot
png("figures/04_arima_forecast.png", width = 1000, height = 500)
autoplot(wt_forecast) +
  labs(title = "24-Month Water Table Forecast (ARIMA)",
       x = "Year", y = "Depth (m)") +
  theme_minimal()
dev.off()

cat("\nAnalysis complete. Figures saved to ./figures/\n")
