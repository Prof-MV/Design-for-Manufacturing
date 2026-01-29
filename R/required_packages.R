# ───────────────────────────────────────────────────────────────
# This chunk makes sure all required packages are installed
# ───────────────────────────────────────────────────────────────

# List of packages needed in this book/project
required_packages <- c(
  "knitr",
  "rmarkdown",
  "bookdown",
  "dplyr",
  "tidyr",
  "ggplot2",
  "kableExtra",
  "stringr",
  "gridExtra",
  "ggforce",
  # add any other packages you use in the book here
  NULL
)

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if(length(new_packages) > 0) {
  message("Installing missing packages: ", paste(new_packages, collapse = ", "))
  install.packages(new_packages, 
                   repos = "https://cloud.r-project.org",
                   quiet = TRUE)
}

# Load them all (so you don't need library() in every chapter)
suppressPackageStartupMessages({
  lapply(required_packages, library, character.only = TRUE)
})