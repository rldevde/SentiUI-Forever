#!/usr/bin/env python3
"""Regenerate the edgeFile border textures with a CORRECT 8-slice layout.

WoW edgeFile spec (landscape file, 128x16, edgeSize 16): the file is cut
into 8 equal vertical slices of 16px each:
    slice 0 = LEFT edge      slice 1 = RIGHT edge
    slice 2 = TOP edge       slice 3 = BOTTOM edge
    slice 4 = TOPLEFT        slice 5 = TOPRIGHT
    slice 6 = BOTTOMLEFT     slice 7 = BOTTOMRIGHT

The side slices stretch along their frame edge; the corner slices render
1:1. The border line must sit at the OUTER edge of each slice so the
corner arcs meet the side lines at the shared slice boundaries.

The AI-generated files had a squashed full ring in slice 0, empty side
slices and diagonal bracket arcs in the corner slices - they render as a
fat band on one side plus open corner stubs. This script writes proper
uncompressed 32bpp BGRA TGAs (top-left origin), 4x supersampled for real
anti-aliased coverage.
"""

import struct, os, math

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "Media", "Textures")

W, H = 128, 16
SL = 16          # slice width/height
SS = 4           # supersample factor

GOLD = (235, 173, 51)
WHITE = (255, 255, 255)


def coverage_line(dist, thick):
    """Alpha for a border line `thick` px wide measured from the frame
    edge inward, with ~1px of anti-alias falloff on the inner side.
    dist<0 is outside the frame (corner slices only) - transparent."""
    if dist < 0:
        return 0.0
    return max(0.0, min(1.0, thick - dist + 0.5))


def coverage_glow(dist, width):
    """Soft glow band: strong at the frame edge, fading inward.
    dist<0 is outside the frame - transparent."""
    if dist < 0:
        return 0.0
    t = max(0.0, 1.0 - dist / width)
    return t * t * (3.0 - 2.0 * t)  # smoothstep falloff


def edge_distance(x, y, kind, R):
    """Distance from the frame's outer-edge path inside one 16px slice.

    x,y are sample coords within the slice (0..16, y grows downward,
    slice top = frame top for the top row, bottom = frame bottom for
    bottom slices - i.e. we compute each corner in its own frame).
    kind: 'L','R','T','B','TL','TR','BL','BR'.
    Returns distance to the border path; the caller maps it to alpha.
    """
    if kind == "L":
        return x
    if kind == "R":
        return SL - x
    if kind == "T":
        return y
    if kind == "B":
        return SL - y
    # corners: mirror everything into TL orientation first
    cx, cy = x, y
    if kind in ("TR", "BR"):
        cx = SL - x
    if kind in ("BL", "BR"):
        cy = SL - y
    # TL layout: vertical stub x in [0,t) for y>=R, horizontal stub
    # y in [0,t) for x>=R, quarter annulus (center R,R, radius R) for
    # the x<R,y<R quadrant; interior (x>R,y>R) is empty.
    if cx >= R and cy >= R:
        return 1e9
    if cx <= R and cy <= R:
        # distance to the outer arc (outer radius R around center R,R)
        d = math.hypot(R - cx, R - cy)
        return R - d
    if cy >= R:
        return cx          # left vertical stub
    return cy              # top horizontal stub


def render(path, rgb, thick=1.5, R=7.0, glow=None):
    """Write a 128x16 BGRA TGA. `glow` = inner band width for the soft
    glow style (None -> hard `thick` px line)."""
    kinds = ("L", "R", "T", "B", "TL", "TR", "BL", "BR")
    px = bytearray(W * H * 4)
    r, g, b = rgb
    for sy in range(H):
        for sx in range(W):
            sl = sx // SL
            kind = kinds[sl]
            lx, ly = sx - sl * SL, sy
            acc = 0.0
            for iy in range(SS):
                for ix in range(SS):
                    x = lx + (ix + 0.5) / SS
                    y = ly + (iy + 0.5) / SS
                    d = edge_distance(x, y, kind, R)
                    acc += (coverage_glow(d, glow) if glow
                            else coverage_line(d, thick))
            a = int(round(acc / (SS * SS) * 255))
            i = (sy * W + sx) * 4
            px[i:i + 4] = bytes((b, g, r, a))
    hdr = bytearray(18)
    hdr[2] = 2                        # uncompressed true-color
    hdr[12:14] = struct.pack("<H", W)
    hdr[14:16] = struct.pack("<H", H)
    hdr[16] = 32
    hdr[17] = 0x28                    # top-left origin + 8 alpha bits
    with open(path, "wb") as fh:
        fh.write(bytes(hdr) + bytes(px))
    print("wrote", path)


def main():
    os.makedirs(HERE, exist_ok=True)
    # shared chrome borders: thin white line, tint comes from the code
    render(os.path.join(HERE, "PillEdge.tga"), WHITE, thick=1.6, R=7)
    render(os.path.join(HERE, "SquareEdge.tga"), WHITE, thick=1.6, R=2)
    render(os.path.join(HERE, "TooltipEdge.tga"), WHITE, thick=1.6, R=5)
    # authored-gold rings
    render(os.path.join(HERE, "GoldEdge.tga"), GOLD, thick=1.6, R=7)
    render(os.path.join(HERE, "TargetRing.tga"), GOLD, thick=2.4, R=9)
    # soft glow rings (threat/dispel highlight)
    render(os.path.join(HERE, "ThreatGlow.tga"), WHITE, glow=13, R=9)
    render(os.path.join(HERE, "GlowEdge.tga"), WHITE, glow=13, R=9)


if __name__ == "__main__":
    main()
