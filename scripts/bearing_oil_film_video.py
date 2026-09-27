"""
Explainer animation: how a plain bearing (bushing) builds its hydrodynamic oil
cushion during one start-stop cycle, tracked on the Stribeck curve, with the
wear at each stage.

Output:  images/bearing-oil-film-cycle.mp4  (1920x1080, 30 fps, H.264)
         images/bearing-oil-film-cycle-poster.png

Usage:   python scripts/bearing_oil_film_video.py            # full video
         python scripts/bearing_oil_film_video.py --preview  # a few PNG frames

Needs:   pip install matplotlib numpy imageio-ffmpeg

The model is deliberately simple and illustrative (not a bearing solver):
  * bearing parameter  x = eta*N/P  (same 0-2 axis and regime limits as the
    Stribeck figure in 02-03-Bearings.qmd: boundary < 0.15 < mixed < 0.5)
  * film ratio         lambda = h_min / sigma = 6 * x^0.912  (lambda = 1 at
    x = 0.15, lambda = 3 at x = 0.5), with a first-order lag for film build-up
    at startup (starved contact) and squeeze-film at shutdown
  * eccentricity       eps = 1 - lambda * sigma / c
  * attitude angle     short-bearing (Ocvirk) tan(phi) = pi*sqrt(1-eps^2)/(4 eps)
  * pressure shape     short-bearing  p ~ eps sin(t) / (1 + eps cos(t))^3
  * asperity load share f_c(lambda) (logistic), wear rate ~ f_c * N (Archard)
"""

import os
import sys
import argparse

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle, FancyArrowPatch, Wedge, FancyBboxPatch
from matplotlib.animation import FFMpegWriter

try:
    import imageio_ffmpeg

    matplotlib.rcParams["animation.ffmpeg_path"] = imageio_ffmpeg.get_ffmpeg_exe()
except ImportError:  # fall back to ffmpeg on PATH
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_MP4 = os.path.join(ROOT, "images", "bearing-oil-film-cycle.mp4")
OUT_POSTER = os.path.join(ROOT, "images", "bearing-oil-film-cycle-poster.png")

FPS = 30
T_END = 70.0
DT = 1.0 / FPS

# ---------------------------------------------------------------- colours
C_BOUND = "#F4A38C"     # coral   (boundary)
C_MIXED = "#FFE9A3"     # yellow  (mixed)
C_HYDRO = "#B9E4B0"     # green   (hydrodynamic)
C_BOUND_TXT = "#A3261B"
C_MIXED_TXT = "#8A5A00"
C_HYDRO_TXT = "#1E6B2A"
C_BUSH = "#C9A063"
C_BUSH_EDGE = "#7A5A2B"
C_HOUSING = "#9EA3A8"
C_SHAFT = "#8C939B"
C_SHAFT_EDGE = "#3A3F45"
C_OIL = "#F6C85F"
C_OIL_DOT = "#B7791F"
C_PRESS = "#7B3FA0"
C_CURVE = "#D93025"
C_INK = "#1F2328"
C_MUTED = "#5B6470"

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 13,
    "axes.edgecolor": "#8A929C",
    "axes.labelcolor": C_INK,
    "xtick.color": C_MUTED,
    "ytick.color": C_MUTED,
})

# ---------------------------------------------------------------- model
X_B, X_M = 0.15, 0.50          # regime limits on the bearing-parameter axis
SIGMA_OVER_C = 0.4 / 6.0       # combined roughness / radial clearance
X_SCALE = 1.43                 # x = X_SCALE * eta * N   (P held constant)


def smooth(a, b, t):
    """0 -> 1 smoothstep between times a and b."""
    s = np.clip((t - a) / (b - a), 0, 1)
    return s * s * (3 - 2 * s)


def speed(t):
    """Shaft speed as a fraction of rated speed."""
    up = 0.12 * smooth(4.0, 10.0, t) + 0.33 * smooth(10.0, 17.0, t) + 0.55 * smooth(17.0, 25.0, t)
    down = 0.65 * smooth(36.0, 44.0, t) + 0.35 * smooth(44.0, 51.0, t)
    return max(up - down, 0.0)


def viscosity(t):
    """Oil viscosity factor: cold oil at start, warms while running, stays warm."""
    return 1.0 - 0.38 * smooth(20.0, 34.0, t)


def mu_of_x(x):
    """Stribeck curve: boundary plateau, steep mixed drop, slow viscous rise."""
    return 0.004 + 0.004 * x + 0.126 / (1 + np.exp((x - 0.18) / 0.05))


def lam_of_x(x):
    return 6.0 * np.power(np.maximum(x, 0), 0.912)


def x_of_lam(lam):
    return np.power(np.maximum(lam, 0) / 6.0, 1 / 0.912)


def contact_share(lam):
    """Fraction of the load carried by asperity contact."""
    return 1.0 / (1.0 + np.exp((lam - 1.6) / 0.25))


def regime(lam):
    if lam < 1.0:
        return "boundary"
    if lam < 3.0:
        return "mixed"
    return "hydro"


