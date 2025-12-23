## BstocK Brand Identity

### Logo Concept — “Funnel & Bin” Monogram
- **Visual:** A downward “V” (input flow) above a rounded “M” (storage bin).
- **Hidden meaning:** Rotating 90° suggests the letters **B** and **K**.
- **Spacing:** Keep a clear gap between the V and M to preserve the funnel feel.

### Color Palette
- **Light mode (docs/web/print)**
  - V (Vibrant Blue): `#0EA5E9`
  - M (Deep Indigo): `#322B8C`
  - Background: `#FBFBFF` (or `#FFFFFF`)
- **Dark mode (app icon/splash)**
  - V (Sky Blue): `#63D3FF`
  - M (Soft Lavender): `#CFD4FF`
  - Background: `#0F1426`

### Usage Rules
- Use high-contrast pairs:
  - On light backgrounds, use the Indigo M + Vibrant Blue V.
  - On dark backgrounds, use the Lavender M + Sky Blue V.
- Avoid placing the Lavender M on white/light backgrounds; swap to Indigo there.
- Maintain the gap between V and M; don’t merge the shapes.
- Preserve rounded terminals to match the app’s 14–16px UI radii.

### Implementation Notes
- App theme alignment: The values above match `AppColorSchemes` (light: `primary 0xFF6F5BFF`, `secondary 0xFF0EA5E9`; dark: `primary 0xFFCFD4FF`, `secondary 0xFF63D3FF`, background `0xFF0F1426`).
- Exports: Provide SVG + PNGs at 512/192/96/48. Use maskable variants for PWA (`frontend/web/manifest.json`).
- Flutter: Reference assets in `pubspec.yaml` under `flutter/assets` and update launcher icons as needed.

