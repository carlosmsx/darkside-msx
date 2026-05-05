# Dark Side of the Moon — MSX ROM

A tribute to **Pink Floyd's The Dark Side of the Moon** (1973), written entirely in **Z80 assembly** for MSX computers.

By **Carlos Escobar** (CarlosMSX) · 2025

---

## What it does

- Displays a **SCREEN 2 (Graphics 2)** scene with the iconic prism artwork, album title, and credits
- Plays a **3-channel PSG melody** (AY-3-8910) using a custom music engine with per-note envelope control, pitch adjustment, sustain, and noise
- Animates a **starfield** of 20 sprites expanding outward from the screen center, each with randomized direction and age-based pattern scaling
- All interactive — keyboard controls let you tweak audio parameters in real time (pitch, sustain, noise, envelope evolution speed)

## Files

| File | Description |
|------|-------------|
| `darkside.asm` | Main source: ROM header, music engine, starfield, graphics init |
| `notas.asm` | Note frequency constants for Z80 (C0–B6, sharps and flats) |
| `prisma.asm` | Binary pixel data for the prism graphic (VRAM tile layout) |
| `darkside.bat` | Build script (Windows) |
| `TASM80.TAB` | TASM instruction table for Z80 |

## Building

Requires **Telemark Assembler (TASM) v3.2** on Windows:

```bat
darkside.bat      :: assembles and produces darkside.rom
```

The build script runs:
```
tasm -80 -i -g3 darkside.asm
```
then renames `darkside.obj` → `darkside.rom`.

The ROM is always padded to exactly **16 KB** using the `RomSize(16)` macro.

## Running

Load `darkside.rom` in any MSX emulator that supports ROM cartridges. Tested on **openMSX**.

- The ROM installs itself via the standard MSX BIOS hook mechanism (slot `0FD9Fh`)
- It runs entirely from ROM at address `4000h`
- RAM usage: `8000h`–`8106h` (audio state, starfield table, sprite buffer, PRNG seed)

## Keyboard controls (during playback)

| Key | Action |
|-----|--------|
| `q` / `a` | Pitch up / down |
| `w` / `s` | Sustain up / down |
| `e` / `d` | Noise up / down |
| `r` / `f` | Envelope evolution speed up / down |
| `Space` | Toggle starfield on / off |

## Technical notes

**Music engine** — tick-based, hooked into the MSX interrupt via `RST 30h`. Each channel (A, B, C of the PSG) has an independent state block tracking: current note pointer, duration counter, envelope table pointer, frequency registers, pitch offset, and volume register. Seven envelope curves (`EVOL0`–`EVOL6`) shape each note's amplitude over time.

**Starfield** — 20 sprites managed in RAM (`STAR_TABLE`). Each star carries position (Y, X), velocity (DX, DY), and an age counter. On reaching `MAX_AGE` (40 ticks) a star resets to the screen center and picks a new direction from a 16-entry direction table using a Galois LFSR PRNG seeded from the Z80's `R` register at boot.

**Graphics** — SCREEN 2 (256×192, 16 colors). The prism and text are written directly to VRAM via BIOS routines (`LDIRVM`, `WRTVRM`, port 98h/99h). Font tiles are copied from the MSX BIOS ROM character generator.

## License

MIT — see [LICENSE](LICENSE).

> *"The music is reversible, but time is not."* — Pink Floyd