def simulate():
    t = np.arange(0, T_END + DT / 2, DT)
    n = len(t)
    N = np.array([speed(ti) for ti in t])
    eta = np.array([viscosity(ti) for ti in t])
    lam_ss = lam_of_x(X_SCALE * eta * N)

    lam = np.zeros(n)
    lam[0] = 0.12                     # drained contact at rest
    for i in range(1, n):
        target = max(lam_ss[i], 0.12)
        tau = 1.4 if target > lam[i - 1] else 0.5   # film build-up / squeeze-film lag
        lam[i] = lam[i - 1] + (target - lam[i - 1]) * DT / tau

    x = x_of_lam(lam)
    mu = mu_of_x(x)
    fc = contact_share(lam)
    fc[N < 1e-4] = fc[N < 1e-4]       # contact stays; wear needs sliding (below)
    eps = np.clip(1 - lam * SIGMA_OVER_C, 0.0, 0.995)

    # attitude angle: short-bearing value when floating; friction "roll-up"
    # against the rotation while asperities carry the load
    phi_h = np.arctan2(np.pi * np.sqrt(1 - eps ** 2), 4 * eps)
    phi_f = -np.arctan(mu) * np.minimum(N / 0.02, 1.0)
    phi = (1 - fc) * phi_h + fc * phi_f

    wear_rate = fc * N                # Archard: contact load x sliding speed
    wear = np.concatenate([[0], np.cumsum(wear_rate[1:] * DT)])

    # rotation angle of the shaft (visual speed: 0.9 rev/s at rated speed)
    rot = np.concatenate([[0], np.cumsum(2 * np.pi * 0.9 * N[1:] * DT)])

    return dict(t=t, N=N, eta=eta, lam=lam, x=x, mu=mu, fc=fc, eps=eps,
                phi=phi, wear_rate=wear_rate, wear=wear, rot=rot)


S = simulate()
t_arr = S["t"]


def first_time(cond, after=0.0):
    idx = np.where(cond & (t_arr >= after))[0]
    return float(t_arr[idx[0]]) if len(idx) else None


T_MIX_UP = first_time(S["lam"] >= 1.0)
T_LIFT = first_time(S["lam"] >= 3.0)
T_SETTLED = T_LIFT + 3.0
T_COAST = 36.0
T_TOUCH = first_time(S["lam"] < 3.0, after=T_COAST)
T_BOUND_DN = first_time(S["lam"] < 1.0, after=T_COAST)
T_STOP = first_time(S["N"] <= 0.0, after=T_COAST)
T_SUMMARY = 59.5

# wear split for the summary card
_w = S["wear"]
W_TOTAL = _w[-1]
W_UP = np.interp(T_LIFT, t_arr, _w)
W_RUN = np.interp(T_TOUCH, t_arr, _w) - W_UP
W_DOWN = W_TOTAL - W_UP - W_RUN
PCT_UP, PCT_RUN, PCT_DOWN = (100 * v / W_TOTAL for v in (W_UP, W_RUN, W_DOWN))

N_LIFT = np.interp(T_LIFT, t_arr, S["N"])
N_TOUCH = np.interp(T_TOUCH, t_arr, S["N"])

# ---------------------------------------------------------------- captions
# (start time, title, body, wear line, colour)
CAPTIONS = [
    (0.0, "1 · At rest",
     "The load W presses the shaft onto the bottom of the bushing. The oil has been squeezed\n"
     "out of the contact zone, leaving only a molecule-thin boundary layer of additives.",
     "Wear: none yet (nothing is sliding), but the metal surfaces are touching.", C_BOUND_TXT),
    (4.0, "2 · Startup: boundary lubrication",
     "The shaft starts turning while it still rests on its asperities (microscopic peaks).\n"
     "Friction is high (μ ≈ 0.1), so the shaft briefly rolls a little way up the bore wall.",
     "Wear: HIGHEST per revolution. Asperities weld and shear (adhesive wear) and debris\n"
     "scratches the softer bushing (abrasive wear).", C_BOUND_TXT),
    (T_MIX_UP, "3 · Mixed lubrication: the wedge forms",
     "Rotation drags oil into the converging gap. Pressure builds and carries part of the load;\n"
     "the asperity contacts carry the rest. Friction falls steeply down the Stribeck curve.",
     "Wear: moderate and falling fast, with fewer and lighter contacts each revolution.", C_MIXED_TXT),
    (T_LIFT, "4 · Liftoff",
     "The minimum film thickness grows past ~3× the combined surface roughness (λ = h_min/σ > 3).\n"
     "The last contacts disappear. The shaft now floats on its self-generated oil cushion.",
     f"Wear: drops to essentially zero. Liftoff happened at ≈ {N_LIFT*100:.0f} % of rated speed (cold oil).",
     C_HYDRO_TXT),
    (T_SETTLED, "5 · Full hydrodynamic film",
     "The shaft centre sits off to the side of the load line (ε ≈ 0.45–0.65). The pressure peak just\n"
     "upstream of h_min carries the whole load. As the oil warms, viscosity η drops and the film thins.",
     "Wear: ≈ 0. Only dirt particles larger than h_min can do damage. Friction (μ ≈ 0.008)\n"
     "is now just the oil being sheared.", C_HYDRO_TXT),
    (T_COAST, "6 · Shutdown: coasting down",
     "As speed falls, ηN/P falls and the marker walks back left along the curve. The shaft sinks\n"
     "toward the bottom. Squeeze-film action (oil can't escape the gap instantly) delays touchdown.",
     "Wear: still ≈ 0 while λ > 3.", C_HYDRO_TXT),
    (T_TOUCH, "7 · Touchdown: mixed, then boundary",
     f"The oil is now warm and thin, so the film collapses at ≈ {N_TOUCH*100:.0f} % speed, higher than the\n"
     f"≈ {N_LIFT*100:.0f} % liftoff speed. Asperities touch again while the shaft is still turning.",
     "Wear: rises again as contacts return, and stays high until the shaft stops.", C_MIXED_TXT),
    (T_STOP, "8 · Stopped",
     "The load slowly squeezes the remaining oil out of the contact zone.\n"
     "The next start will begin in boundary lubrication again.",
     "Wear: none while stationary.", C_BOUND_TXT),
    (T_SUMMARY, "Takeaway",
     f"In this cycle, startup caused {PCT_UP:.0f} % of the wear, shutdown {PCT_DOWN:.0f} %, and full-speed running ≈ {PCT_RUN:.0f} %.\n"
     "Plain bearings wear out by the number of starts and stops, not by running hours.",
     "Frequent-start designs need hard-wearing bushing materials, anti-wear additives,\n"
     "or hydrostatic jacking (pumped oil lifts the shaft before it turns).", C_INK),
]


