[CmdletBinding()]
param(
  [string]$BuildRoot
)

$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $BuildRoot) {
  $BuildRoot = Join-Path $repositoryRoot "_build"
}
$BuildRoot = (Resolve-Path $BuildRoot).Path

$galleryPath = Join-Path $BuildRoot "examples\gallery.html"
$galleryFiles = Join-Path $BuildRoot "examples\gallery_files"

if (-not (Test-Path -LiteralPath $galleryPath)) {
  throw "Rendered gallery not found at $galleryPath"
}

$themeCssFile = Get-ChildItem -Path $galleryFiles -Recurse -Filter "*.css" |
  Where-Object { Select-String -Quiet -LiteralPath $_.FullName -Pattern "--cfs-forest" } |
  Select-Object -First 1

if (-not $themeCssFile) {
  throw "Compiled CFS theme CSS was not found below $galleryFiles"
}

$themeCss = Get-Content -Raw -LiteralPath $themeCssFile.FullName

# Reveal.js owns the display property of slide <section> elements. Overriding
# it makes inactive slides visible and layers them over the current slide.
$forcedSectionDisplay =
  '(?s)\.reveal\s+\.slides\s+section[^\{]*\{[^\}]*display\s*:\s*(?:flex|grid)\s*!important'
if ($themeCss -match $forcedSectionDisplay) {
  throw "Theme CSS forces slide sections to display and breaks reveal.js navigation."
}

# A positioned title slide must remain absolute. Relative positioning makes a
# loaded, inactive title slide occupy the first canvas and pushes slide 2 down
# by the full presentation height.
$relativeTitlePosition =
  '(?s)#title-slide,[^\{]*section\.quarto-title-block\{[^\}]*position\s*:\s*relative'
if ($themeCss -match $relativeTitlePosition) {
  throw "The title slide uses relative positioning and displaces nearby slides."
}

if ($themeCss -notmatch 'slide-number\{[^\}]*bottom:[^;]*!important[^\}]*top:\s*auto\s*!important') {
  throw "Slide numbers are not pinned to the bottom-right."
}

if ($themeCss -notmatch 'slide-menu-button\{display:\s*none\s*!important') {
  throw "The visible slide-menu button is not suppressed."
}

if ($themeCss -match 'conclusion-slide') {
  throw "Removed conclusion-slide styling remains in the compiled theme."
}

if ($themeCss -notmatch '--r-main-font:\s*Source Sans Pro') {
  throw "Source Sans Pro is not the primary compiled presentation font."
}

if ($themeCss -notmatch '--r-heading-font-weight:\s*600') {
  throw "Heading weight does not match the bundled Source Sans Pro semibold face."
}

if ($themeCss -match 'section\.present\.section-slide\) \.slide-number') {
  throw "The theme suppresses slide numbers on section dividers."
}

if ($themeCss -notmatch 'section\.present\.section-slide\) \.slide-logo') {
  throw "The theme does not suppress the persistent logo on section dividers."
}

$revealCssPath = Join-Path $galleryFiles "libs\revealjs\dist\reveal.css"
$revealCss = Get-Content -Raw -LiteralPath $revealCssPath
if ($revealCss -notmatch '\.reveal \.slides>section,\.reveal \.slides>section>section\{display:none') {
  throw "The expected reveal.js inactive-slide visibility rule is missing."
}

$galleryHtml = Get-Content -Raw -LiteralPath $galleryPath
$requiredTokens = [ordered]@{
  "title slide" = 'id="title-slide"'
  "section divider" = "section-slide"
  "key result" = "key-result"
  "columns" = 'class="columns'
  "speaker notes" = '<aside class="notes">'
  "incremental fragment" = "fragment"
  "citation" = 'role="doc-biblioref"'
  "figure alt text" = 'alt="Synthetic raster map'
  "persistent logo" = 'class="slide-logo"'
  "title logo" = 'class="cfs-corporate-signature"'
}

foreach ($check in $requiredTokens.GetEnumerator()) {
  if (-not $galleryHtml.Contains($check.Value)) {
    throw "Rendered gallery is missing $($check.Key)."
  }
}

if ($galleryHtml.Contains("Invalid Date")) {
  throw "The gallery contains an invalid placeholder date."
}

if (
  $galleryHtml.Contains("conclusion-slide") -or
  $galleryHtml.Contains("Slide with a long title that wraps onto two lines")
) {
  throw "The gallery still contains a removed slide or layout."
}

if ($galleryHtml.Contains("Organization name | Presentation title")) {
  throw "The gallery footer still contains the organization placeholder."
}

if ($galleryHtml -notmatch 'NRCan_CFS_logo_PT_englishOnly\.svg') {
  throw "The rendered gallery does not reference the supplied NRCan CFS logo."
}

$regularSlideStart = $galleryHtml.IndexOf('<section id="regular-content-slide"')
$dividerSlideStart = $galleryHtml.IndexOf('<section id="section-divider"')
$processSlideStart = $galleryHtml.IndexOf('<section id="slide-with-a-process"')
if ($regularSlideStart -lt 0 -or $dividerSlideStart -lt 0 -or $processSlideStart -lt 0) {
  throw "The first four gallery slides could not be located."
}

$regularSlide = $galleryHtml.Substring(
  $regularSlideStart,
  $dividerSlideStart - $regularSlideStart
)
if ($regularSlide.Contains("<aside") -or $regularSlide.Contains("<style")) {
  throw "The regular content slide contains hidden notes or injected style markup."
}

$dividerSlide = $galleryHtml.Substring(
  $dividerSlideStart,
  $processSlideStart - $dividerSlideStart
)
if (
  $dividerSlide -notmatch 'class="[^"]*section-slide[^"]*center' -or
  -not $dividerSlide.Contains('data-background-color="#183F35"')
) {
  throw "The section divider is not using native reveal.js centering and background attributes."
}

Write-Host "Rendered theme checks passed: visibility, font, and gallery structure"
