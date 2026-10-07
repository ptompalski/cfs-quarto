# Quarto Reveal.js Presentation Theme

A reusable Quarto reveal.js theme for clear, modern research presentations.
It includes layouts for regular content, section dividers, figures, columns,
key results, and conclusions.

## Install

Create a new presentation from the template:

```bash
quarto use template <owner>/<repository>
```

Add the extension to an existing project:

```bash
quarto add <owner>/<repository>
```

## Render

```bash
quarto preview template.qmd
```

Render the template and gallery:

```bash
quarto render
```

## Layout examples

### Regular content

```markdown
## Regular content slide

Use this layout for concise explanatory text.

- First point
- Second point
- Third point
```

### Section divider

```markdown
## Section title {.section-slide .center background-color="#183F35"}

<div class="section-number">01 / Section label</div>

A short section description
```

### Two columns

```markdown
## Slide with two columns

:::: {.columns}
::: {.column width="48%"}
Content for the first column.
:::
::: {.column width="48%"}
Content for the second column.
:::
::::
```

### Full-width figure

```markdown
## Slide with a figure {.full-figure}

![Short caption.](figures/example.png){fig-alt="Description of the figure"}
```

Add `.no-footer` when the figure needs the full slide height.

### Key result

```markdown
## Key result slide {.key-result}

<div class="key-number">78%</div>

<div class="key-label">A short explanation of the result</div>

<div class="key-context">Add uncertainty or sample size here.</div>
```

### Conclusion

```markdown
## Conclusion slide {.conclusion-slide}

- Main finding
- Important supporting result
- Limitation
- Practical implication
```

## Gallery and tests

The gallery demonstrates the available layouts with synthetic data:

```bash
quarto render examples/gallery.qmd
```

Run the complete local test from PowerShell:

```powershell
./scripts/test-extension.ps1
```

The test renders the gallery, installs the packaged extension in a separate
project, and creates a new project from the template.

## License

Source code is available under the MIT License.
