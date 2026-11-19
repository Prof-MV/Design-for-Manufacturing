# weld_draw.R -----------------------------------------------------------------
# Drawing primitives for the welding chapter (03-04-Welding.qmd).
# Every function returns a list of ggplot2 layers, so figures are built as
#   ggplot() + wd_seg(...) + wsym_ref(...) + wsym_fillet(...) + ... + wd_canvas(...)
# Units are arbitrary drawing units; wd_canvas() fixes the aspect ratio 1:1.
# Welding-symbol conventions follow AWS A2.4: "arrow side" symbols sit below the
# reference line (s = -1), "other side" symbols above it (s = +1); the
# perpendicular leg of fillet, bevel, J and flare-bevel symbols is always at left.
# -----------------------------------------------------------------------------

wd_col <- list(
  line   = "black",
  weld   = "#F2B27A",   # weld metal (same orange family as the other chapter figures)
  part   = "white",
  part2  = "#E8EEF5",   # second part where two parts need telling apart
  header = "#C9DCF0",   # table header band
  note   = "#1F5FA8",   # blue leader / callout text
  dim    = "gray25"
)

wd_ts <- function(size) size * diagram_text_scale

## ---- basic marks -------------------------------------------------------------
wd_seg <- function(x, y, xend, yend, lw = 0.5, col = wd_col$line, lt = "solid") {
  list(annotate("segment", x = x, y = y, xend = xend, yend = yend,
                linewidth = lw, colour = col, linetype = lt))
}

wd_path <- function(x, y, lw = 0.5, col = wd_col$line, lt = "solid") {
  list(geom_path(data = data.frame(x = x, y = y), aes(x, y),
                 linewidth = lw, colour = col, linetype = lt, inherit.aes = FALSE))
}

wd_poly <- function(x, y, fill = wd_col$part, col = wd_col$line, lw = 0.6, lt = "solid") {
  list(geom_polygon(data = data.frame(x = x, y = y), aes(x, y),
                    fill = fill, colour = col, linewidth = lw, linetype = lt, inherit.aes = FALSE))
}

wd_text <- function(x, y, label, size = 3.2, hjust = 0.5, vjust = 0.5, col = "black",
                    face = "plain", angle = 0, lineheight = 0.9) {
  list(annotate("text", x = x, y = y, label = label, size = wd_ts(size), hjust = hjust,
                vjust = vjust, colour = col, fontface = face, angle = angle,
                lineheight = lineheight))
}

## Leader / arrow from (x, y) through optional bends to the tip (last point)
wd_arrow <- function(x, y, lw = 0.5, col = wd_col$line, len = 0.18, ends = "last") {
  list(geom_path(data = data.frame(x = x, y = y), aes(x, y), linewidth = lw, colour = col,
                 arrow = arrow(length = unit(len, "cm"), type = "closed", ends = ends),
                 inherit.aes = FALSE))
}

wd_circle <- function(x0, y0, r, fill = NA, col = wd_col$line, lw = 0.5, lt = "solid", n = 90) {
  t <- seq(0, 2 * pi, length.out = n)
  if (is.na(fill)) return(wd_path(x0 + r * cos(t), y0 + r * sin(t), lw, col, lt))
  wd_poly(x0 + r * cos(t), y0 + r * sin(t), fill = fill, col = col, lw = lw, lt = lt)
}

wd_arc <- function(x0, y0, r, a1, a2, lw = 0.5, col = wd_col$line, lt = "solid", n = 40) {
  t <- seq(a1, a2, length.out = n)
  wd_path(x0 + r * cos(t), y0 + r * sin(t), lw, col, lt)
}

## Centre line (long-short dash)
wd_cl <- function(x, y, xend, yend, col = "gray35") {
  wd_seg(x, y, xend, yend, lw = 0.35, col = col, lt = "longdash")
}

