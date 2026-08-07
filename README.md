# Design for Manufacturing

Source for the *Design for Manufacturing* textbook — a [Quarto](https://quarto.org)
book covering engineering drafting and tolerancing, machine elements, design
for manufacturing processes, machine learning for manufacturing, and finite
element analysis.

Rendered book: <https://prof-mv.github.io/Design-for-Manufacturing/>

## Building locally

```sh
quarto render
```

Renders the HTML, PDF, and EPUB formats to `docs/`. Requires
[Quarto](https://quarto.org/docs/get-started/) and R with the packages
listed in `R/required_packages.R`.

```sh
quarto preview
```

Live-reloading preview while editing.

## Structure

Chapters are R Markdown (`.Rmd`) files following a `PART-CHAPTER-Name.Rmd`
numbering scheme (e.g. `02-07-Belt-Pulley.Rmd` is Part II, Chapter 7). Book
structure and metadata live in `_quarto.yml`; shared R helpers live in `R/`.
