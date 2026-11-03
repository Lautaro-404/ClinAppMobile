---
name: Liquid Glass Delivery
colors:
  surface: '#111319'
  surface-dim: '#111319'
  surface-bright: '#37393f'
  surface-container-lowest: '#0c0e13'
  surface-container-low: '#191c21'
  surface-container: '#1d2025'
  surface-container-high: '#282a30'
  surface-container-highest: '#33353b'
  on-surface: '#e2e2ea'
  on-surface-variant: '#e2bfb8'
  inverse-surface: '#e2e2ea'
  inverse-on-surface: '#2e3036'
  outline: '#a98984'
  outline-variant: '#5a413c'
  surface-tint: '#ffb4a6'
  primary: '#ffb4a6'
  on-primary: '#660700'
  primary-container: '#f85d44'
  on-primary-container: '#5a0500'
  inverse-primary: '#b22b18'
  secondary: '#ffb4a3'
  on-secondary: '#630f00'
  secondary-container: '#8f1b01'
  on-secondary-container: '#ffa08a'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#00a572'
  on-tertiary-container: '#00311f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a6'
  on-primary-fixed: '#3f0300'
  on-primary-fixed-variant: '#8f1002'
  secondary-fixed: '#ffdad2'
  secondary-fixed-dim: '#ffb4a3'
  on-secondary-fixed: '#3d0600'
  on-secondary-fixed-variant: '#8c1900'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#111319'
  on-background: '#e2e2ea'
  surface-variant: '#33353b'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 21px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
  currency-display:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.25rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an ultra-premium, tactile on-demand delivery ecosystem engineered for hyper-local speed and visual indulgence. Grounded in a futuristic "Liquid Glass" sensory framework, it blends the hyper-polished precision of Apple iOS 26 optics with the warmth, intimacy, and hospitality of Mendoza's culinary culture.

### Aesthetic Foundation
- **Liquid Glass Optics:** Materials behave like thick, sculpted optical quartz with active refraction. Dynamic background warmth bleeds through semi-translucent substrates, responding to scrolling and interaction.
- **Atmospheric Contrast:** Immersive obsidian baselines offset by radiant liquid ember glows. Surfaces feel physical, polished, and suspended in space rather than flat or purely simulated.
- **Tone of Voice:** Rioplatense Spanish with natural voseo (*Pedí*, *Elegí*, *Seguilo*, *Buscá*). Decisive, warm, prompt, and local.

## Colors

The system relies on high-luminance accents floating above an ultra-dark canvas, using chromatic dispersion and specular edge lighting to establish hierarchy.

### Canvas & Surfaces
- **Canvas Base:** `#07090E` (deep oceanic obsidian).
- **Surface Layer 1:** `#0F131C` at rest, or `rgba(255, 255, 255, 0.08)` backdrop frosted layer over ambient nodes.
- **Surface Layer 2 (Raised Sheets):** `rgba(255, 255, 255, 0.12)`.
- **Surface Layer 3 (High Dynamic Popovers & Alerts):** `rgba(255, 255, 255, 0.16)`.

### Chromatic Light Nodes
Behind glass panels, diffuse light orbs generate optical depth:
- **Warm Flare Primary:** `#E8523A` (64px–128px Gaussian blur, 25–40% layer opacity).
- **Secondary Ember Glow:** `#FF6B4A` (80px Gaussian blur, 20–30% opacity).

### Typography & Content
- **Text Primary:** `#FFFFFF` (100% luminance).
- **Text Secondary:** `rgba(255, 255, 255, 0.60)` for metadata, hints, and timestamps.
- **Text Tertiary / Disabled:** `rgba(255, 255, 255, 0.35)`.

### Feedback Tokens
- **Success:** Emerald `#10B981` with ambient bloom `rgba(16, 185, 129, 0.25)`.
- **Warning / Preparation:** Amber `#F59E0B`.
- **Danger / Cancellation:** Vivid Coral Crimson `#EF4444`.

## Typography

Typography delivers strict clarity across low-transparency substrates through disciplined contrast and proportional tracking adjustments.

- **Numerics & Local Currency:** Price tags format strictly with the local Argentine thousand-separator standard (`$14.600`, `$2.850`). Always pair numeric monetary values with `font-feature-settings: "tnum" 1` to maintain tabular vertical alignment in receipt breakdowns and dynamic shopping bags.
- **Capitalization & Grammar:** Action titles leverage sentence case with Argentine voseo imperatives (`Pedí ahora`, `Seguí tu pedido`, `Confirmá tu dirección`).

## Layout & Spacing

Layout geometry follows an edge-to-edge floating viewport architecture with strict boundary allowances for frosted peripheral layers.

- **Screen Rails:** Standard mobile outer margins stay locked at `1.25rem` (`20px`), decreasing to `1rem` (`16px`) on ultra-compact devices.
- **Safe Area Bottom Offsets:** Floating structural elements (such as the detached bottom navigation pill) float `24px` above the device's native Home Indicator bar. Content containers scroll underneath with a bottom padding reservation of `108px` to guarantee zero interaction collisions.
- **Card Clustering:** Card-to-card vertical intervals standardize at `space-md` (`16px`), while internal content grouping within glass sheets maintains a `space-sm` (`8px`) separation.