## ---- dimensions --------------------------------------------------------------
## Linear dimension between two points with arrows at both ends; label at the middle
## (or at lx, ly). Extension lines are drawn separately with wd_seg().
wd_dim <- function(x1, y1, x2, y2, label = NULL, lx = NULL, ly = NULL, size = 3,
                   col = wd_col$dim, hjust = 0.5, vjust = 0.5, len = 0.15) {
  out <- wd_arrow(c(x1, x2), c(y1, y2), lw = 0.35, col = col, len = len, ends = "both")
  if (!is.null(label)) {
    if (is.null(lx)) lx <- (x1 + x2) / 2
    if (is.null(ly)) ly <- (y1 + y2) / 2
    out <- c(out, wd_text(lx, ly, label, size = size, col = col, hjust = hjust, vjust = vjust))
  }
  out
}

## "Arrows-in" dimension for small gaps: two short arrows pointing at x1 and x2 from outside
wd_dim_in <- function(x1, x2, y, label = NULL, out = 0.4, size = 3, col = wd_col$dim,
                      vertical = FALSE, label_at = c("right", "left"), len = 0.13) {
  label_at <- match.arg(label_at)
  if (!vertical) {
    res <- c(wd_arrow(c(x1 - out, x1), c(y, y), lw = 0.35, col = col, len = len),
             wd_arrow(c(x2 + out, x2), c(y, y), lw = 0.35, col = col, len = len))
    if (!is.null(label)) {
      res <- c(res, if (label_at == "right") wd_text(x2 + out + 0.05, y, label, size = size, hjust = 0, col = col)
                    else wd_text(x1 - out - 0.05, y, label, size = size, hjust = 1, col = col))
    }
  } else {
    ## x1, x2 are y-levels, y is the x position
    res <- c(wd_arrow(c(y, y), c(x2 + out, x2), lw = 0.35, col = col, len = len),
             wd_arrow(c(y, y), c(x1 - out, x1), lw = 0.35, col = col, len = len))
    if (!is.null(label)) {
      res <- c(res, if (label_at == "right") wd_text(y + 0.08, (x1 + x2) / 2, label, size = size, hjust = 0, col = col)
                    else wd_text(y - 0.08, (x1 + x2) / 2, label, size = size, hjust = 1, col = col))
    }
  }
  res
}

## ---- parts -------------------------------------------------------------------
## Wavy break-line points between (x1, y1) and (x2, y2)
wd_break_pts <- function(x1, y1, x2, y2, amp = 0.06, n = 3) {
  t <- seq(0, 1, length.out = 12 * n + 1)
  dx <- x2 - x1; dy <- y2 - y1; L <- sqrt(dx^2 + dy^2)
  nx <- -dy / L; ny <- dx / L
  w <- amp * sin(2 * pi * n * t) * (t > 0 & t < 1)
  data.frame(x = x1 + dx * t + nx * w, y = y1 + dy * t + ny * w)
}

## Rectangle part with optional wavy break on left / right / top / bottom edges
wd_plate <- function(x0, x1, y0, y1, brk = c(), fill = wd_col$part, lw = 0.8, amp = 0.06) {
  e <- function(side, a, b) {
    if (side %in% brk) wd_break_pts(a[1], a[2], b[1], b[2], amp = amp)
    else data.frame(x = c(a[1], b[1]), y = c(a[2], b[2]))
  }
  p <- rbind(e("bottom", c(x0, y0), c(x1, y0)),
             e("right",  c(x1, y0), c(x1, y1)),
             e("top",    c(x1, y1), c(x0, y1)),
             e("left",   c(x0, y1), c(x0, y0)))
  wd_poly(p$x, p$y, fill = fill, lw = lw)
}

