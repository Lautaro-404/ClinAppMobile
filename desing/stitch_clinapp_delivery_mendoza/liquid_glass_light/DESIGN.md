---
name: Liquid Glass Light
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#5a413c'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#8e706b'
  outline-variant: '#e2bfb8'
  surface-tint: '#b22b18'
  primary: '#ae2916'
  on-primary: '#ffffff'
  primary-container: '#d1422c'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb4a6'
  secondary: '#a7391e'
  on-secondary: '#ffffff'
  secondary-container: '#fd7958'
  on-secondary-container: '#6e1500'
  tertiary: '#006947'
  on-tertiary: '#ffffff'
  tertiary-container: '#00855b'
  on-tertiary-container: '#f5fff6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a6'
  on-primary-fixed: '#3f0300'
  on-primary-fixed-variant: '#8f1002'
  secondary-fixed: '#ffdad2'
  secondary-fixed-dim: '#ffb4a2'
  on-secondary-fixed: '#3c0700'
  on-secondary-fixed-variant: '#862208'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
  canvas-base: '#F8F9FA'
  canvas-subtle: '#F1F3F5'
  surface-card: rgba(255, 255, 255, 0.72)
  surface-float: rgba(255, 255, 255, 0.85)
  surface-overlay: rgba(255, 255, 255, 0.92)
  glass-border-white: rgba(255, 255, 255, 0.70)
  glass-border-subtle: rgba(229, 231, 235, 0.80)
  text-primary: '#111827'
  text-secondary: '#4B5563'
  text-tertiary: '#6B7280'
  text-disabled: '#9CA3AF'
  ambient-glow-primary: rgba(232, 82, 58, 0.12)
  ambient-glow-coral: rgba(255, 122, 89, 0.10)
  feedback-success: '#10B981'
  feedback-warning: '#F59E0B'
  feedback-danger: '#EF4444'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
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
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.005em
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

This design system reimagines the tactile on-demand delivery experience into a radiant, daylight-infused "Liquid Glass" sensory framework. It pairs the high optical precision of translucent frosted glass with luminous warm off-white canvases and vibrant red-orange chromatic energy.

### Aesthetic Foundation
- **Luminous Glass Optics:** Translucent frosted crystalline planes floating over pristine, warm neutral surfaces. Glass elements capture soft ambient reflections, characterized by subtle bright white rim highlights, silky backdrop blurs, and airy suspended shadows.
- **Warm Ambient Radiance:** Soft, diffused peach, coral, and red-orange light nodes glow gently behind glass panels, producing dimensional warmth and vitality without visual clutter.
- **Tone of Voice:** Rioplatense Spanish with natural voseo (*Pedí*, *Elegí*, *Seguilo*, *Buscá*). Prompt, modern, welcoming, and hospitable.
- **Movement & Tactility:** Modern Glassmorphic minimalism executed with rounded pill touchpoints, sculpted cards, and fluid interactive transitions.

## Colors

The light mode color palette shifts the canvas to pristine, warm neutrals while preserving the energetic vibrant red-orange identity. Contrast is prioritized across layered glass sheets to retain legibility and tactile clarity.

### Canvas & Surface Hierarchies
- **Base Canvas (`#F8F9FA`):** Warm architectural off-white foundation.
- **Nested Well / Track (`#F1F3F5`):** Soft light neutral for pill wells, chip tracks, and input backgrounds.
- **Glass Sheet (Standard):** `rgba(255, 255, 255, 0.72)` with high blur filtering.
- **Floating Controls & Navigation:** `rgba(255, 255, 255, 0.85)` with layered drop reflections.
- **Modals & Drawers:** `rgba(255, 255, 255, 0.92)` to preserve high-contrast readability against shifting content beneath.

### Chromatic Glow Nodes
Ambient diffused spotlights positioned behind primary cards and headers:
- **Warm Flare:** `#E8523A` diffused via 64px–96px blur at 10–14% opacity.
- **Coral Light:** `#FF7A59` diffused via 80px blur at 8–12% opacity.

### Typography & Content
- **Text Primary (`#111827`):** Deep charcoal-black delivering crisp WCAG AAA legibility against white glass.
- **Text Secondary (`#4B5563`):** Neutral slate for secondary descriptions and labels.
- **Text Tertiary (`#6B7280`):** Muted cool gray for timestamps, breadcrumbs, and helper text.

## Typography

The type scale relies entirely on Inter, prioritized for optical clarity across translucent layers.

- **Tabular Figures:** Always apply `font-feature-settings: "tnum" 1` to price tokens, checkout calculations, and ETA counters to keep digit columns vertically aligned.
- **Local Numeric Formatting:** Prices format according to Argentine standards (`$14.600`, `$2.850`), retaining bold weights for instant visual scanning.
- **Visual Weight & Hierarchy:** Emphasize medium and semibold weights (`500`, `600`) over ultra-thin cuts to ensure strong legibility against glass textures.

## Layout & Spacing

A mobile-first, edge-to-edge floating viewport architecture designed to let background ambient glows peek through frosted structural layers.

- **Screen Rails:** Standard container padding is `1.25rem` (`20px`), scaling down to `1rem` (`16px`) on smaller phone screens.
- **Bottom Clearance:** Scroll regions reserve an absolute minimum of `108px` bottom padding to accommodate the detached floating glass navigation pill and native bottom system indicators.
- **Content Rhythms:** Cards follow a continuous `space-md` (`16px`) stack, while elements inside cards cluster using `space-sm` (`8px`) and `space-md` (`16px`) intervals.