## Elevation & Depth

Depth is defined via optical refraction, variable backdrop blurs, and specular surface borders rather than opaque drop shadows.

### Glassmorphic Levels
1. **Level 0 (Atmospheric Bed):** Pure `#07090E` background hosting ambient blurred radial meshes (`#E8523A` and `#FF6B4A`).
2. **Level 1 (Substrate Cards & Feeds):**
   - Background: `rgba(255, 255, 255, 0.08)`.
   - Backdrop Filter: `blur(20px) saturate(180%)`.
   - Specular Rim: 1px border gradient from `rgba(255, 255, 255, 0.22)` at top-left to `rgba(255, 255, 255, 0.04)` at bottom-right.
   - Shadow: `0 8px 32px 0 rgba(0, 0, 0, 0.37)`.
3. **Level 2 (Floating Pills & Detached Nav Bar):**
   - Background: `rgba(15, 19, 28, 0.72)`.
   - Backdrop Filter: `blur(28px) saturate(200%)`.
   - Specular Rim: 1px continuous border with top highlight `rgba(255, 255, 255, 0.35)` down to `rgba(255, 255, 255, 0.10)`.
   - Shadow: `0 16px 40px rgba(0, 0, 0, 0.55), 0 0 1px rgba(255, 255, 255, 0.25) inset`.
4. **Level 3 (Modal Sheets & Real-Time Tracking Dialogs):**
   - Background: `rgba(255, 255, 255, 0.14)`.
   - Backdrop Filter: `blur(32px) saturate(190%)`.
   - Active Glow Shadow: `0 20px 48px rgba(0, 0, 0, 0.65), 0 0 24px rgba(232, 82, 58, 0.15)`.

## Shapes

The geometric signature uses iOS-inspired squircles for expansive surfaces and full capsule pills for active touchpoints.

- **Content Cards & Containers:** Radii strictly follow squircle curves scaling between `24px` and `32px`.
- **Interactive Controls (Buttons, Inputs, Badges, Tabs):** Locked to `9999px` (pill shape).
- **Sheet Drawers:** Top-left and top-right corners carved at `36px` squircle curvature; bottom corners conform to hardware display curves.

## Components

### Buttons
- **Primary Action (Pill):** Solid `#E8523A` base fill or fluid gradient (`#FF6B4A` to `#E8523A`). Edge border 1px `rgba(255, 255, 255, 0.35)` top sheen. Drop shadow: `0 8px 24px rgba(232, 82, 58, 0.40)`. Text: `#FFFFFF`, weight 600.
- **Glass Secondary (Pill):** Background `rgba(255, 255, 255, 0.10)`, backdrop blur `16px`. Rim: 1px `rgba(255, 255, 255, 0.18)`.
- **Floating Bag / Checkout:** Sticky bottom capsule spanning `calc(100% - 32px)`, height `56px`, displaying aggregate item count bubble, localized currency total (`$14.600`), and right-aligned arrow action.

### Floating Navigation Bar
- **Architecture:** Detached floating capsule isolated from screen margins (left/right `20px`, bottom `24px`).
- **Material:** Ultra-frosted glass `rgba(15, 19, 28, 0.75)`, backdrop blur `24px`, inner specular rim highlight.
- **Active State Indicator:** Smooth liquid capsule bubble surrounding active icon with an internal `#E8523A` radiant bloom and active icon tinted pure white. Inactive icons remain at `rgba(255, 255, 255, 0.50)`.

### Cards (Vendor, Product & Order Tracker)
- **Product & Restaurant Cards:** Framed with `24px` or `28px` squircles, `rgba(255, 255, 255, 0.08)` surface fill, 1px specular highlight border. Cover images masked with complementary squircle inner cutouts (`18px`).
- **Live Delivery Card ("Seguilo en vivo"):** Houses interactive real-time route progress. Uses emerald `#10B981` pulsing indicator for driver location with dynamic countdown metadata.

### Form Inputs & Search Fields
- **Search Field ("Buscá comida, bebidas..."):** Height `48px`, capsule pill (`9999px`), `rgba(255, 255, 255, 0.08)` fill, left-aligned search glyph in secondary white, text in pure white.
- **Focused State:** 1px perimeter glow in `#E8523A` paired with a diffused ambient drop shadow `0 0 12px rgba(232, 82, 58, 0.30)`.

### Chips & Filters
- **Category Selectors:** Height `36px`, pill shape, horizontal scrolling track. 
- **Active State:** `#E8523A` background with crisp white text.
- **Inactive State:** `rgba(255, 255, 255, 0.07)` fill, 1px `rgba(255, 255, 255, 0.14)` border, text `rgba(255, 255, 255, 0.70)`.