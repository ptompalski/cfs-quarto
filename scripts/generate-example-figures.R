#!/usr/bin/env Rscript

# Generate deterministic, synthetic scientific figures for the gallery.
# The core extension does not require R; these PNG files are committed so the
# gallery renders in environments without R.

output_dir <- file.path("examples", "assets")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

forest <- "#183F35"
sage <- "#77917B"
off_white <- "#F5F7F3"
charcoal <- "#26342F"
blue <- "#31758C"
rule <- "#D5DDD7"

open_png <- function(filename, width = 1600, height = 820) {
  png(
    filename = file.path(output_dir, filename),
    width = width,
    height = height,
    res = 160,
    bg = "white",
    type = if (capabilities("cairo")) "cairo-png" else "windows"
  )
}

set.seed(20261006)

# Synthetic remote-sensing surface
x <- seq(-1, 1, length.out = 180)
y <- seq(-1, 1, length.out = 110)
surface <- outer(
  x,
  y,
  function(x, y) {
    0.55 +
      0.30 * exp(-5 * ((x + 0.42)^2 + (y - 0.18)^2)) -
      0.25 * exp(-8 * ((x - 0.34)^2 + (y + 0.25)^2)) +
      0.10 * sin(5 * x) * cos(4 * y)
  }
)
surface[] <- pmax(0.05, pmin(0.95, surface))

