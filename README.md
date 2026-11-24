# Project Mirai DX — 60 FPS + variable tick rate for Zakuro

> [!WARNING]
> **These patches are very experimental.** They were reverse-engineered on one game build
> (USA, CTR-P-BRXE) and validated on one machine. Locate your saves before trying custom
> frame rates, and report anything odd. **Contributions are very welcome** — see
> [Contributing](#contributing).

IPS patches and an emulator overlay for [Zakuro](https://github.com/fearkov/zakuro)
that unlock **Hatsune Miku: Project Mirai DX (USA)** beyond its 30 fps cap:

- **60 fps at correct game speed** — one IPS patch, works on any Zakuro build
- **camera-cut fix** — no blended/ghosted frame when the PV camera cuts
- **variable tick rate** (90 / 120 / ...) via an emulator-side `refresh_scale` setting
- **low-latency present mode** (`ZAKURO_PRESENT_MODE=immediate`, `ZAKURO_SWAP_INTERVAL=0`)

## Requirements

- A **legally owned copy** of *Hatsune Miku: Project Mirai DX (USA)* (CTR-P-BRXE)
- [Zakuro](https://github.com/fearkov/zakuro)
- For more than 60 fps: a Zakuro build with the bundled overlay applied (see below)

## Install — 60 fps

### Windows
Double-click `install.cmd` (or run it from a terminal). It copies the IPS to
`%APPDATA%\zakuro\mods\0004000000148C00\code.ips` and verifies it.

### Linux
```sh
./install.sh
```
Installs the IPS to `~/.local/share/zakuro/mods/0004000000148C00/code.ips`.

## Install — 60+ fps (90 / 120 / ...)

The 60 fps IPS alone can never exceed ~60 fps: the emulator's own frame pacing caps it.
Two more pieces are needed, both bundled here:

1. **Emulator overlay** — a `git` patch against Zakuro `fdf67b2` adding a
   `refresh_scale` setting (per-second vblank rate multiplier) and a low-latency
   present mode:

   ```sh
   git clone https://github.com/fearkov/zakuro
   cd zakuro && git checkout fdf67b29b6398a7ad0dc2309b09ea4c03c45e9d8
   git apply /path/to/zakuro/zakuro-mirai-enhancements.patch
   cargo build --release
   ```

2. **A matching IPS** — generated for any target rate by
   `python tools/make-fps-ips.py <fps>` (writes `patches/mirai-<fps>fps.ips`).

3. **Pair them**: in `%APPDATA%\zakuro\settings.toml` (Linux:
   `~/.config/zakuro/settings.toml`) set, in the top-level section,
   `refresh_scale = <fps> / 59.8281` (120 → `2.005642`, 90 → `1.504231`).
   The placement matters: top level, not inside `[per_game]`.

`switch-patch.ps1` (Windows) automates the pairing: `-Variant fps -Fps 120` builds +
installs both halves; `-Variant v3` returns to the tested 60 fps configuration.

## Low-latency mode

Set before launching (or use the bundled `launch\run-mirai-lowlatency.cmd`):

```
ZAKURO_PRESENT_MODE=immediate   # fifo (default) | mailbox | immediate
ZAKURO_SWAP_INTERVAL=0          # GL path: never fence the swap
```

## Troubleshooting

- **Game runs fast/slow** — the IPS and `refresh_scale` mismatch. A song's notes stay on
  the music, but the picture, HUD and animations run at the wrong rate. Re-pair them or
  go back to `-Variant v3`.
- **The game doesn't boot / black window** — never run two Zakuro instances on one ROM;
  they fight over the save file.
- **Speed is fine, cut scenes flicker** — you're on plain v1/v2; move to v3.

## Legal

Not affiliated with SEGA, UNiSON SHIFT, Nintendo, or the Hatsune Miku Project. This repo
contains no game data — the IPS files are small code patches and must be applied to a
 RomFS image of a **legally owned copy** of the game.

## Contributing

**This is very experimental** — one game build, one machine, one tester so far. Whether
it's more fps values, other game regions (EU/JP), faster paths, or fixes to the open
animation-timing questions in the findings notes: **contributions are very welcome.**
Open an issue or PR. Please keep game data out of the repo.

## Credits

- [Zakuro](https://github.com/fearkov/zakuro) by fearkov (MIT) — the emulator, and the
  bundled emulator-side enhancements
- Patches and tooling: Kuro3901 (MIT)