## Elevation & Depth

Visual depth is conveyed through layered optical refraction, high-blur glass filters, dual-toned specular borders, and soft daylight drop shadows.

### Glassmorphic Layers
1. **Level 0 (Base Canvas):** Solid `#F8F9FA` underlay hosting soft radial gradients of `#E8523A` and `#FF7A59` at 10% opacity with 80px Gaussian blur.
2. **Level 1 (Substrate & Product Cards):**
   - Background: `rgba(255, 255, 255, 0.72)`.
   - Backdrop Filter: `blur(20px) saturate(180%)`.
   - Border: 1px solid `rgba(255, 255, 255, 0.70)` combined with subtle perimeter ring `rgba(229, 231, 235, 0.60)`.
   - Shadow: `0 8px 24px -4px rgba(17, 24, 39, 0.06), 0 2px 6px -1px rgba(17, 24, 39, 0.04)`.
3. **Level 2 (Floating Pills, Detached Bar, Sticky Cart):**
   - Background: `rgba(255, 255, 255, 0.85)`.
   - Backdrop Filter: `blur(24px) saturate(200%)`.
   - Border: 1px solid `rgba(255, 255, 255, 0.90)`.
   - Shadow: `0 12px 32px -4px rgba(17, 24, 39, 0.10), 0 4px 12px -2px rgba(17, 24, 39, 0.05)`.
4. **Level 3 (Modal Sheets & Tracking Dialogs):**
   - Background: `rgba(255, 255, 255, 0.94)`.
   - Backdrop Filter: `blur(32px) saturate(190%)`.
   - Border: 1px solid `rgba(255, 255, 255, 1.0)`.
   - Shadow: `0 24px 48px -12px rgba(17, 24, 39, 0.14), 0 0 20px rgba(232, 82, 58, 0.08)`.

## Shapes

The geometry maintains an organic, high-radius profile blending pill-shaped capsules with sculpted `rounded-3xl` containers.

- **Interactive Elements (Buttons, Search Bars, Badges, Tabs, Pills):** Fully pill-shaped (`rounded-full` / `9999px`).
- **Surface Cards & Vendor Tiles:** Framed with `rounded-3xl` (`1.5rem` / `24px` to `2rem` / `32px`).
- **Sheet Drawers & Modals:** Top edges rounded at `36px` squircle curvature; bottom corners conform to device margins.
- **Media Cutouts:** Internal image and banner masks match container proportions using `rounded-2xl` (`1rem` / `16px`).

## Components

### Buttons
- **Primary Action (Pill):** Solid `#E8523A` fill, text `#FFFFFF` (weight 600). Top inner edge highlight `1px rgba(255, 255, 255, 0.25)`. Shadow: `0 8px 20px rgba(232, 82, 58, 0.32)`.
- **Secondary Glass (Pill):** Translucent `rgba(255, 255, 255, 0.80)` fill, 1px border `rgba(229, 231, 235, 0.80)`. Text `#111827`. Hover/Press: `rgba(241, 243, 245, 0.90)`.
- **Floating Cart Pill:** Fixed bottom pill capsule, background `rgba(255, 255, 255, 0.90)` with `blur(20px)`, housing a primary `#E8523A` item count bubble, tabular Argentine price (`$14.600`), and dark text action.

### Floating Navigation Bar
- **Architecture:** Detached floating glass pill positioned `24px` above the device bottom rail and `20px` from side screen edges.
- **Surface:** `rgba(255, 255, 255, 0.85)` with `24px` backdrop blur, 1px specular white border highlight (`rgba(255, 255, 255, 0.90)`), and soft drop shadow.
- **Active State Indicator:** Smooth capsule container in `#E8523A` with pure white active icon. Inactive icons render in `#6B7280`.

### Cards (Vendor, Product & Tracking)
- **Vendor / Dish Card:** Translucent `rgba(255, 255, 255, 0.72)` background, `24px` rounded corners, 1px `rgba(255, 255, 255, 0.80)` border, subtle light gray perimeter ring, and soft shadow. Inner image masked at `16px`.
- **Live Delivery Card ("Seguilo en vivo"):** Light glass container with a pulsating emerald indicator (`#10B981`) marking courier progress, complemented by dark charcoal text for remaining delivery minutes.

### Form Inputs & Search Fields
- **Search Bar ("Buscá comida, bebidas..."):** Height `48px`, full pill radius (`9999px`), `rgba(255, 255, 255, 0.80)` glass fill, 1px border `rgba(229, 231, 235, 0.80)`. Placeholder in `#6B7280`, input text `#111827`.
- **Focused State:** 1.5px border in `#E8523A` with ambient glow `0 0 0 3px rgba(232, 82, 58, 0.15)`.

### Chips & Filter Pills
- **Category Chips:** Height `36px`, pill shape, horizontal scrolling arrangement.
- **Active State:** `#E8523A` fill with white text (`#FFFFFF`) and warm glow shadow `0 4px 12px rgba(232, 82, 58, 0.25)`.
- **Inactive State:** `rgba(255, 255, 255, 0.75)` fill, 1px border `rgba(229, 231, 235, 0.80)`, text `#4B5563`.