def caption_at(t):
    cur = CAPTIONS[0]
    for c in CAPTIONS:
        if t >= c[0]:
            cur = c
    return cur


# ---------------------------------------------------------------- figure
W_PX, H_PX, DPI = 1920, 1080, 100
fig = plt.figure(figsize=(W_PX / DPI, H_PX / DPI), dpi=DPI, facecolor="white")

# header
fig.text(0.03, 0.955, "How a plain bearing builds its oil cushion: one start–stop cycle",
         fontsize=26, fontweight="bold", color=C_INK, va="center")
fig.text(0.03, 0.918, "Hydrodynamic lubrication of a bushing, tracked on the Stribeck curve",
         fontsize=15, color=C_MUTED, va="center")

# cycle timeline strip
ax_tl = fig.add_axes([0.03, 0.865, 0.94, 0.028])
# main bearing view
ax_main = fig.add_axes([0.01, 0.235, 0.46, 0.615])
# journal-centre locus inset
ax_loc = fig.add_axes([0.365, 0.665, 0.105, 0.16])
# Stribeck curve
ax_str = fig.add_axes([0.53, 0.53, 0.44, 0.29])
# asperity zoom
ax_asp = fig.add_axes([0.53, 0.235, 0.21, 0.225])
# cumulative wear
ax_wear = fig.add_axes([0.785, 0.235, 0.185, 0.225])
# caption band
ax_cap = fig.add_axes([0.0, 0.0, 1.0, 0.185])


def regime_color(lam):
    return {"boundary": C_BOUND, "mixed": C_MIXED, "hydro": C_HYDRO}[regime(lam)]


# ---- timeline strip (static background)
ax_tl.set_xlim(0, T_SUMMARY)
ax_tl.set_ylim(0, 1)
ax_tl.axis("off")
seg_start = 0.0
prev = regime(S["lam"][0]) if S["N"][0] > 0 else "rest"
for i, ti in enumerate(t_arr):
    if ti > T_SUMMARY:
        break
    r = regime(S["lam"][i]) if S["N"][i] > 1e-4 else "rest"
    if r != prev or ti >= T_SUMMARY - DT:
        col = {"rest": "#D5D9DE", "boundary": C_BOUND, "mixed": C_MIXED, "hydro": C_HYDRO}[prev]
        ax_tl.add_patch(Rectangle((seg_start, 0), ti - seg_start, 1, color=col, lw=0))
        seg_start, prev = ti, r
for tl_t, tl_lab in [(2.0, "rest"), ((4 + T_MIX_UP) / 2, "start"), ((T_MIX_UP + T_LIFT) / 2, "mixed"),
                     ((T_LIFT + T_COAST) / 2, "running: floating on oil"),
                     ((T_COAST + T_TOUCH) / 2, "coast-down"), ((T_TOUCH + T_BOUND_DN) / 2, "mixed"),
                     ((T_BOUND_DN + T_STOP) / 2, "stop"), ((T_STOP + T_SUMMARY) / 2, "rest")]:
    ax_tl.text(tl_t, 0.5, tl_lab, ha="center", va="center", fontsize=11, color=C_INK)
tl_head = ax_tl.axvline(0, color=C_INK, lw=3)

# ---- Stribeck (static)
xs = np.linspace(0, 2.0, 400)
ax_str.axvspan(0, X_B, color=C_BOUND, alpha=0.55, lw=0)
ax_str.axvspan(X_B, X_M, color=C_MIXED, alpha=0.75, lw=0)
ax_str.axvspan(X_M, 2.0, color=C_HYDRO, alpha=0.55, lw=0)
ax_str.plot(xs, mu_of_x(xs), color=C_CURVE, lw=3, zorder=3)
for xv in (X_B, X_M):
    ax_str.axvline(xv, color="#6B7280", ls="--", lw=1)