open_png("synthetic-canopy-map.png", 1600, 860)
par(
  mar = c(3.4, 3.7, 0.6, 6.2),
  mgp = c(2.1, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
palette_map <- colorRampPalette(c(off_white, "#C9D7CA", sage, forest))(80)
image(
  x,
  y,
  surface,
  col = palette_map,
  axes = FALSE,
  xlab = "Easting (standardized)",
  ylab = "Northing (standardized)",
  useRaster = TRUE
)
contour(x, y, surface, add = TRUE, drawlabels = FALSE, col = "#FFFFFF88", lwd = 0.8)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, col = rule, col.ticks = rule, tck = -0.015, las = 1)
box(col = rule)
legend_y <- seq(-0.75, 0.75, length.out = length(palette_map) + 1)
for (i in seq_along(palette_map)) {
  rect(1.08, legend_y[i], 1.14, legend_y[i + 1], col = palette_map[i], border = NA, xpd = NA)
}
text(1.11, 0.84, "Spatial\nindex", cex = 0.8, col = charcoal, xpd = NA)
text(1.18, c(-0.75, 0.75), labels = c("0.1", "0.9"), adj = 0, cex = 0.72, col = charcoal, xpd = NA)
dev.off()

# A second spatial product for the paired-figure layout
disturbance <- 0.25 + 0.55 * exp(
  -10 * (
    (outer(x, rep(1, length(y))) - 0.30)^2 +
      (outer(rep(1, length(x)), y) + 0.20)^2
  )
) + outer(sin(3 * x), cos(2 * y)) * 0.08
disturbance[] <- pmax(0, pmin(1, disturbance))

open_png("synthetic-disturbance-map.png", 900, 620)
par(
  mar = c(3.4, 3.7, 0.6, 0.8),
  mgp = c(2.1, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
image(
  x,
  y,
  disturbance,
  col = colorRampPalette(c(off_white, "#B8D0D8", blue, forest))(70),
  axes = FALSE,
  xlab = "Easting (standardized)",
  ylab = "Northing (standardized)",
  useRaster = TRUE
)
contour(x, y, disturbance, add = TRUE, drawlabels = FALSE, col = "#FFFFFF88", lwd = 0.8)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, col = rule, col.ticks = rule, tck = -0.015, las = 1)
box(col = rule)
dev.off()

# Synthetic time series with uncertainty band
year <- 2005:2025
estimate <- 62 + 0.9 * (year - 2005) + sin((year - 2005) / 2.5) * 3 + rnorm(length(year), 0, 1.2)
uncertainty <- seq(4.8, 2.6, length.out = length(year))

open_png("synthetic-time-series.png", 1600, 820)
par(
  mar = c(3.5, 4.2, 0.6, 0.8),
  mgp = c(2.2, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
plot(
  year,
  estimate,
  type = "n",
  ylim = range(estimate - uncertainty, estimate + uncertainty),
  xlab = "Year",
  ylab = "Response index",
  axes = FALSE
)
abline(h = pretty(par("usr")[3:4]), col = off_white, lwd = 2)
polygon(
  c(year, rev(year)),
  c(estimate - uncertainty, rev(estimate + uncertainty)),
  col = "#77917B55",
  border = NA
)
lines(year, estimate, col = forest, lwd = 4)
points(year[c(1, 6, 11, 16, 21)], estimate[c(1, 6, 11, 16, 21)], pch = 21, bg = blue, col = "white", cex = 1.35, lwd = 1.5)
axis(1, at = seq(2005, 2025, 5), col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)
legend(
  "topleft",
  legend = c("Annual estimate", "95% interval"),
  col = c(forest, sage),
  lwd = c(4, 8),
  bty = "n",
  cex = 0.82,
  text.col = charcoal
)
dev.off()

# Annual change, used only in the paired-figure layout
annual_change <- c(NA, diff(estimate))
open_png("synthetic-annual-change.png", 900, 620)
par(
  mar = c(3.5, 4.2, 0.6, 0.8),
  mgp = c(2.2, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
bar_cols <- ifelse(annual_change[-1] >= 0, sage, blue)
barplot(
  annual_change[-1],
  names.arg = year[-1],
  col = bar_cols,
  border = NA,
  xlab = "Year",
  ylab = "Annual index change",
  xaxt = "n"
)
axis(1, at = seq(1, 20, 5), labels = year[-1][seq(1, 20, 5)], col = rule, col.ticks = rule)
abline(h = 0, col = charcoal, lwd = 1.2)
box(col = rule)
dev.off()

# Two compact panels for a standard two-column scientific slide
open_png("synthetic-model-panels.png", 1600, 820)
par(
  mfrow = c(1, 2),
  mar = c(3.8, 4.2, 2.2, 0.8),
  mgp = c(2.2, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)

n <- 120
moisture <- runif(n, 0.1, 0.95)
growth <- 18 + 28 * moisture - 16 * moisture^2 + rnorm(n, 0, 2.3)
plot(
  moisture,
  growth,
  pch = 21,
  bg = "#31758C99",
  col = "white",
  cex = 1.05,
  xlab = "Predictor index",
  ylab = "Response value",
  main = "Observed response",
  axes = FALSE
)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)
fit <- lm(growth ~ moisture + I(moisture^2))
grid_x <- seq(0.1, 0.95, length.out = 200)
lines(grid_x, predict(fit, newdata = data.frame(moisture = grid_x)), col = forest, lwd = 4)

residuals_fit <- residuals(fit)
fitted_fit <- fitted(fit)
plot(
  fitted_fit,
  residuals_fit,
  pch = 21,
  bg = "#77917B99",
  col = "white",
  cex = 1.05,
  xlab = "Fitted value",
  ylab = "Residual",
  main = "Residual check",
  axes = FALSE
)
abline(h = 0, col = forest, lwd = 3)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)
dev.off()

# Stand-age response for the long-title stress test
stand_age <- seq(5, 120, length.out = 90)
recovery_age <- 42 + 0.62 * stand_age - 0.0028 * stand_age^2 + rnorm(length(stand_age), 0, 3.5)
open_png("synthetic-age-response.png", 960, 680)
par(
  mar = c(3.8, 4.2, 0.6, 0.8),
  mgp = c(2.2, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
plot(
  stand_age,
  recovery_age,
  pch = 21,
  bg = "#31758C99",
  col = "white",
  cex = 1.05,
  xlab = "Predictor value",
  ylab = "Response index",
  axes = FALSE
)
fit_age <- lm(recovery_age ~ stand_age + I(stand_age^2))
lines(stand_age, predict(fit_age), col = forest, lwd = 4)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)
dev.off()

# Validation summaries for the minimal, footer-free figure slide
open_png("synthetic-validation-panels.png", 1600, 820)
par(
  mfrow = c(1, 2),
  mar = c(3.8, 4.2, 2.2, 0.8),
  mgp = c(2.2, 0.65, 0),
  family = "sans",
  fg = charcoal,
  col.axis = charcoal,
  col.lab = charcoal
)
hist(
  residuals_fit,
  breaks = 14,
  col = sage,
  border = "white",
  xlab = "Residual",
  ylab = "Plot count",
  main = "Residual distribution",
  axes = FALSE
)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)

ordered <- sort(residuals_fit)
expected <- qnorm(ppoints(length(ordered)))
plot(
  expected,
  ordered,
  pch = 21,
  bg = "#31758C99",
  col = "white",
  cex = 1.05,
  xlab = "Expected normal quantile",
  ylab = "Observed residual quantile",
  main = "Quantile comparison",
  axes = FALSE
)
qqline(residuals_fit, col = forest, lwd = 3)
axis(1, col = rule, col.ticks = rule, tck = -0.015)
axis(2, las = 1, col = rule, col.ticks = rule, tck = -0.015)
box(col = rule)
dev.off()

message("Generated gallery figures in ", normalizePath(output_dir))