## Section hatching (45 deg lines) clipped to a rectangle
wd_hatch <- function(x0, x1, y0, y1, step = 0.12, dir = 1, col = "gray30", lw = 0.3) {
  w <- x1 - x0; h <- y1 - y0
  cs <- seq(-h, w, by = step)
  segs <- lapply(cs, function(c0) {
    ## line x = x0 + c0 + t, y = y0 + t (dir = 1) clipped to box
    t0 <- max(0, -c0); t1 <- min(h, w - c0)
    if (t1 <= t0) return(NULL)
    if (dir == 1) data.frame(x = x0 + c0 + t0, y = y0 + t0, xend = x0 + c0 + t1, yend = y0 + t1)
    else data.frame(x = x1 - c0 - t0, y = y0 + t0, xend = x1 - c0 - t1, yend = y0 + t1)
  })
  d <- do.call(rbind, segs)
  list(geom_segment(data = d, aes(x = x, y = y, xend = xend, yend = yend),
                    linewidth = lw, colour = col, inherit.aes = FALSE))
}

## Weld bead: polygon through the given points, smoothed with a closed spline
wd_bead <- function(x, y, fill = wd_col$weld, lw = 0.8, smooth = TRUE) {
  if (smooth && length(x) > 3) {
    s <- stats::spline(seq_along(c(x, x[1])), c(x, x[1]), n = 120, method = "periodic")
    t <- stats::spline(seq_along(c(y, y[1])), c(y, y[1]), n = 120, method = "periodic")
    x <- s$y; y <- t$y
  }
  wd_poly(x, y, fill = fill, lw = lw)
}

## ---- welding symbol: reference line, arrow, tail ------------------------------
## Reference line from x to x + len at height y. The arrow leaves from the
## `arrow_end` ("left" or "right") and runs through ax/ay (bends, then tip).
## tail: text placed in the tail at the opposite end (NULL = no tail; "" = bare tail).
wsym_ref <- function(x, y, len, ax, ay, arrow_end = "left", tail = NULL,
                     all_around = FALSE, field = FALSE, lw = 0.6, tail_size = 3,
                     tail_len = 0.3) {
  ex <- if (arrow_end == "left") x else x + len
  tx <- if (arrow_end == "left") x + len else x
  out <- c(wd_seg(x, y, x + len, y, lw = lw),
           wd_arrow(c(ex, ax), c(y, ay), lw = lw * 0.9))
  if (!is.null(tail)) {
    dir <- if (arrow_end == "left") 1 else -1
    out <- c(out,
             wd_seg(tx, y, tx + dir * tail_len, y + tail_len, lw = lw),
             wd_seg(tx, y, tx + dir * tail_len, y - tail_len, lw = lw))
    if (nzchar(tail)) out <- c(out, wd_text(tx + dir * (tail_len + 0.08), y, tail, size = tail_size,
                                           hjust = if (dir == 1) 0 else 1))
  }
  if (all_around) out <- c(out, wd_circle(ex, y, 0.16, lw = lw))
  if (field) out <- c(out, wd_seg(ex, y, ex, y + 0.5, lw = lw),
                      wd_poly(c(ex, ex, ex + 0.3 * (if (arrow_end == "left") 1 else -1)),
                              c(y + 0.5, y + 0.3, y + 0.4), fill = "black", lw = 0.3))
  out
}