ax_str.text(X_B / 2, 0.148, "BOUNDARY", ha="center", fontsize=11, fontweight="bold", color=C_BOUND_TXT)
ax_str.text((X_B + X_M) / 2, 0.148, "MIXED", ha="center", fontsize=11, fontweight="bold", color=C_MIXED_TXT)
ax_str.text(1.25, 0.148, "HYDRODYNAMIC (full film)", ha="center", fontsize=11, fontweight="bold",
            color=C_HYDRO_TXT)
ax_str.text(X_B / 2, 0.035, "metal-to-\nmetal", ha="center", fontsize=10, color=C_MUTED)
ax_str.text((X_B + X_M) / 2, 0.122, "partial film\n+ asperities", ha="center", fontsize=10, color=C_MUTED)
ax_str.text(1.75, 0.03, "no contact:\nfriction = oil shear", ha="center", fontsize=10, color=C_MUTED)
ax_str.set_xlim(0, 2.0)
ax_str.set_ylim(0, 0.162)
ax_str.set_xlabel("Bearing parameter  ηN/P   (viscosity × speed / pressure)", fontsize=13)
ax_str.set_ylabel("Friction coefficient μ", fontsize=13)
ax_str.set_title("Where are we on the Stribeck curve?", fontsize=16, fontweight="bold", loc="left",
                 color=C_INK)
for sp in ("top", "right"):
    ax_str.spines[sp].set_visible(False)

# ---- locus inset (static)
ax_loc.set_xlim(-1.25, 1.25)
ax_loc.set_ylim(-1.25, 1.25)
ax_loc.set_aspect("equal")
ax_loc.axis("off")
ax_loc.add_patch(Circle((0, 0), 1.0, fill=False, ec=C_BUSH_EDGE, lw=1.5, ls="-"))
ax_loc.add_patch(Circle((0, 0), 1.0, fc="#FFF8E6", ec="none", zorder=0))
ax_loc.plot([0], [0], marker="+", color=C_MUTED, ms=8)
ax_loc.plot([0, 0], [0.55, 0.15], color="#8B1E1E", lw=0)
ax_loc.set_title("shaft-centre path\n(within clearance c)", fontsize=10, color=C_MUTED, pad=2)

# ---- asperity zoom (static setup)
rng = np.random.default_rng(7)
L_PROF = 1200


def rough_profile(seed):
    r = np.random.default_rng(seed).normal(size=L_PROF)
    k = np.exp(-0.5 * (np.arange(-12, 13) / 3.2) ** 2)
    z = np.convolve(np.concatenate([r[-12:], r, r[:12]]), k / k.sum(), mode="valid")
    z = z[:L_PROF]
    return (z - z.mean()) / z.std() / np.sqrt(2)     # each surface sigma = 1/sqrt(2)


Z_BUSH = rough_profile(11)
Z_SHAFT = rough_profile(23)
ASP_WIN = 160                     # samples in view
ASP_X = np.arange(ASP_WIN)
ASP_YMAX = 8.4
ax_asp.set_xlim(0, ASP_WIN - 1)
ax_asp.set_ylim(-2.6, ASP_YMAX)
ax_asp.set_xticks([])
ax_asp.set_yticks([])
ax_asp.set_title("Zoom on the thinnest point (h_min)", fontsize=13, fontweight="bold", loc="left",
                 color=C_INK)
ax_asp.set_facecolor("white")

# ---- wear axis (static)
ax_wear.set_xlim(0, T_SUMMARY)
ax_wear.set_ylim(0, 1.08)
ax_wear.set_title("Cumulative wear", fontsize=13, fontweight="bold", loc="left", color=C_INK)
ax_wear.set_xlabel("time in cycle", fontsize=11)
ax_wear.set_ylabel("relative wear depth", fontsize=11)
ax_wear.set_xticks([])
ax_wear.set_yticks([0, 0.5, 1.0])
ax_wear.set_yticklabels(["0", "50 %", "100 %"], fontsize=10)
for sp in ("top", "right"):
    ax_wear.spines[sp].set_visible(False)
seg_start = 0.0
prev = regime(S["lam"][0]) if S["N"][0] > 0 else "rest"
for i, ti in enumerate(t_arr):
    if ti > T_SUMMARY:
        break
    r = regime(S["lam"][i]) if S["N"][i] > 1e-4 else "rest"
    if r != prev or ti >= T_SUMMARY - DT:
        col = {"rest": "#EEF0F2", "boundary": C_BOUND, "mixed": C_MIXED, "hydro": C_HYDRO}[prev]
        ax_wear.axvspan(seg_start, ti, color=col, alpha=0.45, lw=0)
        seg_start, prev = ti, r
wear_norm = S["wear"] / W_TOTAL

