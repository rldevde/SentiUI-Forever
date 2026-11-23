#!/usr/bin/env python3
"""Generate the complete SentiUI texture suite.

Produces every asset in Media/Textures/ as an uncompressed 32bpp BGRA
TGA plus a PNG preview, and a _ContactSheet.png review sheet. The
Sentinel look: flat dark surfaces, 1px lines, one gold accent, ~5-6px
corner radius, no bevels, no heavy gradients.

WoW edgeFile layout (warcraft.wiki/wiki/EdgeFiles): an edge texture is
cut horizontally into 8 equal slices - Left, Right, Top, Bottom, TL,
TR, BL, BR. Side slices stretch along their edge; corner slices render
edgeSize x edgeSize. The "outside" edge of a side slice is the frame's
outer boundary (the band extends inward); Top/Bottom are stored rotated
-90 deg, so their outside edge is the left/right file column. Corners
are stored un-rotated as they appear on screen.

Tint rule: anything recolored at runtime ships white + alpha (tint =
vertex color x texture); baked color only where the spec calls for it.

Run:  python make_media.py
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "Media", "Textures")
SHEET_FILE = os.path.join(OUT_DIR, "_ContactSheet.png")

SS = 8                    # supersample factor for AA shapes
SLICE = 16                # px per edge slice -> file 128x16

# palette -----------------------------------------------------------------------
ACCENT = (235, 173, 51)     # EBAD33 gold
BLUE = (51, 158, 255)      # 339EFF
PANEL = (11, 13, 18)      # 0B0D12
RAISED = (19, 22, 28)     # 13161C
INSET = (7, 8, 12)        # 07080C
BORD = (34, 40, 54)       # 222836
TXT = (235, 238, 245)      # EBEEF5
DIM = (140, 146, 163)     # 8C92A3
THREAT = (192, 57, 43)      # C0392B
WHITE = (255, 255, 255)
GREEN = (77, 217, 122)
RED = (240, 82, 92)


def w_rgba(a=255):
    return (255, 255, 255, a)


def rgba(c, a=255):
    return (c[0], c[1], c[2], a)


# -----------------------------------------------------------------------------
# output helpers

def write_tga(path, arr):
    """Uncompressed 32bpp BGRA TGA, top-down. arr = uint8 (h, w, 4) RGBA."""
    h, w = arr.shape[:2]
    header = bytearray(18)
    header[2] = 2
    header[12] = w & 0xFF
    header[13] = w >> 8
    header[14] = h & 0xFF
    header[15] = h >> 8
    header[16] = 32
    header[17] = 0x28                  # 8 alpha bits + top-down origin
    bgra = arr[..., [2, 1, 0, 3]]
    with open(path, "wb") as f:
        f.write(header)
        f.write(bgra.tobytes())


def save(name, arr):
    """arr = float RGBA 0..255 (h, w, 4). Writes .tga + .png preview."""
    a = np.clip(arr + 0.5, 0, 255).astype(np.uint8)
    base = os.path.join(OUT_DIR, name)
    write_tga(base + ".tga", a)
    Image.fromarray(a, "RGBA").save(base + ".png")


def down(arr, ss=SS):
    """Box-downsample a supersampled float RGBA canvas."""
    h, w = arr.shape[:2]
    return arr.reshape(h // ss, ss, w // ss, ss, 4).mean(axis=(1, 3))


def grid(w, h, ss=SS):
    """Logical-px coordinate grids for a w x h canvas supersampled ss x."""
    y, x = np.mgrid[0:h * ss, 0:w * ss].astype(np.float64)
    return (x + 0.5) / ss, (y + 0.5) / ss


def glyph(w, h, fn, ss=SS):
    """PIL ImageDraw canvas at ss x, downsampled with LANCZOS."""
    im = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    fn(d, w * ss, h * ss, ss)
    im = im.resize((w, h), Image.LANCZOS)
    return np.asarray(im).astype(np.float64)


def stroke(d, pts, width_lpx, ss, fill=(255, 255, 255, 255), joint="curve"):
    d.line(pts, fill=fill, width=max(1, int(round(width_lpx * ss))), joint=joint)


# -----------------------------------------------------------------------------
# tileable noise

def tileable_noise(w, h, cells=8, seed=0):
    rng = np.random.default_rng(seed)
    g = rng.random((cells, cells))
    fy = np.arange(h) / h * cells
    fx = np.arange(w) / w * cells
    y0 = np.floor(fy).astype(int) % cells
    y1 = (y0 + 1) % cells
    x0 = np.floor(fx).astype(int) % cells
    x1 = (x0 + 1) % cells
    ty = (fy - np.floor(fy))[:, None]
    tx = (fx - np.floor(fx))[None, :]
    return (g[np.ix_(y0, x0)] * (1 - tx) * (1 - ty)
            + g[np.ix_(y0, x1)] * tx * (1 - ty)
            + g[np.ix_(y1, x0)] * (1 - tx) * ty
            + g[np.ix_(y1, x1)] * tx * ty)


def fill_tex(w, h, rgb, alpha, noise_pct=0.04, seed=1):
    n = tileable_noise(w, h, 8, seed)
    mod = 1.0 + (n - 0.5) * 2 * noise_pct
    arr = np.zeros((h, w, 4))
    for i in range(3):
        arr[..., i] = rgb[i] * mod
    arr[..., 3] = alpha
    return arr


def flat(w, h, rgba_):
    arr = np.zeros((h, w, 4))
    arr[...] = rgba_
    return arr


# -----------------------------------------------------------------------------
# edge-file machinery
#
# Slices are built at SLICE*SS device px in logical-px coordinates.
# File order: Left, Right, Top, Bottom, TL, TR, BL, BR.
# For side slices "outside" is always file column 0 (Left) resp. N
# (Right, stored flipped). Top reuses the Left slice (outside = left col),
# Bottom reuses the Right slice (outside = right col).

def slice_grid(n=SLICE, ss=SS):
    return grid(n, n, ss)


def side_ring(n=SLICE, ss=SS, bw=3, line=w_rgba(255), band=(128, 128, 128, 235)):
    """Hard border line at the outside edge + inner band. band: rgba or
    callable(dd) -> (n,4) where dd = distance inward past the line."""
    x, _ = slice_grid(n, ss)
    d = x
    arr = np.zeros((n * ss, n * ss, 4))
    is_line = d < bw
    if callable(band):
        b = band(d - bw)
    else:
        b = np.empty((n * ss, n * ss, 4))
        b[...] = band
    arr[~is_line] = b[~is_line]
    arr[is_line] = line
    return arr


def side_glow(n=SLICE, ss=SS, peak=0.9, sigma=4.5, color=WHITE):
    """Soft glow peaking at the outside edge, fading inward."""
    x, _ = slice_grid(n, ss)
    a = peak * np.exp(-((x / sigma) ** 2))
    arr = np.zeros((n * ss, n * ss, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = color
    arr[..., 3] = a * 255
    return arr


def corner_ring(cx, cy, n=SLICE, ss=SS, bw=3, line=w_rgba(255),
                band=(128, 128, 128, 235), line_fn=None):
    """Quarter ring around the tile's inner corner (cx, cy); band fills
    the inner disc. line_fn(x, y) may return a per-pixel line color."""
    x, y = slice_grid(n, ss)
    d = np.hypot(x - cx, y - cy)
    r = n
    arr = np.zeros((n * ss, n * ss, 4))
    is_line = (d > r - bw) & (d <= r + 0.5)
    is_in = d <= r - bw
    if line_fn is not None:
        arr[is_line] = line_fn(x[is_line], y[is_line])
    else:
        arr[is_line] = line
    if callable(band):
        arr[is_in] = band((r - bw) - d[is_in])
    else:
        arr[is_in] = band
    return arr


def corner_glow(cx, cy, n=SLICE, ss=SS, peak=0.9, sigma=4.5, color=WHITE):
    x, y = slice_grid(n, ss)
    d = np.hypot(x - cx, y - cy)
    dist_in = np.maximum(n - d, 0.0)
    a = peak * np.exp(-((dist_in / sigma) ** 2))
    a[d > n + 0.5] = 0
    arr = np.zeros((n * ss, n * ss, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = color
    arr[..., 3] = a * 255
    return arr


def corner_square(edges, n=SLICE, ss=SS, bw=3, line=w_rgba(255),
                  band=(128, 128, 128, 235)):
    """Square corner: 'edges' = ('l','t') for TL etc. Border runs along
    the two outer edges, band fills the interior."""
    x, y = slice_grid(n, ss)
    is_line = np.zeros_like(x, dtype=bool)
    dd = np.full_like(x, np.inf)
    if 'l' in edges:
        is_line |= x < bw
        dd = np.minimum(dd, x - bw)
    if 'r' in edges:
        is_line |= x > n - bw
        dd = np.minimum(dd, n - x - bw)
    if 't' in edges:
        is_line |= y < bw
        dd = np.minimum(dd, y - bw)
    if 'b' in edges:
        is_line |= y > n - bw
        dd = np.minimum(dd, n - y - bw)
    arr = np.zeros((n * ss, n * ss, 4))
    is_in = ~is_line
    if callable(band):
        arr[is_in] = band(np.maximum(dd[is_in], 0))
    else:
        arr[is_in] = band
    arr[is_line] = line
    return arr


def edge_file(slices, n=SLICE):
    """Assemble 8 slice arrays (n*ss, n*ss, 4) into one (n*ss, 8*n*ss, 4)
    strip, then downsample."""
    strip = np.concatenate(slices, axis=1)
    return down(strip)


def ordered(L, R, T, B, TL, TR, BL, BR):
    return [L, R, T, B, TL, TR, BL, BR]


# -----------------------------------------------------------------------------
# rounded-rect signed distance for masks/frames

def sdf_rrect(x, y, w, h, r):
    qx = np.abs(x - w / 2) - (w / 2 - r)
    qy = np.abs(y - h / 2) - (h / 2 - r)
    outside = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
    inside = np.minimum(np.maximum(qx, qy), 0)
    return outside + inside - r


def rrect_ring(w, h, r, ring_w, line=w_rgba(255), inner=None, outer_glow=0,
               ss=SS):
    """Rounded-rect ring texture: transparent outside, `ring_w` px line
    at the silhouette, optional inner band/fill."""
    x, y = grid(w, h, ss)
    d = sdf_rrect(x, y, w, h, r)
    arr = np.zeros((h * ss, w * ss, 4))
    is_line = np.abs(d) <= ring_w / 2 + 0.25
    if inner is not None:
        is_in = d < -ring_w / 2
        if callable(inner):
            arr[is_in] = inner(-d[is_in] - ring_w / 2)
        else:
            arr[is_in] = inner
    if outer_glow > 0:
        is_out = d > ring_w / 2
        g = outer_glow * np.exp(-(((d - ring_w / 2) / 3.0) ** 2))
        ga = np.zeros((h * ss, w * ss, 4))
        ga[..., 0], ga[..., 1], ga[..., 2] = line[:3]
        ga[..., 3] = np.where(is_out, g * 255, 0)
        arr = np.maximum(arr, ga)
    arr[is_line] = line
    return down(arr, ss)


# =============================================================================
# ASSET BUILDERS
# =============================================================================

A = []          # (name, w, h, arr)


def reg(name, arr):
    h, w = arr.shape[:2]
    A.append((name, w, h, arr))


# --- 1. chrome / borders -------------------------------------------------------

def build_pill_edge():
    s = side_ring(bw=3, line=w_rgba(255), band=(128, 128, 128, 235))
    sr = np.fliplr(s)
    c = lambda cx, cy: corner_ring(cx, cy, bw=3, line=w_rgba(255),
                                   band=(128, 128, 128, 235))
    n = SLICE
    return edge_file(ordered(s, sr, s, sr,
                             c(n, n), c(0, n), c(n, 0), c(0, 0)))


def build_square_edge():
    s = side_ring(bw=3, line=w_rgba(255), band=(128, 128, 128, 235))
    sr = np.fliplr(s)
    cs = lambda e: corner_square(e, bw=3, line=w_rgba(255),
                                 band=(128, 128, 128, 235))
    return edge_file(ordered(s, sr, s, sr,
                             cs('lt'), cs('rt'), cs('lb'), cs('rb')))


def build_glow_edge(peak=0.9, sigma=5.0):
    s = side_glow(peak=peak, sigma=sigma)
    sr = np.fliplr(s)
    n = SLICE
    g = lambda cx, cy: corner_glow(cx, cy, peak=peak, sigma=sigma)
    return edge_file(ordered(s, sr, s, sr,
                             g(n, n), g(0, n), g(n, 0), g(0, 0)))


def build_gold_edge():
    gold = rgba(ACCENT, 255)
    gold_hi = (255, 220, 140, 255)

    def band(dd):
        b = np.zeros(dd.shape + (4,))
        b[..., 0], b[..., 1], b[..., 2] = 128, 128, 128
        b[..., 3] = 200 * np.exp(-(dd / 9.0)) + 60
        return b

    s = side_ring(bw=3, line=gold, band=band)
    sr = np.fliplr(s)
    st = side_ring(bw=3, line=gold_hi, band=band)   # stronger top edge
    n = SLICE

    # top corners: arc brightness lerps to the brighter tone near the
    # top end of the arc so it lands flush on the stronger top edge
    def cfn():
        def fn(x, y):
            t = np.clip(1.0 - y / SLICE, 0, 1)
            out = np.zeros((x.shape[0], 4))
            for i in range(3):
                out[..., i] = gold[i] + (gold_hi[i] - gold[i]) * t
            out[..., 3] = 255
            return out
        return fn

    return edge_file(ordered(s, sr, st, sr,
                             corner_ring(n, n, bw=3, band=band, line_fn=cfn()),
                             corner_ring(0, n, bw=3, band=band, line_fn=cfn()),
                             corner_ring(n, 0, bw=3, band=band, line=gold),
                             corner_ring(0, 0, bw=3, band=band, line=gold)))


def build_tooltip_edge():
    band = (PANEL[0], PANEL[1], PANEL[2], 245)
    s = side_ring(bw=3, line=w_rgba(255), band=band)
    sr = np.fliplr(s)
    cs = lambda e: corner_square(e, bw=3, line=w_rgba(255), band=band)
    return edge_file(ordered(s, sr, s, sr,
                             cs('lt'), cs('rt'), cs('lb'), cs('rb')))


def build_target_ring():
    """Gold accent ring: crisp 2px core + short soft tail inward."""
    gold = rgba(ACCENT, 255)

    def band(dd):
        b = np.zeros(dd.shape + (4,))
        b[..., 0], b[..., 1], b[..., 2] = ACCENT
        b[..., 3] = 120 * np.exp(-(dd / 5.0))
        return b

    s = side_ring(bw=2, line=gold, band=band)
    sr = np.fliplr(s)
    n = SLICE
    c = lambda cx, cy: corner_ring(cx, cy, bw=2, line=gold, band=band)
    return edge_file(ordered(s, sr, s, sr,
                             c(n, n), c(0, n), c(n, 0), c(0, 0)))


# --- 2. fills / surfaces -------------------------------------------------------

def build_gloss():
    w, h = 8, 32
    _, y = grid(w, h, 1)
    a = np.clip(1.0 - y / (h * 0.75), 0, 1) ** 1.5 * 70
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    arr[..., 3] = a
    return arr


def build_divider():
    w, h = 64, 4
    x, _ = grid(w, h, 1)
    line = np.zeros((h, w, 4))
    line[..., 0], line[..., 1], line[..., 2] = 255, 255, 255
    a = np.where((x[0] > 4) & (x[0] < w - 4), 190,
                 np.clip((np.minimum(x[0], w - x[0]) - 0.5) / 4, 0, 1) * 190)
    line[1, :, 3] = a
    line[2, :, 3] = a * 0.55
    line[0, :, 3] = a * 0.2
    line[3, :, 3] = a * 0.2
    return line


# --- 3. bars -------------------------------------------------------------------

def build_bar_flat():
    return flat(64, 8, w_rgba(255))


def build_bar_gloss():
    w, h = 64, 8
    _, y = grid(w, h, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    sheen = np.clip(1.4 - y / 3.0, 0, 1) * 255
    base = 225 + sheen * 0.12
    arr[..., 3] = np.clip(base, 0, 255)
    arr[..., 0] = np.clip(255, 0, 255)
    # slightly darker bottom rows
    arr[..., 3] *= np.where(y > h - 2, 0.85, 1.0)
    return arr


def build_bar_striped():
    w, h = 64, 8
    x, y = grid(w, h, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    stripe = ((x + y) % 8) < 3
    arr[..., 3] = np.where(stripe, 210, 255)
    return arr


def build_bar_segment():
    w, h = 64, 8
    x, _ = grid(w, h, 1)
    arr = flat(w, h, w_rgba(255))
    notch = (x % 8) < 1
    arr[..., 3] = np.where(notch, 0, 255)
    arr[0, :, 3] = np.where(notch[0], 0, 255)
    return arr


def build_bar_spark():
    w, h = 8, 32
    x, y = grid(w, h, SS)
    cx = w / 2
    core = np.exp(-(((x - cx) / 0.9) ** 2))
    glow = 0.55 * np.exp(-(((x - cx) / 2.6) ** 2))
    taper = np.clip(1.0 - np.abs(y - h / 2) / (h / 2), 0.25, 1)
    arr = np.zeros((h * SS, w * SS, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    arr[..., 3] = np.clip((core + glow) * taper, 0, 1) * 255
    return down(arr)


# --- 4. controls ---------------------------------------------------------------

def g_check_empty(d, w, h, ss):
    d.rounded_rectangle([1.5 * ss, 1.5 * ss, w - 1.5 * ss, h - 1.5 * ss],
                        radius=2.5 * ss, fill=rgba(INSET, 235),
                        outline=(255, 255, 255, 215), width=int(1.2 * ss))


def g_check_on(d, w, h, ss):
    g_check_empty(d, w, h, ss)
    stroke(d, [(3.6 * ss, 8.4 * ss), (6.6 * ss, 11.4 * ss), (12.4 * ss, 4.6 * ss)],
           1.8, ss, rgba(ACCENT))


def g_radio_off(d, w, h, ss):
    d.ellipse([2 * ss, 2 * ss, w - 2 * ss, h - 2 * ss], fill=rgba(INSET, 235),
              outline=(255, 255, 255, 215), width=int(1.2 * ss))


def g_radio_on(d, w, h, ss):
    g_radio_off(d, w, h, ss)
    d.ellipse([5 * ss, 5 * ss, w - 5 * ss, h - 5 * ss], fill=rgba(ACCENT))


def g_thumb(d, w, h, ss):
    d.rounded_rectangle([1.2 * ss, 1 * ss, w - 1.2 * ss, h - 1 * ss],
                        radius=4 * ss, fill=(255, 255, 255, 255))


def g_arrow(d, w, h, ss, direction):
    if direction == 'up':
        pts = [(3 * ss, 8.2 * ss), (6 * ss, 4.6 * ss), (9 * ss, 8.2 * ss)]
    elif direction == 'down':
        pts = [(3 * ss, 3.8 * ss), (6 * ss, 7.4 * ss), (9 * ss, 3.8 * ss)]
    elif direction == 'left':
        pts = [(8.2 * ss, 3 * ss), (4.6 * ss, 6 * ss), (8.2 * ss, 9 * ss)]
    else:
        pts = [(3.8 * ss, 3 * ss), (7.4 * ss, 6 * ss), (3.8 * ss, 9 * ss)]
    stroke(d, pts, 1.4, ss)


def g_close(d, w, h, ss):
    stroke(d, [(4 * ss, 4 * ss), (10 * ss, 10 * ss)], 1.5, ss)
    stroke(d, [(10 * ss, 4 * ss), (4 * ss, 10 * ss)], 1.5, ss)


def g_plus(d, w, h, ss):
    stroke(d, [(6 * ss, 2.8 * ss), (6 * ss, 9.2 * ss)], 1.5, ss)
    stroke(d, [(2.8 * ss, 6 * ss), (9.2 * ss, 6 * ss)], 1.5, ss)


def g_minus(d, w, h, ss):
    stroke(d, [(2.8 * ss, 6 * ss), (9.2 * ss, 6 * ss)], 1.5, ss)


def g_dropdown(d, w, h, ss):
    stroke(d, [(4.4 * ss, 3.6 * ss), (8 * ss, 7.8 * ss), (11.6 * ss, 3.6 * ss)],
           1.5, ss)


def g_gear(d, w, h, ss):
    cx = cy = 8 * ss
    lw = int(1.2 * ss)
    for k in range(8):
        a = math.radians(k * 45)
        r0, r1 = 4.6 * ss, 7.2 * ss
        d.line([(cx + r0 * math.cos(a), cy + r0 * math.sin(a)),
                (cx + r1 * math.cos(a), cy + r1 * math.sin(a))],
               fill=(255, 255, 255, 255), width=lw)
    d.ellipse([cx - 4.2 * ss, cy - 4.2 * ss, cx + 4.2 * ss, cy + 4.2 * ss],
              outline=(255, 255, 255, 255), width=lw)
    d.ellipse([cx - 1.3 * ss, cy - 1.3 * ss, cx + 1.3 * ss, cy + 1.3 * ss],
              outline=(255, 255, 255, 255), width=lw)


def g_lock(d, w, h, ss, open_):
    lw = int(1.3 * ss)
    d.rounded_rectangle([3 * ss, 6.8 * ss, 11 * ss, 12.8 * ss],
                        radius=1.6 * ss, outline=(255, 255, 255, 255),
                        width=lw)
    # shackle: arc over the top; open lock leaves the right side up
    box = [4.2 * ss, 2 * ss, 9.8 * ss, 8.6 * ss]
    if open_:
        d.arc(box, start=140, end=330, fill=(255, 255, 255, 255), width=lw)
    else:
        d.arc(box, start=180, end=360, fill=(255, 255, 255, 255), width=lw)
        d.line([(4.2 * ss + 2.8 * ss, 5.3 * ss), (4.2 * ss + 2.8 * ss, 6.8 * ss)],
               fill=(255, 255, 255, 255), width=lw)
        d.line([(9.8 * ss - 2.8 * ss, 5.3 * ss), (9.8 * ss - 2.8 * ss, 6.8 * ss)],
               fill=(255, 255, 255, 255), width=lw)
    d.ellipse([6.3 * ss, 8.7 * ss, 7.7 * ss, 10.1 * ss],
              fill=(255, 255, 255, 255))


def g_shield(d, w, h, ss, lw_lpx=1.3):
    lw = int(lw_lpx * ss)
    pts = [(8 * ss, 13 * ss), (12.8 * ss, 9.5 * ss), (12.8 * ss, 3 * ss),
           (3.2 * ss, 3 * ss), (3.2 * ss, 9.5 * ss)]
    d.line(pts + [pts[0]], fill=(255, 255, 255, 255), width=lw, joint='curve')


def g_cast_shield(d, w, h, ss):
    g_shield(d, w, h, ss)
    stroke(d, [(8 * ss, 5.4 * ss), (8 * ss, 9.4 * ss)], 1.2, ss)
    stroke(d, [(5.6 * ss, 7.4 * ss), (10.4 * ss, 7.4 * ss)], 1.2, ss)


def g_skull(d, w, h, ss):
    d.ellipse([2.6 * ss, 1.6 * ss, 13.4 * ss, 10.4 * ss],
              fill=(255, 255, 255, 255))
    d.rectangle([4.6 * ss, 8.6 * ss, 11.4 * ss, 13 * ss],
                fill=(255, 255, 255, 255))
    z = (0, 0, 0, 0)
    d.ellipse([4.6 * ss, 5.4 * ss, 7 * ss, 8 * ss], fill=z)
    d.ellipse([9 * ss, 5.4 * ss, 11.4 * ss, 8 * ss], fill=z)
    d.polygon([(8 * ss, 9.6 * ss), (7.2 * ss, 11 * ss), (8.8 * ss, 11 * ss)],
              fill=z)
    for tx in (6.1, 8, 9.9):
        d.line([(tx * ss, 11.2 * ss), (tx * ss, 13 * ss)], fill=z,
               width=int(0.7 * ss))


def g_res(d, w, h, ss):
    # phoenix / rebirth glyph: rising bird - head dot, swept wings, tail
    d.ellipse([14 * ss, 6 * ss, 18 * ss, 10 * ss], fill=(255, 255, 255, 255))
    d.arc([2 * ss, 10 * ss, 18 * ss, 30 * ss], start=300, end=20,
          fill=(255, 255, 255, 255), width=int(1.6 * ss))
    d.arc([14 * ss, 10 * ss, 30 * ss, 30 * ss], start=160, end=240,
          fill=(255, 255, 255, 255), width=int(1.6 * ss))
    stroke(d, [(16 * ss, 12 * ss), (16 * ss, 20 * ss)], 1.6, ss)
    stroke(d, [(12.5 * ss, 24 * ss), (16 * ss, 20.5 * ss), (19.5 * ss, 24 * ss)],
           1.4, ss)


def g_offline(d, w, h, ss):
    lw = int(1.3 * ss)
    # monitor + slash
    d.rounded_rectangle([3 * ss, 3.4 * ss, 13 * ss, 10 * ss], radius=1 * ss,
                        outline=(255, 255, 255, 255), width=lw)
    stroke(d, [(6 * ss, 12.4 * ss), (10 * ss, 12.4 * ss)], 1.3, ss)
    stroke(d, [(8 * ss, 10 * ss), (8 * ss, 11.6 * ss)], 1.3, ss)
    stroke(d, [(3.4 * ss, 12.6 * ss), (12.6 * ss, 2.6 * ss)], 1.4, ss)


def g_resting(d, w, h, ss):
    def z(x, y, s):
        stroke(d, [(x * ss, y * ss), ((x + s) * ss, y * ss),
                   (x * ss, (y + s) * ss), ((x + s) * ss, (y + s) * ss)],
               1.2, ss)
    z(2.5, 2.5, 4.2)
    z(6.5, 6.5, 4.8)
    z(9.5, 10, 3.8)


def g_combat(d, w, h, ss):
    stroke(d, [(3.4 * ss, 3.4 * ss), (12.6 * ss, 12.6 * ss)], 1.5, ss)
    stroke(d, [(12.6 * ss, 3.4 * ss), (3.4 * ss, 12.6 * ss)], 1.5, ss)
    # hilts
    stroke(d, [(2.8 * ss, 4.6 * ss), (4.6 * ss, 2.8 * ss)], 1.1, ss)
    stroke(d, [(11.4 * ss, 2.8 * ss), (13.2 * ss, 4.6 * ss)], 1.1, ss)
    stroke(d, [(2.8 * ss, 11.4 * ss), (4.6 * ss, 13.2 * ss)], 1.1, ss)
    stroke(d, [(13.2 * ss, 11.4 * ss), (11.4 * ss, 13.2 * ss)], 1.1, ss)


def g_leader(d, w, h, ss):
    pts = [(2.8 * ss, 11.6 * ss), (3.2 * ss, 4.8 * ss), (5.8 * ss, 8 * ss),
           (8 * ss, 3.6 * ss), (10.2 * ss, 8 * ss), (12.8 * ss, 4.8 * ss),
           (13.2 * ss, 11.6 * ss)]
    d.polygon(pts, fill=(255, 255, 255, 255))
    d.rectangle([2.8 * ss, 12.2 * ss, 13.2 * ss, 13.4 * ss],
                fill=(255, 255, 255, 255))


def g_master_loot(d, w, h, ss):
    # coin stack
    d.ellipse([4.5 * ss, 2.6 * ss, 11.5 * ss, 5.6 * ss],
              fill=(255, 255, 255, 255))
    for y in (5.6, 7.9, 10.2):
        d.rounded_rectangle([4.5 * ss, y * ss, 11.5 * ss, (y + 2.4) * ss],
                            radius=0.8 * ss, fill=(255, 255, 255, 255))
    d.ellipse([4.5 * ss, 11 * ss, 11.5 * ss, 14 * ss],
              fill=(255, 255, 255, 255))


def g_ready(d, w, h, ss):
    # left half: green tick / right half: red cross (split via texcoord)
    stroke(d, [(1.2 * ss, 8.6 * ss), (3.6 * ss, 11 * ss), (7 * ss, 4.6 * ss)],
           1.6, ss, rgba(GREEN))
    stroke(d, [(10 * ss, 5 * ss), (14.4 * ss, 11 * ss)], 1.6, ss, rgba(RED))
    stroke(d, [(14.4 * ss, 5 * ss), (10 * ss, 11 * ss)], 1.6, ss, rgba(RED))


def g_role_tank(d, w, h, ss):
    g_shield(d, w, h, ss)


def g_role_heal(d, w, h, ss):
    lw = int(2.2 * ss)
    d.line([(8 * ss, 3.6 * ss), (8 * ss, 12.4 * ss)],
           fill=(255, 255, 255, 255), width=lw)
    d.line([(3.6 * ss, 8 * ss), (12.4 * ss, 8 * ss)],
           fill=(255, 255, 255, 255), width=lw)


def g_role_dps(d, w, h, ss):
    # dagger: blade + crossguard + pommel
    stroke(d, [(5 * ss, 11 * ss), (11 * ss, 5 * ss)], 1.7, ss)
    stroke(d, [(8.2 * ss, 9.6 * ss), (10.4 * ss, 11.8 * ss)], 1.3, ss)
    stroke(d, [(4 * ss, 12 * ss), (5.6 * ss, 10.4 * ss)], 1.5, ss)
    d.ellipse([3 * ss, 11.4 * ss, 4.6 * ss, 13 * ss],
              fill=(255, 255, 255, 255))


def g_dispel_magic(d, w, h, ss):
    # four-point star
    c = 8 * ss
    pts = [(c, 2.4 * ss), (9.6 * ss, 6.4 * ss), (13.6 * ss, c),
           (9.6 * ss, 9.6 * ss), (c, 13.6 * ss), (6.4 * ss, 9.6 * ss),
           (2.4 * ss, c), (6.4 * ss, 6.4 * ss)]
    d.polygon(pts, fill=(255, 255, 255, 255))


def g_dispel_curse(d, w, h, ss):
    # crescent moon
    d.pieslice([2.5 * ss, 2 * ss, 13.5 * ss, 14 * ss], start=40, end=320,
               fill=(255, 255, 255, 255))
    d.ellipse([5.5 * ss, 2.8 * ss, 13 * ss, 11.6 * ss], fill=(0, 0, 0, 0))


def g_dispel_disease(d, w, h, ss):
    # three spore dots
    d.ellipse([2.8 * ss, 4 * ss, 7 * ss, 8.2 * ss], fill=(255, 255, 255, 255))
    d.ellipse([9 * ss, 3 * ss, 13.2 * ss, 7.2 * ss], fill=(255, 255, 255, 255))
    d.ellipse([5.8 * ss, 9.4 * ss, 10.2 * ss, 13.8 * ss],
              fill=(255, 255, 255, 255))


def g_dispel_poison(d, w, h, ss):
    # droplet
    c = 8 * ss
    d.polygon([(c, 2.4 * ss), (11.6 * ss, 9 * ss), (c, 9 * ss), (4.4 * ss, 9 * ss)],
              fill=(255, 255, 255, 255))
    d.ellipse([4.2 * ss, 6.6 * ss, 11.8 * ss, 13.6 * ss],
              fill=(255, 255, 255, 255))
    d.ellipse([6.4 * ss, 8.6 * ss, 8 * ss, 10.2 * ss], fill=(0, 0, 0, 0))


# --- 5. frames / containers ----------------------------------------------------

def build_tab(active):
    """Edge-style tab chip, 8 slices of 24px -> 192x24. Active = raised
    fill + 2px gold left blade."""
    n, ss = 24, SS
    fill_c = rgba(RAISED, 245) if active else (11, 13, 18, 235)
    gold = rgba(ACCENT, 255)

    def side(blade):
        x, _ = grid(n, n, ss)
        arr = np.zeros((n * ss, n * ss, 4))
        arr[...] = fill_c
        if blade:
            arr[x < 2] = gold
        # faint top edge line for definition (outside = left file col is
        # the vertical edge here; the top border is drawn into corners)
        return arr

    L = side(active)
    R = side(False)

    def corner(cx, cy, left_side):
        x, y = grid(n, n, ss)
        d = np.hypot(x - cx, y - cy)
        arr = np.zeros((n * ss, n * ss, 4))
        inside = d <= n + 0.5
        arr[inside] = fill_c
        if left_side and active:
            arr[inside & (x < 2)] = gold
        return arr

    return edge_file([L, R, L, R,
                      corner(n, n, True), corner(0, n, False),
                      corner(n, 0, True), corner(0, 0, False)], n=n)


def build_portrait_frame():
    return rrect_ring(64, 64, r=14, ring_w=3, line=w_rgba(255),
                      inner=lambda dd: np.stack(
                          [np.full_like(dd, 20), np.full_like(dd, 23),
                           np.full_like(dd, 30),
                           150 * np.exp(-(dd / 10.0))], axis=-1))


def build_icon_mask():
    x, y = grid(64, 64, SS)
    d = sdf_rrect(x, y, 64, 64, 12)
    arr = np.zeros((64 * SS, 64 * SS, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    arr[..., 3] = np.where(d <= 0, 255, 0)
    return down(arr)


def build_icon_border():
    return rrect_ring(64, 64, r=12, ring_w=2.5, line=w_rgba(255))


def build_button_ring():
    return rrect_ring(64, 64, r=9, ring_w=2.5, line=w_rgba(255))


def build_button_pushed():
    return rrect_ring(
        64, 64, r=9, ring_w=2.5, line=(180, 180, 180, 200),
        inner=lambda dd: np.stack(
            [np.zeros_like(dd), np.zeros_like(dd), np.zeros_like(dd),
             np.clip(90 * np.exp(-(dd / 8.0)) + 40, 0, 160)], axis=-1))


def build_button_checked():
    return rrect_ring(
        64, 64, r=9, ring_w=3, line=rgba(ACCENT, 255),
        inner=lambda dd: np.stack(
            [np.full_like(dd, ACCENT[0]), np.full_like(dd, ACCENT[1]),
             np.full_like(dd, ACCENT[2]),
             80 * np.exp(-(dd / 7.0))], axis=-1))


def build_cooldown():
    w = h = 64
    x, y = grid(w, h, SS)
    cx = cy = w / 2
    ang = np.degrees(np.arctan2(x - cx, -(y - cy))) % 360   # 0 = up, cw
    r = np.hypot(x - cx, y - cy)
    arr = np.zeros((h * SS, w * SS, 4))
    inside = r <= w / 2
    wedge = inside & (ang <= 100)
    arr[..., 3] = np.where(wedge, 165, 0)
    return down(arr)


# --- 6. unit frames ------------------------------------------------------------

def build_uf_backdrop():
    w, h = 64, 32
    _, y = grid(w, h, 1)
    arr = flat(w, h, (8, 10, 14, 200))
    arr[..., 3] = np.where(y < 1, 120, 200)   # faint top edge
    for i in range(3):
        arr[..., i] = np.where(y < 1, 60, 8 + i * 2)
    arr[0, :, 0] = 90
    arr[0, :, 1] = 96
    arr[0, :, 2] = 112
    arr[0, :, 3] = 150
    return arr


def build_absorb():
    w, h = 64, 8
    x, y = grid(w, h, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    hatch = ((x - y) % 6) < 2.5
    arr[..., 3] = np.where(hatch, 40, 105)
    return arr


def build_incoming_heal():
    w, h = 64, 8
    _, y = grid(w, h, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 60, 200, 110
    arr[..., 3] = 85 + np.clip(1 - y / 4, 0, 1) * 30
    return arr


def build_cast_bg():
    w, h = 64, 16
    _, y = grid(w, h, 1)
    arr = flat(w, h, rgba(INSET, 245))
    # sunken look: darker top inner shadow, faint bottom edge light
    arr[..., 3] = np.where(y < 1.5, 255, 245)
    for i in range(3):
        arr[0, :, i] = 3
        arr[1, :, i] = max(0, INSET[i] - 3)
    edge = (y >= h - 1)
    arr[..., 0] = np.where(edge, 70, arr[..., 0])
    arr[..., 1] = np.where(edge, 76, arr[..., 1])
    arr[..., 2] = np.where(edge, 92, arr[..., 2])
    arr[..., 3] = np.where(edge, 200, arr[..., 3])
    return arr


def build_range_fade():
    return flat(64, 64, (0, 0, 0, 150))


def build_elite_border():
    base = rrect_ring(64, 64, r=10, ring_w=2.2, line=rgba(ACCENT, 255))
    # small gold diamond accents at top/bottom center (minimal ornament)
    im = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), 'RGBA')
    im = im.resize((64 * SS, 64 * SS), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for cx, cy in ((32, 2.6), (32, 61.4)):
        s = 3.2 * SS
        d.polygon([(cx * SS, cy * SS - s), (cx * SS + s * 0.7, cy * SS),
                   (cx * SS, cy * SS + s), (cx * SS - s * 0.7, cy * SS)],
                  fill=rgba(ACCENT))
    im = im.resize((64, 64), Image.LANCZOS)
    return np.asarray(im).astype(np.float64)


def build_group_header():
    w, h = 64, 16
    arr = flat(w, h, rgba(RAISED, 210))
    arr[0, :, 0], arr[0, :, 1], arr[0, :, 2] = ACCENT
    arr[0, :, 3] = 170
    arr[1, :, 0], arr[1, :, 1], arr[1, :, 2] = ACCENT
    arr[1, :, 3] = 60
    return arr


# --- 7. backgrounds / structure ------------------------------------------------

def build_title_bar():
    w, h = 64, 24
    x, y = grid(w, h, 1)
    vert = np.clip(1.0 - y / h * 1.6, 0, 1) ** 1.4
    endfade = np.clip((np.minimum(x, w - x)) / 8.0, 0, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    arr[..., 3] = vert * endfade * 26
    arr[0, :, 3] = np.clip(arr[0, :, 3] + 30 * endfade[0], 0, 255)
    return arr


def build_row_hover():
    return flat(64, 16, w_rgba(20))


def build_row_select():
    arr = flat(64, 16, w_rgba(26))
    arr[:, 0:2, 0], arr[:, 0:2, 1], arr[:, 0:2, 2] = ACCENT
    arr[:, 0:2, 3] = 235
    return arr


def build_slot_bg():
    x, y = grid(64, 64, SS)
    arr = np.zeros((64 * SS, 64 * SS, 4))
    edge = np.minimum(np.minimum(x, 64 - x), np.minimum(y, 64 - y))
    inside = edge > 1.2
    arr[inside] = rgba(INSET, 255)
    ring = (edge > 0.6) & (edge <= 2.4)
    arr[ring] = (90, 100, 122, 110)
    return down(arr)


def build_scroll_inset():
    arr = fill_tex(64, 32, INSET, 250, noise_pct=0.03, seed=7)
    arr[0, :, 0], arr[0, :, 1], arr[0, :, 2] = 2, 3, 4
    return arr


def build_mover_grid():
    w = h = 64
    x, y = grid(w, h, 1)
    arr = np.zeros((h, w, 4))
    line = ((x % 8) < 1) | ((y % 8) < 1)
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 255, 255
    arr[..., 3] = np.where(line, 26, 0)
    arr[..., 3] = np.where(((x % 32) < 1) | ((y % 32) < 1), 40, arr[..., 3])
    return arr


def build_backplate():
    w = h = 128
    x, y = grid(w, h, 1)
    arr = fill_tex(w, h, PANEL, 242, noise_pct=0.025, seed=11)
    # corner vignette <= 6%
    dx = np.minimum(x, w - x)
    dy = np.minimum(y, h - y)
    r = np.hypot(np.clip(28 - dx, 0, None), np.clip(28 - dy, 0, None)) / 28
    vig = 1.0 - 0.06 * np.clip(r, 0, 1) ** 2
    for i in range(3):
        arr[..., i] *= vig
    return arr


# --- 8. suite furniture --------------------------------------------------------

def build_minimap_border():
    w = h = 128
    x, y = grid(w, h, SS)
    edge = np.minimum(np.minimum(x, w - x), np.minimum(y, h - y))
    arr = np.zeros((h * SS, w * SS, 4))
    ring = (edge > 0.4) & (edge <= 2.8)
    arr[ring] = w_rgba(255)
    outer = edge <= 0.4
    arr[outer] = w_rgba(120)
    # gold corner accents: L brackets ~10px at each corner
    acc = np.zeros((h * SS, w * SS, 4))
    arm = 11
    t = 2.2
    near_l = x < arm
    near_r = x > w - arm
    near_t = y < arm
    near_b = y > h - arm
    corner_zone = ((near_l & (y < t)) | (near_t & (x < t)) |
                   (near_r & (y < t)) | (near_t & (x > w - t)) |
                   (near_l & (y > h - t)) | (near_b & (x < t)) |
                   (near_r & (y > h - t)) | (near_b & (x > w - t)))
    acc[corner_zone] = rgba(ACCENT, 230)
    mask = acc[..., 3] > 0
    arr[mask] = acc[mask]
    return down(arr)


def build_actionbar_bg():
    w, h = 128, 32
    x, y = grid(w, h, SS)
    arr = np.zeros((h * SS, w * SS, 4))
    arr[...] = rgba(PANEL, 238)
    edge = np.minimum(np.minimum(x, w - x), np.minimum(y, h - y))
    arr[edge < 1.2] = (90, 98, 118, 120)
    cx = np.abs(x - w / 2) / (w / 2)
    fade = 1.0 + 0.05 * (1 - cx ** 2)
    for i in range(3):
        arr[..., i] *= fade
    return down(arr)


def build_microbar_bg():
    w, h = 128, 16
    x, y = grid(w, h, SS)
    arr = np.zeros((h * SS, w * SS, 4))
    arr[...] = rgba(PANEL, 235)
    edge = np.minimum(np.minimum(x, w - x), np.minimum(y, h - y))
    arr[edge < 1.2] = (90, 98, 118, 110)
    return down(arr)


def build_chat_tab(active):
    w, h = 64, 16
    x, y = grid(w, h, SS)
    r = 4
    # rounded top corners, square bottom
    dx = np.clip(r - np.minimum(x, w - x), 0, None)
    dy_top = np.clip(r - y, 0, None)
    d = np.hypot(dx, dy_top) - r
    inside = d <= 0
    arr = np.zeros((h * SS, w * SS, 4))
    fill = rgba(RAISED, 245) if active else (13, 15, 20, 225)
    arr[inside] = fill
    edge = (d > -1.4) & inside
    line_c = rgba(ACCENT, 240) if active else (100, 108, 128, 120)
    arr[edge] = line_c
    return down(arr)


def build_editbox_bg():
    w, h = 64, 16
    _, y = grid(w, h, 1)
    arr = flat(w, h, rgba(INSET, 248))
    arr[y < 1.6] = (2, 3, 5, 250)          # top inner shadow
    arr[y >= h - 1] = (70, 76, 92, 160)    # faint bottom edge
    return arr


def build_tracker_row():
    arr = np.zeros((16, 64, 4))
    arr[:, 0:1, 0], arr[:, 0:1, 1], arr[:, 0:1, 2] = ACCENT
    arr[:, 0:1, 3] = 220
    arr[:, 1:2, 3] = 60
    arr[:, 1:2, 0], arr[:, 1:2, 1], arr[:, 1:2, 2] = ACCENT
    return arr


def build_panel_button():
    w, h = 64, 16
    x, y = grid(w, h, SS)
    arr = np.zeros((h * SS, w * SS, 4))
    arr[...] = rgba(RAISED, 245)
    edge = np.minimum(np.minimum(x, w - x), np.minimum(y, h - y))
    arr[edge < 1.1] = (100, 108, 128, 110)
    return down(arr)


def build_toast_bg():
    w, h = 64, 32
    x, y = grid(w, h, SS)
    r = 6
    d = sdf_rrect(x, y, w, h, r)
    arr = np.zeros((h * SS, w * SS, 4))
    inside = d <= 0
    arr[inside] = (13, 15, 20, 250)
    edge = (d > -1.2) & inside
    arr[edge] = (90, 98, 118, 130)
    top = inside & (y < 2.2)
    arr[top] = rgba(ACCENT, 240)
    return down(arr)


def build_logo_mark():
    """Sentinel 'S' glyph, gold on transparent."""
    w = h = 64
    im = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    font = None
    for path in ("DejaVuSans-Bold.ttf", "arialbd.ttf", "arial.ttf"):
        try:
            font = ImageFont.truetype(path, int(46 * SS))
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default(size=int(44 * SS))
    d.text((w * SS / 2, h * SS / 2), "S", font=font, fill=rgba(ACCENT),
           anchor="mm")
    im = im.resize((w, h), Image.LANCZOS)
    return np.asarray(im).astype(np.float64)


# =============================================================================
# manifest
# =============================================================================

def build_all():
    # 1. chrome / borders
    reg("PillEdge", build_pill_edge())
    reg("SquareEdge", build_square_edge())
    reg("GlowEdge", build_glow_edge(peak=0.9, sigma=5.0))
    reg("GoldEdge", build_gold_edge())
    reg("TooltipEdge", build_tooltip_edge())

    # 2. fills / surfaces
    reg("PanelFill", fill_tex(64, 64, PANEL, 245, noise_pct=0.04, seed=2))
    reg("RaisedFill", fill_tex(64, 64, RAISED, 250, noise_pct=0.04, seed=3))
    reg("InsetFill", fill_tex(64, 64, INSET, 250, noise_pct=0.03, seed=4))
    reg("Gloss", build_gloss())
    reg("Divider", build_divider())

    # 3. bars
    reg("BarFlat", build_bar_flat())
    reg("BarGloss", build_bar_gloss())
    reg("BarStriped", build_bar_striped())
    reg("BarSegment", build_bar_segment())
    reg("BarSpark", build_bar_spark())

    # 4. controls
    reg("CheckEmpty", glyph(16, 16, g_check_empty))
    reg("CheckOn", glyph(16, 16, g_check_on))
    reg("RadioOff", glyph(16, 16, g_radio_off))
    reg("RadioOn", glyph(16, 16, g_radio_on))
    reg("SliderThumb", glyph(12, 20, g_thumb))
    for name, direc in (("ArrowUp", 'up'), ("ArrowDown", 'down'),
                        ("ArrowLeft", 'left'), ("ArrowRight", 'right')):
        reg(name, glyph(12, 12, lambda d, w, h, s, di=direc: g_arrow(d, w, h, s, di)))
    reg("CloseX", glyph(14, 14, g_close))
    reg("Plus", glyph(12, 12, g_plus))
    reg("Minus", glyph(12, 12, g_minus))
    reg("DropdownArrow", glyph(16, 12, g_dropdown))
    reg("Gear", glyph(16, 16, g_gear))
    reg("Lock", glyph(14, 14, lambda d, w, h, s: g_lock(d, w, h, s, False)))
    reg("Unlock", glyph(14, 14, lambda d, w, h, s: g_lock(d, w, h, s, True)))

    # 5. frames / containers
    reg("TabNormal", build_tab(False))
    reg("TabActive", build_tab(True))
    reg("PortraitFrame", build_portrait_frame())
    reg("IconMask", build_icon_mask())
    reg("IconBorder", build_icon_border())
    reg("ButtonRing", build_button_ring())
    reg("ButtonPushed", build_button_pushed())
    reg("ButtonChecked", build_button_checked())
    reg("Cooldown", build_cooldown())

    # 6. unit frames / heal UI
    reg("UFBackdrop", build_uf_backdrop())
    reg("HealthFill", flat(64, 8, w_rgba(255)))
    reg("PowerFill", flat(64, 8, w_rgba(255)))
    reg("AltPowerFill", flat(64, 8, w_rgba(255)))
    reg("AbsorbBar", build_absorb())
    reg("IncomingHeal", build_incoming_heal())
    reg("CastBg", build_cast_bg())
    reg("CastShield", glyph(16, 16, g_cast_shield))
    reg("ThreatGlow", build_glow_edge(peak=1.0, sigma=5.5))
    reg("TargetRing", build_target_ring())
    reg("RangeFade", build_range_fade())
    reg("ResIcon", glyph(32, 32, g_res))
    reg("DeadIcon", glyph(16, 16, g_skull))
    reg("BossSkull", glyph(16, 16, g_skull))
    reg("OfflineIcon", glyph(16, 16, g_offline))
    reg("RestingIcon", glyph(16, 16, g_resting))
    reg("CombatIcon", glyph(16, 16, g_combat))
    reg("LeaderIcon", glyph(16, 16, g_leader))
    reg("MasterLootIcon", glyph(16, 16, g_master_loot))
    reg("ReadyCheck", glyph(16, 16, g_ready))
    reg("EliteBorder", build_elite_border())
    reg("GroupHeader", build_group_header())
    reg("RoleTank", glyph(16, 16, g_role_tank))
    reg("RoleHeal", glyph(16, 16, g_role_heal))
    reg("RoleDps", glyph(16, 16, g_role_dps))
    reg("DispelMagic", glyph(16, 16, g_dispel_magic))
    reg("DispelCurse", glyph(16, 16, g_dispel_curse))
    reg("DispelDisease", glyph(16, 16, g_dispel_disease))
    reg("DispelPoison", glyph(16, 16, g_dispel_poison))

    # 7. backgrounds / structure
    reg("TitleBar", build_title_bar())
    reg("RowHover", build_row_hover())
    reg("RowSelect", build_row_select())
    reg("SlotBg", build_slot_bg())
    reg("ScrollInset", build_scroll_inset())
    reg("MoverGrid", build_mover_grid())
    reg("DataBarXP", flat(64, 8, w_rgba(255)))
    reg("DataBarRep", flat(64, 8, w_rgba(255)))
    reg("Backplate", build_backplate())

    # 8. suite furniture
    reg("MinimapBorder", build_minimap_border())
    reg("ActionBarBg", build_actionbar_bg())
    reg("MicroBarBg", build_microbar_bg())
    reg("ChatTab", build_chat_tab(False))
    reg("ChatTabActive", build_chat_tab(True))
    reg("EditboxBg", build_editbox_bg())
    reg("TrackerRow", build_tracker_row())
    reg("PanelButtonBg", build_panel_button())
    reg("ToastBg", build_toast_bg())
    reg("LogoMark", build_logo_mark())


# -----------------------------------------------------------------------------
# contact sheet

def contact_sheet():
    bg = (11, 13, 18, 255)
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 11)
    except OSError:
        font = ImageFont.load_default()

    cells = []
    for name, w, h, arr in A:
        s = 1 if max(w, h) >= 96 else (3 if min(w, h) <= 20 else 2)
        im = Image.fromarray(np.clip(arr + 0.5, 0, 255).astype(np.uint8),
                             'RGBA').resize((w * s, h * s), Image.NEAREST)
        cells.append((name, im))

    sheet_w = 1360
    cell_h = 104
    x = 8
    y = 8
    rows = [[]]
    for name, im in cells:
        cw = max(im.width + 16, 96)
        if x + cw > sheet_w:
            rows.append([])
            x = 8
            y += cell_h
        rows[-1].append((name, im, x, cw))
        x += cw

    sheet_h = y + cell_h + 8
    sheet = Image.new('RGBA', (sheet_w, sheet_h), bg)
    d = ImageDraw.Draw(sheet)
    yy = 8
    for row in rows:
        for name, im, cx, cw in row:
            sheet.alpha_composite(im, (cx + (cw - im.width) // 2,
                                       yy + (76 - im.height) // 2))
            d.text((cx + cw / 2, yy + 84), name, font=font,
                   fill=(140, 146, 163, 255), anchor="ma")
        yy += cell_h
    sheet.save(SHEET_FILE)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    build_all()
    for name, w, h, arr in A:
        save(name, arr)
    contact_sheet()
    print(f"wrote {len(A)} assets "
          f"({len(A) * 2} files + contact sheet) -> {OUT_DIR}")


if __name__ == "__main__":
    main()