## ---- basic weld symbols (x = position of the symbol's root / left leg) ---------
## s = -1 arrow side (below), +1 other side (above); h = symbol height
wsym_fillet <- function(x, y, s = -1, h = 0.35, lw = 0.6) {
  wd_path(c(x, x, x + h), c(y, y + s * h, y), lw = lw)
}
wsym_square <- function(x, y, s = -1, h = 0.35, gap = 0.12, lw = 0.6) {
  c(wd_seg(x - gap / 2, y, x - gap / 2, y + s * h, lw = lw),
    wd_seg(x + gap / 2, y, x + gap / 2, y + s * h, lw = lw))
}
wsym_v <- function(x, y, s = -1, h = 0.35, lw = 0.6) {
  wd_path(c(x - 0.75 * h, x, x + 0.75 * h), c(y + s * h, y, y + s * h), lw = lw)
}
wsym_bevel <- function(x, y, s = -1, h = 0.35, lw = 0.6) {
  c(wd_seg(x, y, x, y + s * h, lw = lw), wd_seg(x, y, x + 0.8 * h, y + s * h, lw = lw))
}
wsym_scarf <- function(x, y, s = -1, h = 0.35, gap = 0.12, lw = 0.6) {
  c(wd_seg(x - gap, y, x - gap + 0.6 * h, y + s * h, lw = lw),
    wd_seg(x + gap, y, x + gap + 0.6 * h, y + s * h, lw = lw))
}
wsym_u <- function(x, y, s = -1, h = 0.4, lw = 0.6) {
  r <- 0.32 * h; st <- 0.3 * h; yc <- y + s * (st + r)
  t <- seq(pi, 2 * pi, length.out = 30)
  c(wd_seg(x, y, x, y + s * st, lw = lw),
    wd_path(c(x - r, x + r * cos(t), x + r), c(y + s * h, yc + s * r * sin(t), y + s * h), lw = lw))
}
wsym_j <- function(x, y, s = -1, h = 0.4, lw = 0.6) {
  r <- 0.32 * h; st <- 0.3 * h; yc <- y + s * (st + r)
  t <- seq(3 * pi / 2, 2 * pi, length.out = 20)
  c(wd_seg(x, y, x, y + s * h, lw = lw),
    wd_path(c(x + r * cos(t), x + r), c(yc + s * r * sin(t), y + s * h), lw = lw))
}
wsym_flare_v <- function(x, y, s = -1, h = 0.35, gap = 0.06, lw = 0.6) {
  r <- h
  c(wd_arc(x - gap - r, y, r, 0, s * pi / 2, lw = lw),
    wd_arc(x + gap + r, y, r, pi, pi - s * pi / 2, lw = lw))
}
wsym_flare_bevel <- function(x, y, s = -1, h = 0.35, gap = 0.08, lw = 0.6) {
  r <- h
  c(wd_seg(x, y, x, y + s * h, lw = lw),
    wd_arc(x + gap + r, y, r, pi, pi - s * pi / 2, lw = lw))
}
## Back / backing weld (half circle); filled = melt-through
wsym_back <- function(x, y, s = -1, r = 0.17, lw = 0.6, filled = FALSE) {
  t <- seq(0, s * pi, length.out = 30)
  if (filled) return(wd_poly(x + r * cos(t), y + r * sin(t), fill = "black", lw = lw))
  wd_path(x + r * cos(t), y + r * sin(t), lw = lw)
}
wsym_plug <- function(x, y, s = -1, w = 0.5, h = 0.2, lw = 0.6) {
  wd_path(c(x - w / 2, x - w / 2, x + w / 2, x + w / 2), c(y, y + s * h, y + s * h, y), lw = lw)
}
wsym_spot <- function(x, y, s = 0, r = 0.17, lw = 0.6) {
  wd_circle(x, y + s * r, r, lw = lw)
}
wsym_seam <- function(x, y, s = 0, r = 0.17, lw = 0.6) {
  yc <- y + s * r
  c(wd_circle(x, yc, r, lw = lw),
    wd_seg(x - 1.5 * r, yc + 0.35 * r, x + 1.5 * r, yc + 0.35 * r, lw = lw),
    wd_seg(x - 1.5 * r, yc - 0.35 * r, x + 1.5 * r, yc - 0.35 * r, lw = lw))
}
wsym_stud <- function(x, y, r = 0.17, lw = 0.6) {
  d <- r * cos(pi / 4)
  c(wd_circle(x, y + r, r, lw = lw),
    wd_seg(x - d, y + r - d, x + d, y + r + d, lw = lw),
    wd_seg(x - d, y + r + d, x + d, y + r - d, lw = lw))
}
wsym_surfacing <- function(x, y, r = 0.15, lw = 0.6) {
  c(wsym_back(x - r, y, -1, r, lw), wsym_back(x + r, y, -1, r, lw))
}
wsym_edge_flange <- function(x, y, s = 1, h = 0.4, g = 0.07, r = 0.15, lw = 0.6) {
  c(wd_seg(x - g, y + s * r, x - g, y + s * h, lw = lw),
    wd_arc(x - g - r, y + s * r, r, 0, -s * pi / 2, lw = lw),
    wd_seg(x + g, y + s * r, x + g, y + s * h, lw = lw),
    wd_arc(x + g + r, y + s * r, r, pi, pi + s * pi / 2, lw = lw))
}
wsym_corner_flange <- function(x, y, s = 1, h = 0.4, g = 0.07, r = 0.15, lw = 0.6) {
  c(wd_seg(x - g, y, x - g, y + s * h, lw = lw),
    wd_seg(x + g, y + s * r, x + g, y + s * h, lw = lw),
    wd_arc(x + g + r, y + s * r, r, pi, pi + s * pi / 2, lw = lw))
}