# ---- main bearing view (static)
R_BORE, R_BUSH, R_HOUS = 1.0, 1.20, 1.30
CLR = 0.13                         # drawn radial clearance (hugely exaggerated)
R_SHAFT = R_BORE - CLR
ax_main.set_xlim(-1.95, 1.95)
ax_main.set_ylim(-1.95, 1.72)
ax_main.set_aspect("equal")
ax_main.axis("off")
ax_main.add_patch(Circle((0, 0), R_HOUS, fc=C_HOUSING, ec="#6B7076", lw=1.5, zorder=1))
ax_main.add_patch(Circle((0, 0), R_BUSH, fc=C_BUSH, ec=C_BUSH_EDGE, lw=1.5, zorder=2))
ax_main.add_patch(Circle((0, 0), R_BORE, fc=C_OIL, ec=C_BUSH_EDGE, lw=1.5, zorder=3))
ax_main.plot([0], [0], marker="+", color=C_BUSH_EDGE, ms=14, mew=2, zorder=9)
for lab, xy, xyt, col in [("housing", (-0.88, 0.88), (-1.55, 1.30), "#4B5058"),
                          ("bushing", (-1.03, 0.40), (-1.75, 0.75), C_BUSH_EDGE),
                          ("oil film", (-0.94, 0.12), (-1.80, 0.20), C_OIL_DOT)]:
    ax_main.annotate(lab, xy=xy, xytext=xyt, fontsize=12, color=col, ha="center", va="bottom",
                     fontweight="bold", zorder=12,
                     arrowprops=dict(arrowstyle="-", color=col, lw=1.2, shrinkA=0, shrinkB=0))
ax_main.text(-1.93, -1.93, "clearance exaggerated ≈ 100×", fontsize=11, color=C_MUTED, ha="left",
             va="bottom", style="italic")

# oil particles in the gap
N_DOTS = 170
dot_alpha = rng.uniform(0, 2 * np.pi, N_DOTS)
dot_u = rng.uniform(0.12, 0.88, N_DOTS)

dyn = []   # artists recreated every frame


def add(a):
    dyn.append(a)
    return a


cap_bg = FancyBboxPatch((0.015, 0.06), 0.97, 0.88, boxstyle="round,pad=0.0,rounding_size=0.02",
                        transform=ax_cap.transAxes, fc="#F6F7F9", ec="#D0D5DB", lw=1.2)
ax_cap.add_patch(cap_bg)
ax_cap.set_xlim(0, 1)
ax_cap.set_ylim(0, 1)
ax_cap.axis("off")
cap_title = ax_cap.text(0.03, 0.835, "", fontsize=20, fontweight="bold", va="center")
cap_body = ax_cap.text(0.03, 0.555, "", fontsize=15, va="center", color=C_INK, linespacing=1.35)
cap_wear = ax_cap.text(0.03, 0.225, "", fontsize=14, va="center", color=C_INK, linespacing=1.3,
                       fontweight="bold")

# live readout strip under the bearing view
readout = fig.text(0.03, 0.212, "", fontsize=14, family="DejaVu Sans Mono", va="center", color=C_INK)
state_badge = fig.text(0.24, 0.835, "", fontsize=15, fontweight="bold", va="center", ha="center")
cap_bar = Rectangle((0.018, 0.12), 0.006, 0.76, transform=ax_cap.transAxes, color=C_INK, lw=0)
ax_cap.add_patch(cap_bar)


