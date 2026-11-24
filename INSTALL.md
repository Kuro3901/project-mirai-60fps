# INSTALL.md — agent-friendly install runbook

Step-by-step instructions for installing the 60 fps / variable-tick-rate patches for
**Hatsune Miku: Project Mirai DX (USA)** (CTR-P-BRXE) under [Zakuro]. Written so a
human *or* an automation agent can follow it without guesswork: exact paths, exact
commands, machine-checkable verification, and rollback.

> **Legal precondition.** The patches must be applied to a **legally owned** copy of the
> game. This repo contains no game data, and nothing in it downloads or processes ROMs.
> An agent must not offer to obtain the game.

## 1. Collect inputs

| input | values / source |
|---|---|
| OS | `windows` or `linux` — picks the data dirs below |
| target fps | `60` (Path A, simplest, best tested) or `90` / `120` / ... (Path B) |
| ROM | the user's own `Hatsune Miku - Project Mirai DX (USA).cci` (title ID `0004000000148C00`) |
| Zakuro | a stock release build (fine for Path A) or a source build (required for Path B) |
| repo root | path of this checkout; commands below run from it unless stated |

**Data dirs**

| OS | mods dir (patch target) | settings.toml |
|---|---|---|
| Windows | `%APPDATA%\zakuro\mods\0004000000148C00\` | `%APPDATA%\zakuro\settings.toml` |
| Linux | `${XDG_DATA_HOME:-$HOME/.local/share}/zakuro/mods/0004000000148C00/` | `~/.config/zakuro/settings.toml` |

The installed file is always `<mods dir>/code.ips`. Zakuro loads it as a code patch for
that title ID only — saves and other games are not affected.

## 2. Pick a path

- **Path A — 60 fps**: copy one IPS into the mods dir. Works on **any** Zakuro build,
  stock or patched. No settings change. This is what `install.cmd` / `install.sh` do.
- **Path B — 60+ fps** (`90` / `120` / ...): build the patched emulator (bundled
  overlay), generate a matching IPS, and set `refresh_scale` in `settings.toml`. The
  IPS and `refresh_scale` are a **pair** — a mismatch makes the whole game run
  fast/slow (a song's notes stay on the music, but picture, HUD and animations drift).
- Optional with either path: low-latency present mode (§5).

## 3. Path A — 60 fps (v3 camera patch)

**Windows** — double-click `install.cmd`, or from a terminal:

```bat
cd <repo root>
install.cmd
```

raw equivalent:

```bat
copy /y "patches\mirai-60fps-v3-camera.ips" "%APPDATA%\zakuro\mods\0004000000148C00\code.ips"
```

**Linux**:

```sh
cd <repo root>
./install.sh
```

raw equivalent:

```sh
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zakuro/mods/0004000000148C00"
cp patches/mirai-60fps-v3-camera.ips "${XDG_DATA_HOME:-$HOME/.local/share}/zakuro/mods/0004000000148C00/code.ips"
```

No `settings.toml` change is needed for Path A. Launch Zakuro with the ROM.

If Zakuro recompiles this game ahead of time (AOT), recompile it once **after** the
patch is installed (Zakuro menu → *Recompile*), so the patched code runs at full speed;
the patched parts otherwise fall back to the interpreter.

## 4. Path B — 60+ fps

### B1 — build the patched emulator

```sh
git clone https://github.com/fearkov/zakuro
cd zakuro
git checkout fdf67b29b6398a7ad0dc2309b09ea4c03c45e9d8
git apply <repo root>/zakuro-mirai-enhancements.patch   # tip: --check first
cargo build --release
```

Needs Rust 1.95+; on Linux also pkg-config and the ALSA/udev dev headers (see the
Zakuro README). The overlay adds the `refresh_scale` setting and the low-latency
present mode. A stock Zakuro build caps at ~60 fps regardless of the IPS.

### B2 — generate the IPS for the target rate

```sh
cd <repo root>
python tools/make-fps-ips.py 120        # writes patches/mirai-120fps.ips
```

Python 3, `fps >= 30`.

### B3 — install it

Copy `patches/mirai-<fps>fps.ips` to `<mods dir>/code.ips` (same as Path A).

### B4 — pair `refresh_scale` in settings.toml

`refresh_scale = <fps> / (268111856 / 4481136)` (= `<fps> / 59.83122`), rounded to
6 decimals:

| fps | refresh_scale |
|---|---|
| 60 | 1.002821 |
| 90 | 1.504231 |
| 120 | 2.005642 |

**Placement matters**: top-level of the file, **not** inside `[per_game]`. If it lands
in a game's table, zakuro fails to parse it, silently falls back to `1.0`, and the game
runs at the wrong speed. Concretely: put the line before the first `[section]` header.

Safe procedure (what `switch-patch.ps1` does): back up `settings.toml` → remove any
existing `refresh_scale =` line → insert the new value before the first `[` line →
validate that the file still parses:

```sh
python -c "import tomllib; tomllib.load(open('<settings.toml>','rb')); print('ok')"
```

(Python 3.11+ for `tomllib`.) If validation fails, restore the backup — never leave a
broken `settings.toml` in place.

**Windows shortcut** — B2 + B3 + B4 automated, with backup, validation and rollback:

```powershell
powershell tools\switch-patch.ps1 -Variant fps -Fps 120
```

### B5 — launch the patched build

Point your launcher at the patched `zakuro` binary and the ROM. The bundled
`run-mirai.cmd` / `run-mirai-lowlatency.cmd` assume the build at
`zakuro\target\release\zakuro.exe` and the `.cci` beside the repo root — edit them if
your layout differs.

## 5. Low-latency mode (optional, both paths)

```
ZAKURO_PRESENT_MODE=immediate   # fifo (default) | mailbox | immediate
ZAKURO_SWAP_INTERVAL=0          # GL path: never fence the swap
```

Windows: run `run-mirai-lowlatency.cmd`. Expect tearing on fast pans; pacing still
follows the console clock.

## 6. Verification (machine-checkable)

1. `<mods dir>/code.ips` exists and matches the IPS it was copied from, byte for byte:

```sh
sha256sum "<mods dir>/code.ips"
```

Shipped IPS files (256-bit SHA):

| file | records | sha256 |
|---|---|---|
| `mirai-60fps-v3-camera.ips` (default) | 20 | `e57fdb749bbb246a2f861d971262f3e2151560347db709f51326ba0548abf718` |
| `mirai-60fps-minimal.ips` (prototype) | 2 | `2684e3f7c69dd3cdead86fd3d53e771e69506970878e56f826ab8e43d2ee3289` |
| `mirai-60fps-prototype-v1.ips` (prototype) | 11 | `2c10414543b5ac1f6423c162a27ed1384800b0189aa8d320eb2b9cc0b97f2212` |
| `mirai-60fps-prototype-v2.ips` (prototype) | 12 | `6efac80509beff65d47d9f8fad5bf12c8ccdf97861bce7afc4892dd7146fadc3` |

Generated `patches/mirai-<fps>fps.ips`: compare the installed file against the copy in
`patches/`. Every IPS starts with `PATCH` and ends with `EOF`:

```sh
python3 -c "d=open('<mods dir>/code.ips','rb').read(); assert d[:5]==b'PATCH' and d[-3:]==b'EOF'"
```

2. Path B only: `settings.toml` parses (tomllib one-liner above) and `refresh_scale`
   sits before the first `[` header.
3. In game: a song's notes stay on the music, and picture/HUD/animation speed is right
   (≈ target fps). Notes fine but overall speed wrong ⇒ §8, row 1.

## 7. Rollback

- **Patch**: delete `<mods dir>/code.ips`
  (Windows: `powershell tools\switch-patch.ps1 -Variant off`).
- **Settings**: restore `settings.toml.bak`, or set `refresh_scale = 1.0`, or delete
  the line.
- The patched emulator build is harmless on its own — the knob defaults to `1.0`.
- Back to the tested 60 fps config: `powershell tools\switch-patch.ps1 -Variant v3`.

## 8. Troubleshooting

| symptom | cause | fix |
|---|---|---|
| game runs fast/slow overall (notes stay on the music) | IPS and `refresh_scale` mismatch | re-pair (§4 B4 table), or `switch-patch.ps1 -Variant v3` |
| no boot / black window | a second Zakuro instance is already running this ROM (they fight over the save) | close every instance, relaunch — never run two |
| speed fine but cutscenes flicker/ghost | an old prototype patch (v1/v2/minimal) is installed | install v3 |
| fps never exceeds ~60 | the stock/unpatched emulator caps at its own frame pacing | do §4 B1, then re-pair |

## 9. Agent notes / gotchas

- **Never run two Zakuro instances on the same ROM** — save-file conflict.
- `patches/mirai-<fps>fps.ips` is a generated artifact — don't commit it. Keep game
  data (ROM, dumps, extracted files) out of the repo entirely.
- Stay inside the mods dir and `settings.toml`; nothing else on the user's system
  needs to change. Back up `settings.toml` before edits, validate after.
- `tools/switch-patch.ps1` variants: `v3` = tested default, `off` = uninstall,
  `minimal` / `v1` / `v2` = shipped prototypes (comparison only), `fps` = custom-rate
  pairing. It derives the repo root from its own location, so it runs from anywhere.
- Windows launchers (`run-mirai*.cmd`) expect `zakuro\target\release\zakuro.exe` and
  the game's `.cci` beside the repo root; edit the paths for other layouts.
- Repo contents at a glance: `patches/*.ips` = code patches (tiny, no game data) ·
  `tools/make-fps-ips.py` = rate-specific IPS generator · `tools/switch-patch.ps1` =
  Windows installer/pairer · `install.cmd` / `install.sh` = Path A installers ·
  `run-mirai*.cmd` = launchers · `zakuro-mirai-enhancements.patch` = emulator overlay
  against Zakuro `fdf67b2`.