## ---- supplementary symbols ---------------------------------------------------
## Contour mark over a symbol of width w centred at x, at distance d from the line
wsym_contour <- function(x, y, s = -1, type = c("flush", "convex", "concave"),
                         w = 0.35, d = 0.48, finish = NULL, lw = 0.6, size = 3) {
  type <- match.arg(type)
  yy <- y + s * d
  out <- switch(type,
    flush   = wd_seg(x - w / 2, yy, x + w / 2, yy, lw = lw),
    convex  = wd_arc(x, yy, w / 2, 0, s * pi, lw = lw),
    concave = wd_arc(x, yy + s * w / 2, w / 2, pi, pi - s * pi, lw = lw))
  if (!is.null(finish)) {
    fy <- yy + s * (if (type == "flush") 0.16 else w / 2 + 0.16)
    out <- c(out, wd_text(x, fy, finish, size = size))
  }
  out
}

## ---- tables / panels ---------------------------------------------------------
## Header band with column titles: cols = list of c(x_centre, label)
wd_header <- function(x0, x1, y0, y1, labels, xs, size = 3.2, face = "plain") {
  c(list(annotate("rect", xmin = x0, xmax = x1, ymin = y0, ymax = y1,
                  fill = wd_col$header, colour = "black", linewidth = 0.6)),
    wd_text(xs, (y0 + y1) / 2, labels, size = size, face = face))
}
wd_box <- function(x0, x1, y0, y1, lw = 0.6, fill = NA, col = "black") {
  list(annotate("rect", xmin = x0, xmax = x1, ymin = y0, ymax = y1,
                fill = fill, colour = col, linewidth = lw))
}

## Canvas: fixed aspect, no axes, white background
wd_canvas <- function(xlim, ylim, title = NULL, subtitle = NULL) {
  list(coord_fixed(ratio = 1, xlim = xlim, ylim = ylim, expand = FALSE, clip = "off"),
       labs(title = title, subtitle = subtitle),
       theme_void() +
         theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 12 * chart_text_scale),
               plot.subtitle = element_text(hjust = 0.5, size = 10 * chart_text_scale),
               plot.background = element_rect(fill = "white", colour = NA),
               plot.margin = margin(6, 6, 6, 6)))
}

## ---- arcs with arrowheads (angle dimensions) ---------------------------------
wd_arcdim <- function(x0, y0, r, a1, a2, label = NULL, lx = NULL, ly = NULL, size = 3,
                      col = wd_col$dim, ends = "both", hjust = 0.5) {
  t <- seq(a1, a2, length.out = 40)
  out <- list(geom_path(data = data.frame(x = x0 + r * cos(t), y = y0 + r * sin(t)), aes(x, y),
                        linewidth = 0.35, colour = col, inherit.aes = FALSE,
                        arrow = arrow(length = unit(0.13, "cm"), type = "closed", ends = ends)))
  if (!is.null(label)) {
    am <- (a1 + a2) / 2
    if (is.null(lx)) lx <- x0 + (r + 0.18) * cos(am)
    if (is.null(ly)) ly <- y0 + (r + 0.18) * sin(am)
    out <- c(out, wd_text(lx, ly, label, size = size, col = col, hjust = hjust))
  }
  out
}