def draw_frame(i):
    for a in dyn:
        a.remove()
    dyn.clear()

    t = t_arr[i]
    N, lam, x, mu = S["N"][i], S["lam"][i], S["x"][i], S["mu"][i]
    fc, eps, phi, rot = S["fc"][i], S["eps"][i], S["phi"][i], S["rot"][i]
    reg = regime(lam)
    moving = N > 1e-4
    summary = t >= T_SUMMARY

    # ---------------- timeline playhead
    tl_head.set_xdata([min(t, T_SUMMARY)] * 2)

    # ---------------- main view
    e = eps * CLR
    ae = -np.pi / 2 + phi                          # direction of shaft-centre offset
    cx, cy = e * np.cos(ae), e * np.sin(ae)

    # pressure distribution (short-bearing shape), drawn outside the bushing
    share = 1 - fc
    if share > 0.02 and moving:
        e_p = min(eps, 0.9)
        th = np.linspace(0, np.pi, 180)                # 0 = h_max, pi = h_min
        p = e_p * np.sin(th) / (1 + e_p * np.cos(th)) ** 3
        alpha = ae - np.pi + th                        # bore angle; CCW rotation
        fy = np.sum(p * np.sin(alpha)) * (th[1] - th[0])
        fx = np.sum(p * np.cos(alpha)) * (th[1] - th[0])
        p = p / max(np.hypot(fx, fy), 1e-9) * share
        L = np.minimum(0.17 * p, 0.40)
        ro = R_HOUS + 0.02 + L
        px = np.concatenate([(R_HOUS + 0.02) * np.cos(alpha), (ro * np.cos(alpha))[::-1]])
        py = np.concatenate([(R_HOUS + 0.02) * np.sin(alpha), (ro * np.sin(alpha))[::-1]])
        add(ax_main.fill(px, py, color=C_PRESS, alpha=0.30, lw=0, zorder=4)[0])
        add(ax_main.plot(ro * np.cos(alpha), ro * np.sin(alpha), color=C_PRESS, lw=2, zorder=4)[0])
        k = np.argmax(L)
        for j in range(8, 180, 16):
            r0, r1 = R_HOUS + 0.02 + L[j], R_HOUS + 0.04
            if L[j] > 0.05:
                add(ax_main.annotate("", xy=(r1 * np.cos(alpha[j]), r1 * np.sin(alpha[j])),
                                     xytext=(r0 * np.cos(alpha[j]), r0 * np.sin(alpha[j])),
                                     arrowprops=dict(arrowstyle="-|>", color=C_PRESS, lw=1.2,
                                                     mutation_scale=10), zorder=4))
        lx, ly = (ro[k] + 0.12) * np.cos(alpha[k]), (ro[k] + 0.12) * np.sin(alpha[k])
        add(ax_main.text(lx, ly, "oil-film\npressure", fontsize=11, color=C_PRESS,
                         ha="center", va="center", fontweight="bold", zorder=5))

    # oil particles (Couette-like drag, faster near the shaft)
    ang = dot_alpha + rot * (R_SHAFT / R_BORE) * dot_u * 0.55
    h = CLR - e * np.cos(ang - ae)
    rr = R_BORE - dot_u * h
    add(ax_main.scatter(rr * np.cos(ang), rr * np.sin(ang), s=6, color=C_OIL_DOT, zorder=5, lw=0))

    # shaft
    add(ax_main.add_patch(Circle((cx, cy), R_SHAFT, fc=C_SHAFT, ec=C_SHAFT_EDGE, lw=2, zorder=6)))
    for k in range(6):
        a = rot + k * np.pi / 3
        add(ax_main.plot([cx + 0.18 * np.cos(a), cx + 0.80 * np.cos(a)],
                         [cy + 0.18 * np.sin(a), cy + 0.80 * np.sin(a)],
                         color="#A9AFB6", lw=2.5, zorder=7, solid_capstyle="round")[0])
    add(ax_main.add_patch(Circle((cx + 0.70 * np.cos(rot), cy + 0.70 * np.sin(rot)), 0.06,
                                 fc="#E0B400", ec=C_SHAFT_EDGE, lw=1, zorder=8)))
    add(ax_main.add_patch(Circle((cx, cy), 0.14, fc="#6E757D", ec=C_SHAFT_EDGE, lw=1, zorder=8)))
    add(ax_main.plot([cx], [cy], marker="+", color="white", ms=10, mew=2, zorder=9)[0])

    # load arrow
    add(ax_main.annotate("", xy=(cx, cy - 0.20), xytext=(cx, cy + 0.62),
                         arrowprops=dict(arrowstyle="-|>", color="#9B1C1C", lw=4, mutation_scale=26),
                         zorder=10))
    add(ax_main.text(cx + 0.07, cy + 0.50, "W", fontsize=18, fontweight="bold", color="#9B1C1C",
                     zorder=10))

    # rotation arrow
    if moving:
        a0 = 0.35 * np.pi
        arc = np.linspace(a0, a0 + 0.55 * np.pi, 40)
        ra = R_SHAFT + 0.34
        add(ax_main.plot(cx + ra * np.cos(arc[:-3]), cy + ra * np.sin(arc[:-3]), color=C_INK, lw=0,
                         zorder=10)[0])
        add(ax_main.annotate("", xy=(cx + ra * np.cos(arc[-1]), cy + ra * np.sin(arc[-1])),
                             xytext=(cx + ra * np.cos(arc[0]), cy + ra * np.sin(arc[0])),
                             arrowprops=dict(arrowstyle="-|>", color=C_INK, lw=2.5, mutation_scale=20,
                                             connectionstyle="arc3,rad=0.45"), zorder=10))
        add(ax_main.text(cx + (ra + 0.13) * np.cos(a0 + 0.3 * np.pi),
                         cy + (ra + 0.13) * np.sin(a0 + 0.3 * np.pi), "ω",
                         fontsize=18, fontweight="bold", color=C_INK, zorder=10, ha="center"))

    # h_min marker and contact sparks
    hx, hy = R_BORE * np.cos(ae), R_BORE * np.sin(ae)
    if fc > 0.25 and moving:
        glow = min(1.0, fc) * (0.6 + 0.4 * np.sin(t * 25))
        add(ax_main.scatter([hx], [hy], s=900 * glow, color="#FF3B1F", alpha=0.35, zorder=11, lw=0))
        add(ax_main.scatter([hx], [hy], s=160 * glow, color="#FFD23F", alpha=0.9, zorder=11, lw=0))
        for k in range(4):
            aa = ae + rng.uniform(-0.6, 0.6)
            ll = rng.uniform(0.08, 0.22) * fc
            add(ax_main.plot([hx, hx + ll * np.cos(aa + 0.6)], [hy, hy + ll * np.sin(aa + 0.6)],
                             color="#FF7A00", lw=1.5, zorder=11)[0])
    lab_r = R_BORE + 0.02
    add(ax_main.annotate("h_min", xy=(hx * 0.99, hy * 0.99),
                         xytext=(1.72 * np.cos(ae + 0.9), 1.72 * np.sin(ae + 0.9)),
                         fontsize=12, color="#B42318", fontweight="bold", ha="center",
                         arrowprops=dict(arrowstyle="-", color="#B42318", lw=1.2), zorder=12))

    # readout strip
    state_txt = {"boundary": "BOUNDARY", "mixed": "MIXED", "hydro": "HYDRODYNAMIC"}[reg]
    if not moving:
        state_txt = "STATIONARY"
    eta = S["eta"][i]
    oil = "cold" if eta > 0.95 else ("warming" if eta > 0.64 else "warm")
    mu_txt = f"{mu:.3f}" if moving else "  –  "
    readout.set_text(f"speed {N * 100:3.0f} %  ·  η {eta:.2f}× ({oil})  ·  λ {lam:4.1f}  ·  "
                     f"ε {eps:.2f}  ·  μ {mu_txt}")
    state_badge.set_text(state_txt)
    state_badge.set_color("white" if (reg != "mixed" or not moving) else C_INK)
    state_badge.set_bbox(dict(boxstyle="round,pad=0.35", ec="none",
                              fc={"boundary": "#C0392B", "mixed": "#F2C94C", "hydro": "#2E8B3E"}[reg]
                              if moving else "#6B7280"))

    # ---------------- locus inset
    sl = slice(0, i + 1)
    ex = S["eps"][sl] * np.cos(-np.pi / 2 + S["phi"][sl])
    ey = S["eps"][sl] * np.sin(-np.pi / 2 + S["phi"][sl])
    add(ax_loc.plot(ex, ey, color="#2563EB", lw=1.6, alpha=0.8)[0])
    add(ax_loc.plot([eps * np.cos(ae)], [eps * np.sin(ae)], "o", color="#1D4ED8", ms=7, mec="white")[0])

    # ---------------- Stribeck marker
    trail_start = max(0, i - 4 * FPS)
    tr = slice(trail_start, i + 1)
    add(ax_str.plot(S["x"][tr], S["mu"][tr], color="#1D4ED8", lw=4, alpha=0.35, zorder=4,
                    solid_capstyle="round")[0])
    if summary:
        add(ax_str.plot(S["x"][:i + 1], S["mu"][:i + 1], color="#1D4ED8", lw=2, alpha=0.5, zorder=4)[0])
    add(ax_str.plot([x], [mu], "o", ms=16, color="#1D4ED8" if moving else "white",
                    mec="#1D4ED8", mew=3, zorder=6)[0])
    if moving and not summary:
        direction = "→ speeding up" if S["N"][i] >= S["N"][max(i - 1, 0)] and t < T_COAST else "← slowing down"
        add(ax_str.annotate(f"you are here\n{direction}", xy=(x, mu),
                            xytext=(x + 0.12 if x < 1.5 else x - 0.12,
                                    mu - 0.035 if mu > 0.08 else mu + 0.045),
                            fontsize=11, color="#1D4ED8", fontweight="bold",
                            ha="left" if x < 1.5 else "right",
                            arrowprops=dict(arrowstyle="-", color="#1D4ED8", lw=1.2), zorder=6))
    if summary:
        add(ax_str.text(1.0, 0.105, f"liftoff ≈ {N_LIFT*100:.0f} % speed (cold oil)\n"
                                    f"touchdown ≈ {N_TOUCH*100:.0f} % speed (warm oil)",
                        fontsize=11, color="#1D4ED8", ha="left", va="center",
                        bbox=dict(boxstyle="round,pad=0.35", fc="white", ec="#1D4ED8", lw=1)))

    # ---------------- asperity zoom
    shift = int(rot / (2 * np.pi) * 280) % L_PROF
    zb = Z_BUSH[:ASP_WIN]
    zs = np.take(Z_SHAFT, (ASP_X + shift) % L_PROF)
    gap = min(lam, 5.6)
    ys = gap + zs
    top = np.full_like(ys, ASP_YMAX)
    add(ax_asp.fill_between(ASP_X, -2.6, zb, color=C_BUSH, lw=0, zorder=2))
    add(ax_asp.plot(ASP_X, zb, color=C_BUSH_EDGE, lw=1.2, zorder=3)[0])
    add(ax_asp.fill_between(ASP_X, zb, ys, where=ys > zb, color=C_OIL, alpha=0.85, lw=0, zorder=1,
                            interpolate=True))
    add(ax_asp.fill_between(ASP_X, ys, top, color=C_SHAFT, lw=0, zorder=2))
    add(ax_asp.plot(ASP_X, ys, color=C_SHAFT_EDGE, lw=1.2, zorder=3)[0])
    overlap = ys < zb
    if overlap.any():
        add(ax_asp.fill_between(ASP_X, ys, zb, where=overlap, color="#FF2D1A", lw=0, zorder=4,
                                interpolate=True))
    n_contacts = int(np.sum(np.diff(overlap.astype(int)) == 1) + (1 if overlap[0] else 0))
    add(ax_asp.text(3, ASP_YMAX - 0.35, "shaft (moving →)" if moving else "shaft", fontsize=11,
                    color="white", va="top", fontweight="bold", zorder=5))
    add(ax_asp.text(3, -2.3, "bushing (fixed)", fontsize=11, color="#4A3313", va="bottom",
                    fontweight="bold", zorder=5))
    info = f"film/roughness λ = {lam:.1f}  ·  contacts in view: {n_contacts}"
    if lam > 5.6:
        info = f"λ = {lam:.1f} (gap drawn shortened)  ·  contacts: 0"
    ax_asp.set_xlabel(info, fontsize=11, color="#B42318" if n_contacts else C_INK)
    # debris flecks while in contact
    if fc > 0.3 and moving:
        for _ in range(int(6 * fc)):
            xd = rng.uniform(0, ASP_WIN)
            yd = rng.uniform(zb[int(xd)] + 0.1, max(zb[int(xd)] + 0.2, ys[int(xd)] - 0.1))
            add(ax_asp.plot([xd], [yd], "s", ms=3, color="#5A3E1B", zorder=5)[0])

    # ---------------- wear
    ts = t_arr[:i + 1]
    add(ax_wear.plot(np.minimum(ts, T_SUMMARY), wear_norm[:i + 1], color="#B42318", lw=3, zorder=3)[0])
    rate = S["wear_rate"][i]
    lvl = "HIGH" if rate > 0.035 else ("moderate" if rate > 0.006 else ("low" if rate > 0.0005 else "≈ 0"))
    if not moving:
        lvl = "0 (not sliding)"
    ax_wear.set_xlabel(f"wear rate now: {lvl}", fontsize=12, fontweight="bold",
                       color="#B42318" if lvl in ("HIGH", "moderate") else C_INK)
    if t >= T_LIFT:
        yl = np.interp(T_LIFT, t_arr, wear_norm)
        add(ax_wear.annotate(f"startup\n{PCT_UP:.0f} %", xy=(T_LIFT, yl), xytext=(T_LIFT + 3, yl - 0.35),
                             fontsize=10, color=C_INK, arrowprops=dict(arrowstyle="-", lw=0.8)))
    if t >= T_TOUCH:
        add(ax_wear.text(0.5 * (T_LIFT + T_TOUCH), np.interp(T_TOUCH, t_arr, wear_norm) + 0.06,
                         f"running ≈ {PCT_RUN:.0f} %", fontsize=10, ha="center", color=C_HYDRO_TXT))
    if t >= T_STOP:
        add(ax_wear.annotate(f"shutdown\n{PCT_DOWN:.0f} %", xy=(T_STOP, 1.0), xytext=(T_STOP - 11, 0.80),
                             fontsize=10, color=C_INK, arrowprops=dict(arrowstyle="-", lw=0.8)))

    # ---------------- caption (with a short fade-in)
    c = caption_at(t)
    fade = float(np.clip((t - c[0]) / 0.5, 0, 1))
    cap_title.set_text(c[1])
    cap_title.set_color(c[4])
    cap_body.set_text(c[2])
    cap_wear.set_text(c[3])
    cap_wear.set_color("#B42318" if c[4] in (C_BOUND_TXT, C_MIXED_TXT) else C_INK)
    cap_bar.set_color(c[4])
    for a in (cap_title, cap_body, cap_wear):
        a.set_alpha(fade)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", action="store_true", help="write a few PNG frames only")
    args = ap.parse_args()

    print(f"liftoff t={T_LIFT:.1f}s N={N_LIFT:.2f}; touchdown t={T_TOUCH:.1f}s N={N_TOUCH:.2f}; "
          f"stop t={T_STOP:.1f}s; wear split up/run/down = {PCT_UP:.1f}/{PCT_RUN:.2f}/{PCT_DOWN:.1f} %")

    if args.preview:
        outdir = os.environ.get("PREVIEW_DIR", os.path.join(ROOT, "scripts", "_preview"))
        os.makedirs(outdir, exist_ok=True)
        for ts in (2, 7, 14, T_LIFT + 1, 30, 40, T_TOUCH + 2, 55, 64):
            i = int(round(ts * FPS))
            draw_frame(i)
            fig.savefig(os.path.join(outdir, f"frame_{ts:05.1f}.png"), dpi=DPI)
        print("preview written to", outdir)
        return

    writer = FFMpegWriter(fps=FPS, codec="libx264",
                          extra_args=["-crf", "26", "-preset", "slow", "-tune", "animation",
                                      "-pix_fmt", "yuv420p", "-movflags", "+faststart"])
    n_frames = len(t_arr)
    with writer.saving(fig, OUT_MP4, dpi=DPI):
        for i in range(n_frames):
            draw_frame(i)
            writer.grab_frame(facecolor="white")
            if i % 150 == 0:
                print(f"frame {i}/{n_frames}", flush=True)
    draw_frame(int(32 * FPS))
    fig.savefig(OUT_POSTER, dpi=DPI)
    print("wrote", OUT_MP4, "and", OUT_POSTER)


if __name__ == "__main__":
    main()
