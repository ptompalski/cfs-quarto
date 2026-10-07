# Optional ggplot2 helpers for figures that match the cfs-revealjs palette.
# Source this file only in projects that already use ggplot2.

cfs_colours <- c(
  forest = "#183F35",
  sage = "#77917B",
  off_white = "#F5F7F3",
  charcoal = "#26342F",
  blue = "#31758C"
)

scale_colour_cfs <- function(..., aesthetics = "colour") {
  ggplot2::scale_colour_manual(
    values = unname(cfs_colours[c("forest", "blue", "sage", "charcoal")]),
    aesthetics = aesthetics,
    ...
  )
}

scale_fill_cfs <- function(...) {
  ggplot2::scale_fill_manual(
    values = unname(cfs_colours[c("forest", "blue", "sage", "off_white")]),
    ...
  )
}

theme_cfs <- function(base_size = 18, base_family = "Source Sans 3") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        colour = cfs_colours[["forest"]],
        face = "bold",
        size = ggplot2::rel(1.2)
      ),
      plot.subtitle = ggplot2::element_text(colour = cfs_colours[["charcoal"]]),
      axis.title = ggplot2::element_text(colour = cfs_colours[["charcoal"]]),
      axis.text = ggplot2::element_text(colour = cfs_colours[["charcoal"]]),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E5EAE6", linewidth = 0.4),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}