## ---- groove-weld cross-section --------------------------------------------------
## Two plates of thickness t butting at x = cx (bottom at y0), each extending L
## from the joint, with prepared edges. pl(u) / pr(u) give how far the left /
## right edge is cut back from the root gap at height fraction u (0 = bottom,
## 1 = top). The weld fills the groove between u = from and u = to (several
## ranges can be passed as a list), melts `melt` into the plates and has a
## reinforcement cap where it reaches a surface. Dashed lines show the original
## preparation inside the weld.
wd_groove <- function(cx, y0, t = 0.6, L = 1.4, gap = 0.04,
                      pl = function(u) 0 * u, pr = function(u) 0 * u,
                      fill = list(c(0, 1)), melt = 0.05, cap = 0.08, root_cap = 0.04,
                      brk = c("left", "right"), plate_fill = wd_col$part, lw = 0.8,
                      weld_fill = wd_col$weld, show_prep = TRUE, joint_line = FALSE) {
  u <- seq(0, 1, length.out = 41)
  xl <- cx - gap / 2 - pl(u); xr <- cx + gap / 2 + pr(u); yy <- y0 + u * t
  lbrk <- wd_break_pts(cx - L, y0 + t, cx - L, y0, amp = 0.05)
  rbrk <- wd_break_pts(cx + L, y0, cx + L, y0 + t, amp = 0.05)
  if (!"left" %in% brk)  lbrk <- data.frame(x = c(cx - L, cx - L), y = c(y0 + t, y0))
  if (!"right" %in% brk) rbrk <- data.frame(x = c(cx + L, cx + L), y = c(y0, y0 + t))
  out <- c(wd_poly(c(lbrk$x, xl), c(lbrk$y, yy), fill = plate_fill, lw = lw),
           wd_poly(c(rbrk$x, rev(xr)), c(rbrk$y, rev(yy)), fill = plate_fill, lw = lw))
  if (joint_line) out <- c(out, wd_seg(cx, y0, cx, y0 + t, lw = lw))
  if (is.numeric(fill)) fill <- list(fill)
  for (f in fill) {
    k <- which(u >= f[1] - 1e-9 & u <= f[2] + 1e-9)
    ## melted boundary: prep line pushed into the plates, rounded at a buried end
    ml <- xl[k] - melt; mr <- xr[k] + melt; yk <- yy[k]
    top <- if (f[2] >= 1) {
      tt <- seq(0, 1, length.out = 21)
      data.frame(x = ml[length(k)] + (mr[length(k)] - ml[length(k)]) * tt,
                 y = y0 + t + cap * sin(pi * tt))
    } else {
      tt <- seq(0, 1, length.out = 21)
      data.frame(x = ml[length(k)] + (mr[length(k)] - ml[length(k)]) * tt,
                 y = yk[length(k)] + 0.6 * melt * sin(pi * tt))
    }
    bot <- if (f[1] <= 0) {
      tt <- seq(1, 0, length.out = 21)
      data.frame(x = ml[1] + (mr[1] - ml[1]) * tt, y = y0 - root_cap * sin(pi * tt))
    } else {
      tt <- seq(1, 0, length.out = 21)
      data.frame(x = ml[1] + (mr[1] - ml[1]) * tt, y = yk[1] - 0.6 * melt * sin(pi * tt))
    }
    out <- c(out, wd_poly(c(ml, top$x, rev(mr), bot$x), c(yk, top$y, rev(yk), bot$y),
                          fill = weld_fill, lw = lw))
    if (show_prep) out <- c(out, wd_path(xl[k], yk, lw = 0.3, lt = "dashed"),
                            wd_path(xr[k], yk, lw = 0.3, lt = "dashed"))
  }
  out
}

