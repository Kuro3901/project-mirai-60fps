# Build patches/mirai-<fps>fps.ips: the v3-camera 60 fps patch rescaled to any target fps N.
#
# The 60 fps patch (make-60fps-v2-ips.py + v3 camera floor, both kept outside this repo) is built from data that
# scales linearly in the tick rate, because the engine is tick-driven end to end (findings
# section 13). Stock is 30 ticks/s; at N ticks/s every per-tick step scales by 30/N:
#
#   0x002ED4C4  stock 30.0f  -> 900.0/N   (layout/UI per-tick step; 15.0f at 60)
#   0x0032DCBC  stock  1.0f  ->  30.0/N   (AnimFrameCtrl::Step cur += step * this; 0.5f at 60)
#
#   0x0010DBC8  bne -> b      unchanged: one vblank wait per pass (the IPS side),
#                             the vblank RATE itself comes from the emulator's
#                             %APPDATA%\zakuro\settings.toml refresh_scale = N/59.83
#
# The 3e-5 cut-sync constants stay untouched (halving them breaks cut sync, see the
# v2 notes). The v3 camera-floor cave is tick-rate agnostic (it samples fcurves at
# integers, which is exact stock sampling at any tick rate).
#
# usage: python tools/make-fps-ips.py 120 [--base patches/mirai-60fps-v3-camera.ips]

import argparse
import os
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

STEP_VA = 0x002ED4C4     # stock 30.0f (0x41F00000)
MULT_VA = 0x0032DCBC     # stock 1.0f carried in the 60fps patch as 0.5f (0x3F000000)
BASE_VA = 0x00100000     # IPS offsets index the mapped image, VA - BASE_VA

def parse_ips(data):
    recs, i = [], 5
    while i + 3 <= len(data) and data[i:i + 3] != b"EOF":
        off = int.from_bytes(data[i:i + 3], "big"); i += 3
        ln = int.from_bytes(data[i:i + 2], "big"); i += 2
        recs.append((off, data[i:i + ln])); i += ln
    assert data[i:i + 3] == b"EOF", "no IPS EOF marker"
    return dict(recs), recs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("fps", type=int)
    ap.add_argument("--base", default=os.path.join(ROOT, "patches", "mirai-60fps-v3-camera.ips"))
    args = ap.parse_args()
    n = args.fps
    assert n >= 30, "only unlocks: N must be >= 30"

    recs, _ = parse_ips(open(args.base, "rb").read())

    # the base must be the N=60 tuning: 15.0f / 0.5f
    assert recs[STEP_VA - BASE_VA] == struct.pack("<f", 15.0), \
        "base is not the 60 fps tuning at %08X: %r" % (STEP_VA, recs[STEP_VA - BASE_VA])
    assert recs[MULT_VA - BASE_VA] == struct.pack("<f", 0.5), \
        "base is not the 60 fps tuning at %08X: %r" % (MULT_VA, recs[MULT_VA - BASE_VA])

    recs[STEP_VA - BASE_VA] = struct.pack("<f", 900.0 / n)
    recs[MULT_VA - BASE_VA] = struct.pack("<f", 30.0 / n)

    out = bytearray(b"PATCH")
    for off in sorted(recs):
        data = recs[off]
        out += off.to_bytes(3, "big") + len(data).to_bytes(2, "big") + data
    out += b"EOF"

    path = os.path.join(ROOT, "patches", "mirai-%dfps.ips" % n)
    open(path, "wb").write(out)
    print("wrote", path, len(out), "bytes,", len(recs), "records")
    print("  %08X -> %s (%.4f)   [was 15.0]" % (STEP_VA, struct.unpack('<f', recs[STEP_VA - BASE_VA])[0], 900.0 / n))
    print("  %08X -> %s (%.4f)   [was 0.5]" % (MULT_VA, struct.unpack('<f', recs[MULT_VA - BASE_VA])[0], 30.0 / n))
    print("pair with %%APPDATA%%\\zakuro\\settings.toml refresh_scale = %.6f (n / 59.83122)" % (n / (268111856.0 / 4481136.0)))

if __name__ == "__main__":
    main()
