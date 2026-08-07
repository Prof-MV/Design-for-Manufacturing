# Playbook: fixing R code rendering + adding interactive cells to a Quarto book

Written from work done on the ENGR-3027 Process Engineering Quarto book
(github.com/Prof-MV/Process-Engineering). Paste this into a new chat along
with "do this to my book too" — it has everything needed to reproduce the
same fixes on a different Quarto book project.

## 0. Prerequisites: get R + Quarto installed locally

If the assistant doesn't already have R/Quarto available in its environment,
on Windows the fastest path is `winget` (already present on Windows 11):

```powershell
winget install --id RProject.R -e
winget install --id Posit.Quarto -e
```

Gotchas found on a fresh install:
- The R installer does **not** add its `bin` folder to `PATH`. Add it
  manually (adjust the version number):
  `[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\R\R-<version>\bin", "User")`
- A new terminal is needed afterwards for `PATH` changes to take effect.
- `install.packages()` fails silently-ish with "lib is not writable" if run
  non-interactively before a personal library exists. Fix:
  ```r
  # find the expected personal library path
  Rscript -e "Sys.getenv('R_LIBS_USER')"
  # create it before installing anything
  New-Item -ItemType Directory -Force -Path "<that path>"
  ```
- Install the book's R package dependencies (check the repo for a
  `required_packages.R` or similar) after the above.

## 1. The split code/output rendering bug ("chunk splitting")

**Symptom:** an R chunk with multiple `cat()`/`print()` calls (or a loop
that prints) renders as several alternating little code blocks and output
blocks instead of one code block followed by one output block. This is a
**knitr default**, not a Quarto-specific bug — it existed under
R Markdown/bookdown too, if the book was migrated from there.

**Cause:** knitr's default `results` chunk option interleaves source and
output at the statement level. Any chunk with more than one printing
statement gets fragmented.

**Fix — one line, applies to the whole book at once:**

```yaml
# _quarto.yml
knitr:
  opts_chunk:
    results: hold
```

This holds all output until the end of each chunk and renders the full
source as one block. It's global, so no per-chunk edits needed. Chunk-level
`results=` overrides (e.g. `results='asis'` on video-embed helpers) still
take precedence, so nothing else breaks.

**Gotcha — the freeze cache:** if the project uses `execute: freeze: auto`
(common for books with lots of ggplot chunks, to speed up CI), rendered
output is cached in a git-tracked `_freeze/` directory and keyed off the
`.qmd` source content — **not** `_quarto.yml`. A project-YAML-only change
like the one above will not invalidate the cache, so old (buggy) output
keeps shipping until you delete the relevant `_freeze/<chapter>/` folders
(or the whole directory) so the next render re-executes from scratch.

## 2. Missing-jQuery bug in kableExtra tables

**Symptom:** browser console shows `Uncaught ReferenceError: $ is not
defined` at `kePrint.js:1` on every page that uses `kableExtra::kable_styling()`.