## Common edge preparations (return functions of u for wd_groove)
prep_bevel <- function(t, angle, rf = 0, from = 0, to = 1) {
  ## straight bevel cut over u in [from + rf/t, to], measured from the bottom
  function(u) {
    a <- from + rf / t
    ifelse(u > a & u <= to, (u - a) * t * tan(angle * pi / 180),
           ifelse(u > to, (to - a) * t * tan(angle * pi / 180), 0))
  }
}
prep_bevel_top <- function(t, angle, depth) {
  ## bevel cut from the top surface down to `depth`
  function(u) pmax(0, (u * t - (t - depth))) * tan(angle * pi / 180)
}
prep_bevel_bot <- function(t, angle, depth) {
  function(u) pmax(0, (depth - u * t)) * tan(angle * pi / 180)
}
prep_j_top <- function(t, depth, r = 0.18, angle = 15) {
  ## J (or half-U) preparation from the top: radius r at the bottom, then a flank
  function(u) {
    z <- u * t - (t - depth)            # height above the groove bottom
    ## quarter circle (horizontal at the groove bottom), then a straight flank
    circ <- ifelse(z <= 0, 0, sqrt(pmax(0, r^2 - (r - pmin(z, r))^2)))
    flank <- pmax(0, z - r) * tan(angle * pi / 180)
    circ + flank
  }
}
prep_j_bot <- function(t, depth, r = 0.18, angle = 15) {
  f <- prep_j_top(t, depth, r, angle)
  function(u) f(1 - u)
}

## ---- fillet bead in a corner ----------------------------------------------------
## Corner at (x, y). The weld runs a leg `lh` along the horizontal surface in
## direction dx (+1 right / -1 left) and `lv` up the vertical surface in
## direction dy (+1 up / -1 down). bulge > 0 convex face, < 0 concave.
wd_fillet_bead <- function(x, y, lh = 0.4, lv = lh, dx = 1, dy = 1, bulge = 0.04,
                           fill = wd_col$weld, lw = 0.8, prep = TRUE) {
  tt <- seq(0, 1, length.out = 25)
  fx <- x + dx * lh * tt; fy <- y + dy * lv * (1 - tt)
  L <- sqrt(lh^2 + lv^2)
  nx <- dx * lv / L; ny <- dy * lh / L          # outward normal of the face
  fx <- fx + nx * bulge * sin(pi * tt); fy <- fy + ny * bulge * sin(pi * tt)
  out <- wd_poly(c(x, fx), c(y, fy), fill = fill, lw = lw)
  if (prep) out <- c(out, wd_path(c(x, x + dx * lh * 0.98), c(y, y), lw = 0.3, lt = "dashed"),
                     wd_path(c(x, x), c(y, y + dy * lv * 0.98), lw = 0.3, lt = "dashed"))
  out
}

## ---- "drawing callout | interpretation" panels ---------------------------------
## Frame of width W with a header band and rows of the given heights (top to bottom).
## Returns the layers; row bottoms are wd_ci_rows(heights).
wd_ci_rows <- function(heights) rev(cumsum(rev(heights))) - heights
wd_ci_frame <- function(W, heights, labels = NULL, split = W / 2, hh = 0.5,
                        heads = c("DRAWING CALLOUT", "INTERPRETATION"), size = 3, y0 = 0) {
  H <- sum(heights); yb <- wd_ci_rows(heights) + y0
  out <- c(list(annotate("rect", xmin = 0, xmax = W, ymin = y0 + H, ymax = y0 + H + hh,
                         fill = wd_col$header, colour = "black", linewidth = 0.6)),
           wd_text(c(split / 2, (split + W) / 2), y0 + H + hh / 2, heads, size = size),
           wd_box(0, W, y0, y0 + H + hh),
           if (length(heights) > 1) wd_seg(0, yb[-length(yb)], W, yb[-length(yb)], lw = 0.4))
  if (!is.null(labels)) out <- c(out, wd_text(0.2, yb + 0.22, labels, size = size, hjust = 0))
  out
}
## Two plates butted together (drawing-callout view): outline plus joint line
wd_butt <- function(cx, y0, t = 0.4, L = 1.3, ...) {
  wd_groove(cx, y0, t = t, L = L, gap = 0, fill = list(), joint_line = TRUE, ...)
}

