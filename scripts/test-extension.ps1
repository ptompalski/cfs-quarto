[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$buildRoot = Join-Path $repositoryRoot "_build"
$runId = [Guid]::NewGuid().ToString("N")
$packageRoot = Join-Path $buildRoot "package-$runId"
$smokeRoot = Join-Path $buildRoot "smoke-$runId"
$templateRoot = Join-Path $buildRoot "template-$runId"
$archivePath = Join-Path $buildRoot "cfs-quarto-$runId.zip"

New-Item -ItemType Directory -Force -Path $packageRoot, $smokeRoot, $templateRoot | Out-Null

Write-Host "Rendering repository project"
& quarto render $repositoryRoot
if ($LASTEXITCODE -ne 0) { throw "Repository render failed." }

& (Join-Path $repositoryRoot "tests\check-rendered-theme.ps1") -BuildRoot $buildRoot
if ($LASTEXITCODE -ne 0) { throw "Rendered theme checks failed." }

Copy-Item -Recurse -LiteralPath (Join-Path $repositoryRoot "_extensions") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $repositoryRoot "template.qmd") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $repositoryRoot "NRCan_CFS_logo_PT_englishOnly.svg") -Destination $packageRoot
Compress-Archive -Path (Join-Path $packageRoot "*") -DestinationPath $archivePath

Copy-Item -LiteralPath (Join-Path $repositoryRoot "tests\smoke.qmd") -Destination $smokeRoot
Copy-Item -LiteralPath (Join-Path $repositoryRoot "tests\footer-two-authors.qmd") -Destination $smokeRoot
Copy-Item -LiteralPath (Join-Path $repositoryRoot "tests\footer-many-authors.qmd") -Destination $smokeRoot

Push-Location $smokeRoot
try {
  Write-Host "Installing extension package in $smokeRoot"
  & quarto add $archivePath --no-prompt
  if ($LASTEXITCODE -ne 0) { throw "Extension installation failed." }

  & quarto render smoke.qmd
  if ($LASTEXITCODE -ne 0) { throw "Installed extension render failed." }

  if (-not (Test-Path -LiteralPath (Join-Path $smokeRoot "smoke.html"))) {
    throw "Smoke-test HTML was not created."
  }

  & quarto render footer-two-authors.qmd
  if ($LASTEXITCODE -ne 0) { throw "Two-author footer render failed." }

  & quarto render footer-many-authors.qmd
  if ($LASTEXITCODE -ne 0) { throw "Many-author footer render failed." }

  $twoAuthorHtml = Get-Content -Raw -LiteralPath (Join-Path $smokeRoot "footer-two-authors.html")
  if ($twoAuthorHtml -notmatch '<div class="footer footer-default">\s*<p>Ada Lovelace, Grace Hopper \| Forest analysis</p>') {
    throw "Two-author footer does not contain both author names."
  }

  $manyAuthorHtml = Get-Content -Raw -LiteralPath (Join-Path $smokeRoot "footer-many-authors.html")
  if ($manyAuthorHtml -notmatch '<div class="footer footer-default">\s*<p>Lovelace et al\. \| Forest analysis</p>') {
    throw "Many-author footer does not use the first author's family name and et al."
  }
}
finally {
  Pop-Location
}

Push-Location $templateRoot
try {
  Write-Host "Creating a project from the template package in $templateRoot"
  & quarto use template $archivePath --no-prompt
  if ($LASTEXITCODE -ne 0) { throw "Template project creation failed." }

  $templateDocument = Get-ChildItem -Path $templateRoot -Filter "*.qmd" | Select-Object -First 1
  if (-not $templateDocument) { throw "Template project did not contain a Quarto document." }

  & quarto render $templateDocument.FullName
  if ($LASTEXITCODE -ne 0) { throw "Template project render failed." }

  $templateOutput = [System.IO.Path]::ChangeExtension($templateDocument.FullName, ".html")
  if (-not (Test-Path -LiteralPath $templateOutput)) {
    throw "Template project HTML was not created."
  }
}
finally {
  Pop-Location
}

Write-Host "Extension install smoke test passed: $smokeRoot\smoke.html"
Write-Host "Template creation smoke test passed: $templateOutput"
