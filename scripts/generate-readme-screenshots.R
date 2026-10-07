#!/usr/bin/env Rscript

# Capture representative reveal.js slides for the repository README.

if (!requireNamespace("chromote", quietly = TRUE)) {
  stop("The chromote package is required.")
}

gallery_path <- normalizePath(
  file.path("_build", "examples", "gallery.html"),
  winslash = "/",
  mustWork = TRUE
)

output_dir <- file.path("docs", "images")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

gallery_url <- paste0("file:///", gallery_path)

slides <- c(
  "title-slide.png" = "title-slide",
  "two-column-slide.png" = "slide-with-a-figure-and-text",
  "section-divider.png" = "section-divider"
)

browser <- chromote::ChromoteSession$new()
on.exit(browser$close(), add = TRUE)
browser$set_viewport_size(width = 1600, height = 900)

hide_reveal_controls <- paste(
  "for (const selector of",
  "['.controls', '.slide-menu-button', '.progress']) {",
  "const element = document.querySelector(selector);",
  "if (element) element.style.display = 'none';",
  "}",
  sep = " "
)

for (filename in names(slides)) {
  browser$go_to(
    paste0(gallery_url, "#/", slides[[filename]]),
    wait_ = FALSE
  )
  Sys.sleep(2)
  browser$Runtime$evaluate(expression = hide_reveal_controls)
  browser$screenshot(
    filename = file.path(output_dir, filename),
    selector = "html",
    delay = 0.5
  )
}

message("Generated README screenshots in ", normalizePath(output_dir))