## ---- bent (formed) plate and flare weld helpers ----------------------------------
## Formed plate: vertical leg whose outer face is at x = xo (dir = +1: leg on the
## right, flange running left; dir = -1 mirrored), bend sitting on the surface y = yb,
## leg rising to ytop, flange ending at xf. Thickness th, outer bend radius ro.
wd_bent <- function(xo, yb, ytop, xf, th = 0.2, ro = 0.4, dir = 1, flip = FALSE,
                    fill = wd_col$part, lw = 0.8) {
  ri <- ro - th
  cxb <- xo - dir * ro; cyb <- yb + ro
  a <- seq(0, -pi / 2, length.out = 25)
  ox <- cxb + dir * ro * cos(a); oy <- cyb + ro * sin(a)
  ix <- cxb + dir * ri * cos(rev(a)); iy <- cyb + ri * sin(rev(a))
  x <- c(xo, ox, xf, xf, ix, xo - dir * th)
  y <- c(ytop, oy, yb, yb + th, iy, ytop)
  if (flip) y <- 2 * yb - y + 0   # mirror about the surface (bend at the top)
  wd_poly(x, y, fill = fill, lw = lw)
}
## Weld filling the flare between a bend of outer radius ro (centre cx0, cy0) and a
## flat surface at y = ys, on the side dir (+1 right of the centre). depth = how far
## down the flare the weld reaches (fraction of the arc), face bulge b.
wd_flare_bead <- function(cx0, cy0, ro, ys, dir = 1, reach = 0.35, up = 0.45, b = 0.04,
                          fill = wd_col$weld, lw = 0.8, down = FALSE, toe_dx = 0.18) {
  s <- if (down) -1 else 1
  ## arc from the tangent point on the surface (angle -90) towards the side
  a <- seq(-pi / 2 + reach, 0 - (pi / 2) * (1 - up), length.out = 20)
  ax <- cx0 + dir * ro * cos(a); ay <- cy0 + s * ro * sin(a)
  ## face from the top of the arc out to the toe on the surface (toe_dx beyond the arc end)
  toe <- c(ax[length(ax)] + dir * toe_dx, ys)
  tt <- seq(0, 1, length.out = 15)
  fx <- ax[length(ax)] + (toe[1] - ax[length(ax)]) * tt + dir * b * sin(pi * tt)
  fy <- ay[length(ay)] + (toe[2] - ay[length(ay)]) * tt + s * b * sin(pi * tt)
  wd_poly(c(ax[1], ax, fx, ax[1]), c(ys, ay, fy, ys), fill = fill, lw = lw)
}

## Contour mark drawn parallel to the face of a fillet symbol (wsym_fillet at x, y, s, h).
## type: "flush" straight line, "convex" bows away from the weld, "concave" bows toward it.
## finish: optional finishing letter (G, M, C ...) placed beyond the mark.
wsym_fillet_contour <- function(x, y, s = -1, h = 0.35, type = c("flush", "convex", "concave"),
                                d = 0.08, sag = 0.06, finish = NULL, size = 3, lw = 0.6) {
  type <- match.arg(type)
  t <- seq(0.15, 0.85, length.out = 25)
  arc <- 4 * ((t - 0.15) / 0.7) * (1 - (t - 0.15) / 0.7)
  off <- d + switch(type, flush = 0 * t, convex = sag * arc, concave = sag * (1 - arc))
  ## face runs from (x, y + s h) to (x + h, y); outward normal points right and away from the line
  px <- x + t * h + off / sqrt(2)
  py <- y + s * h * (1 - t) + s * off / sqrt(2)
  out <- wd_path(px, py, lw = lw)
  if (!is.null(finish)) out <- c(out, wd_text(x + 0.5 * h + (d + sag + 0.17) / sqrt(2),
                                             y + s * (0.5 * h + (d + sag + 0.17) / sqrt(2)), finish, size = size))
  out
}
