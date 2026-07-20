<p align="center">
  <img src="branding_logo_lockup_google.png" alt="bytemail" width="360" />
</p>

# ByteMail branding concepts

Operator-locked color tokens and visual concepts for Final-wave packaging. **Wired** into Windows `.ico`, Android adaptive launcher, notification mono, and minimal Android splash (Final wave Phase A, 2026-07-18).

**Product web page:** static site + mothership strategy live in sibling [`../../../LiveBytes`](../../../LiveBytes) (`website/` → `https://livebytes.net/bytemail/`). See [`../POST_V1_LIVEBYTES_WEB_STRATEGY.md`](../POST_V1_LIVEBYTES_WEB_STRATEGY.md) (stub) and LiveBytes `docs/`.

## Color tokens (locked)

| Token | Hex | Role |
| --- | --- | --- |
| Muted Quartz | `#E0AAFF` | Option A `BYTE` (archive) |
| Teal Cyan | `#00B4D8` | Option A `mail`; icon flap; gradient end |
| Electric Amethyst | `#7B2CBF` | Icon panels; gradient start; adaptive launcher background |
| Transition blue | `#3A7BD5` | Gradient mid |
| Deep obsidian | `#0B0B12` | Android splash background |

## Wordmark status

| Option | Status | Notes |
| --- | --- | --- |
| **B — Stealth Lowercase** | **LOCKED + wired** | Continuous `bytemail`; glyph gradient `#7B2CBF` → `#3A7BD5` → `#00B4D8`. In-app title-bar via `BytemailWordmark`. |
| A — Structural Capitalization | Archive / alternate | Bold `BYTE` (`#E0AAFF`) + italic `mail` (`#00B4D8`). Keep on file; not shipping default. |

## Icon status

| Variant | Status | Notes |
| --- | --- | --- |
| **v2 — Data Envelope (refined geometry)** | **LOCKED + wired** | Production launcher / taskbar mark. Source: [`branding_icon_data_envelope_v2.png`](branding_icon_data_envelope_v2.png). Exported to Windows `.ico` + Android adaptive / splash / notification mono. |
| v1, v3–v5 | Archive / alternates | Keep on file for reference; not shipping default. |

## Logo lockup (icon + wordmark)

| File | Use |
| --- | --- |
| [`branding_logo_lockup_icon_wordmark.png`](branding_logo_lockup_icon_wordmark.png) | Full-res concept lockup (~1.1 MB) |
| [`branding_logo_lockup_google.png`](branding_logo_lockup_google.png) | **Google OAuth / Cloud branding** — same lockup, compressed under 1 MB (~526 KB). Also used in **documentation headers** (root README, primary `docs/*.md` guides) at ~360 px width for GitHub and local preview. |
| [`branding_icon_data_envelope_v2.png`](branding_icon_data_envelope_v2.png) | Square mark if the form wants icon-only (~844 KB) |

## Splash (locked)

| Platform | Decision | Notes |
| --- | --- | --- |
| **Android** | **Minimal splash only — wired** | Obsidian `#0B0B12` + centered Data Envelope v2. `drawable/launch_background.xml` + Android 12 SplashScreen API (`values-v31/styles.xml`). |
| **Windows** | **Skip native splash** | Relies on `.ico` + wordmark B; no dedicated Windows splash screen. |

**Dismiss policy:** No artificial delay — Flutter removes the launch theme when the first frame paints (`LaunchTheme` → `NormalTheme`).

## Production wire-up (Final wave Phase A) — landed 2026-07-18

| Surface | Path / notes |
| --- | --- |
| Windows `.ico` | `windows/runner/resources/app_icon.ico` (16–256 multi-size from v2) |
| Android adaptive | `mipmap-anydpi-v26/ic_launcher.xml` + density foregrounds; background `#7B2CBF` |
| Notification mono | `drawable-*/ic_stat_bytemail.png`; Dart uses `@drawable/ic_stat_bytemail` |
| Android splash | Obsidian + centered v2; first-frame dismiss; **no** Windows splash |
| In-app wordmark | `lib/ui/branding/bytemail_wordmark.dart` in title bar |

Do not ship Flutter defaults — packaged builds use Data Envelope v2.

Assets were generated with Python/Pillow from the locked v2 PNG (manual export; `flutter_launcher_icons` / `flutter_native_splash` not required for V1).

## Concept set (2026-07-18)

### Wordmarks

| File | Caption |
| --- | --- |
| [`branding_wordmark_option_b.png`](branding_wordmark_option_b.png) | **Option B — Stealth Lowercase (LOCKED):** continuous `bytemail` in a Space Grotesk–like face; glyph gradient `#7B2CBF` → `#3A7BD5` → `#00B4D8`. |
| [`branding_wordmark_option_a.png`](branding_wordmark_option_a.png) | **Option A — Structural Capitalization (archive):** bold geometric `BYTE` (`#E0AAFF`) + lighter italic `mail` (`#00B4D8`) on obsidian. |

### Data Envelope icons

| File | Caption |
| --- | --- |
| [`branding_icon_data_envelope.png`](branding_icon_data_envelope.png) | **v1 — Original (archive):** cyan luminous top flap + overlapping amethyst geometric panels. |
| [`branding_icon_data_envelope_v2.png`](branding_icon_data_envelope_v2.png) | **v2 — Refined geometry (LOCKED):** sharper overlapping panels; stronger cyan “incoming data” glow on detached top flap; subtler amethyst / blue base. |
| [`branding_icon_data_envelope_v3.png`](branding_icon_data_envelope_v3.png) | **v3 — Adaptive flat (archive):** 2–3 shape silhouette; cyan flap + solid amethyst body; crisp at 48px / Android adaptive. |
| [`branding_icon_data_envelope_v4.png`](branding_icon_data_envelope_v4.png) | **v4 — Isometric stack (archive):** cyan / amethyst / transition-blue stacked plates with envelope flap cue. |
| [`branding_icon_data_envelope_v5.png`](branding_icon_data_envelope_v5.png) | **v5 — Crystal wild card (archive):** faceted / crystal-cut envelope pocket + circuit-chevron data insert. |

### Header mockups

| File | Caption |
| --- | --- |
| [`branding_header_mockup_b.png`](branding_header_mockup_b.png) | Desktop chrome with **locked** Option B gradient `bytemail`. |
| [`branding_header_mockup_a.png`](branding_header_mockup_a.png) | Same chrome with Option A wordmark (archive reference). |

Earlier exploratory icons (`branding_concept_*`, `branding_wordmark_concept.png`) are superseded for the production decision path; keep only if useful for archive.

## Operator decisions (locked)

1. ~~Pick wordmark A or B~~ → **B locked** (stealth lowercase `bytemail`).
2. ~~Confirm Data Envelope variant~~ → **v2 locked**.
3. ~~Splash approach~~ → **Minimal Android only** (obsidian/jewel + centered icon v2; first-frame dismiss; no artificial delay). **Skip Windows splash** (`.ico` + wordmark suffice).
4. ~~Wire locked wordmark B + icon v2 + Android splash~~ → **Done** (Final wave Phase A, 2026-07-18).
5. Do not ship Flutter defaults once the icon is wired.