**Cause:** `kable_styling()` pulls in `kePrint.js`, a tiny script that
activates Bootstrap tooltips/popovers via jQuery. Quarto's Bootstrap 5 HTML
theme dropped jQuery entirely, so the script throws immediately. It fails
silently otherwise (doesn't break the rest of the page) — impact is limited
to tooltips/popovers on tables never firing, but it's still a real bug worth
fixing since it's on every page.

**Fix:** inject the jQuery copy already bundled with the `rmarkdown` R
package (offline, no CDN) via an R helper, called once per chapter **before**
any table:

```r
# R/helpers.R (or equivalent)
inject_jquery <- function() {
  if (knitr::is_html_output()) {
    htmltools::tagList(rmarkdown::html_dependency_jquery())
  }
}
```

Then call `inject_jquery()` as the last line of each chapter's setup chunk
(the one that already does `source("R/helpers.R")` etc.). It must be a
top-level call inside the `.qmd`'s own chunk — not buried inside a
`source()`'d file — or its HTML dependency won't get picked up by knitr's
dependency-collection mechanism. `include=FALSE` on that chunk is fine;
dependency injection happens independently of visible output.

**Verify:** after rendering, check the generated HTML's `<head>` —
`jquery-*.min.js` should appear *before* `kePrint.js` (script tags execute
in document order, and kePrint.js calls `$(...)` immediately on load).

## 3. Interactive, editable code cells (webR)

The ask this came out of: "make the first example in a chapter read-only,
and the rest an interactive, editable Jupyter-like workflow."

**Only one real option for a static site (GitHub Pages, no server):**
[quarto-webr](https://github.com/coatless/quarto-webr) — runs actual R
client-side via WebAssembly. No server, no Binder/JupyterHub dependency.

### Install

If the assistant's environment can run `quarto add coatless/quarto-webr`,
do that. If not (no Quarto CLI available), vendor it by hand — this is
exactly what `quarto add` does under the hood:

```bash
git clone --depth 1 --branch <latest-tag> https://github.com/coatless/quarto-webr.git /tmp/webr-src
mkdir -p _extensions/coatless
cp -r /tmp/webr-src/_extensions/webr _extensions/coatless/webr
```

Check https://github.com/coatless/quarto-webr/tags for the latest stable
tag rather than pulling `main` (which may be a `-dev` prerelease). The
extension folder must be **committed to the repo** if CI just runs
`quarto render` without ever calling `quarto add`.

### Scope it to one chapter at a time (recommended for a first pass)

Don't flip this on book-wide in one shot. Add YAML front matter to just the
chapter(s) being converted:

```yaml
---
engine: knitr
filters:
  - webr
webr:
  show-startup-message: true
  cell-options:
    autorun: true
---
```

### The read-only-first / interactive-rest pattern

- Leave the **first** worked example in a chapter as a normal
  ` ```{r} ` chunk — untouched, unconverted. It's the fixed reference the
  student reads before touching anything themselves.
- Convert **later** examples to:
  ````
  ```{webr-r}
  #| label: some-label
  ... same R code ...
  ```
  ````
  `autorun: true` (set globally above) means output appears immediately on
  page load, not just after a manual click.
- Add a one-line cue immediately before each converted cell, e.g. *"This one
  is live — edit the numbers and re-run it."*

### Which chunks are safe to convert — check every one before converting

A `{webr-r}` cell runs in its own **isolated browser-side R session**. It
has **no access to**:
- variables/data frames created in other chunks (even earlier ones in the
  same document) — each webR page has its own environment, separate from
  knitr's per-document R session
- any package not either base R or explicitly preloaded via the page's
  `webr: packages: [...]` list (which adds real load-time latency and a
  dependency on the CRAN-like webR package mirror being available)

So before converting a chunk, read it and confirm it's **fully
self-contained**: all data it uses is created with `<-` inside that same
chunk, and it only calls base-R functions (`cat`, `sprintf`, `data.frame`,
`round`, `ceiling`, control flow, etc.). Chunks that reference a `tibble`/
`ggplot`/`dplyr` pipeline built in an earlier hidden chunk, or that need
non-base packages, are **not** safe to convert as-is — either skip them or
duplicate the needed setup code into the cell itself. In practice, "short
numeric worked-example" chunks (the ones already written in a
`cat()`/`sprintf()` style to print results) are almost always safe;
`ggplot2`-heavy visualization chunks and chunks depending on prior context
almost never are without extra rework — leave those alone.

If a chapter only has **one** visible worked-example chunk, there's nothing
to convert — leave it as the static reference, matching the pattern.

### Known limitations to flag to whoever owns the book

- **PDF/EPUB:** webR only runs in a browser. Quarto's webR filter checks
  `quarto.doc.is_format("html")` and for any other format just returns the
  code block unchanged — i.e. PDF/EPUB versions show the source code with
  **no computed output** for any converted cell. Confirmed by reading the
  filter's Lua source directly (`_extensions/.../webr.lua`), not assumed.
  This is a real content regression in those two formats for any chunk you
  convert — worth weighing before converting chunks whose output matters in
  print form.
- **Must be served over `http://`, not opened as a local file.** webR loads
  via ES module `import()` and fetches its WASM runtime — browsers block
  this under `file://`. Use `quarto preview` (starts a local dev server) to
  test, not double-clicking the rendered HTML.
- **Needs internet on first load** (per page/session) — webR's runtime and
  R packages are fetched from `webr.r-wasm.org` by default, cached by the
  browser afterward.
- Don't run `quarto preview` (which watches files and re-renders on change)
  at the same time as manual `quarto render` calls — they collide over the
  same project render lock and produce a `cannot open the connection` error
  reading the `.qmd`. Stop the preview server before doing direct renders,
  or vice versa.

## Suggested order of operations for a new book

1. Add `results: hold` to `_quarto.yml`, clear `_freeze/` for affected
   chapters, render, confirm output blocks are no longer split.
2. Add `inject_jquery()` fix if the book uses kableExtra tables at all
   (check the browser console for the `$ is not defined` error to confirm
   it's actually present before bothering).
3. Vendor/install quarto-webr.
4. Pick **one** chapter with 2+ self-contained numeric example chunks,
   convert it, render, and actually open it in a browser via
   `quarto preview` to confirm cells run and are editable before touching
   any other chapter.
5. Once approved, sweep the rest of the chapters using the same
   self-containment check per chunk.
6. Full-book render (`quarto render`, no `--to` filter, so it hits all
   configured formats) before committing, to catch anything that broke.
