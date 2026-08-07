# Helper functions for ENGR-3027 Process Engineering Book
# These functions provide conditional output for HTML vs PDF rendering

#' Embed a YouTube video with conditional output
#'
#' In HTML output, displays a responsive iframe embed.
#' In PDF/LaTeX output, displays a formatted link to the video.
#'
#' @param video_id The YouTube video ID (e.g., "dQw4w9WgXcQ")
#' @param title The title to display (used in PDF link text)
#' @return NULL (outputs directly via cat)
#' @examples
#' embed_youtube("dQw4w9WgXcQ", "Example Video")
embed_youtube <- function(video_id, title = "Watch Video") {
  # Clean video ID (remove any URL parts if full URL passed)
  if (grepl("youtube.com|youtu.be", video_id)) {
    # Extract video ID from URL
    video_id <- gsub(".*(?:youtube\\.com/embed/|youtube\\.com/watch\\?v=|youtu\\.be/)([^&?/]+).*", "\\1", video_id)
  }

  if (knitr::is_html_output()) {
    # HTML output - responsive iframe
    cat(sprintf('
<div style="position: relative; padding-bottom: 56.25%%; height: 0; overflow: hidden; max-width: 100%%;">
  <iframe
    style="position: absolute; top: 0; left: 0; width: 100%%; height: 100%%;"
    src="https://www.youtube.com/embed/%s"
    title="%s"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    referrerpolicy="strict-origin-when-cross-origin"
    allowfullscreen>
  </iframe>
</div>
', video_id, title))
  } else {
    # PDF/LaTeX output - formatted link
    cat(sprintf('\n\n**%s:** [https://www.youtube.com/watch?v=%s](https://www.youtube.com/watch?v=%s)\n\n',
                title, video_id, video_id))
  }
}

#' Create a styled info box with conditional output
#'
#' In HTML output, displays a colored box.
#' In PDF output, displays a simple formatted block.
#'
#' @param content The content to display
#' @param type The type of box: "info", "warning", "tip", "note"
#' @return NULL (outputs directly via cat)
info_box <- function(content, type = "info") {
  colors <- list(
    info = "#3498DB",
    warning = "#E74C3C",
    tip = "#2ECC71",
    note = "#F39C12"
  )

  icons <- list(
    info = "Info",
    warning = "Warning",
    tip = "Tip",
    note = "Note"
  )

  color <- colors[[type]]
  icon <- icons[[type]]

  if (knitr::is_html_output()) {
    cat(sprintf('
<div style="padding: 15px; margin: 10px 0; border-left: 5px solid %s; background-color: %s20;">
<strong>%s:</strong> %s
</div>
', color, color, icon, content))
  } else {
    cat(sprintf('\n\n**%s:** %s\n\n', icon, content))
  }
}
