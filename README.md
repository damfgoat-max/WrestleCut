# WrestleCut
**Cut Weight Safely • Made for Wrestlers**

100% free. No ads. No subscriptions. No in-app purchases. No monetization of any kind.

A comprehensive, safety-first weight-cutting assistant for wrestlers, built in SwiftUI for iOS 18 with SwiftData (fully offline).

## Features
- Dark athletic onboarding: age, height (ft/in + cm), start/goal weight, cut start + weigh-in dates, food dislikes/allergies (multi-select), ZIP/address for nearby stores
- Safe timeline: never plans >1.5–2% body weight/week as fat loss; late drop is timed water with load → taper, never zero fluids. Unsafe paces are flagged, not built
- Dashboard: days left, progress ring, today's weight/calorie targets, water tracker (+250/+500/+1L), streak, motivation
- Cutting Plan: daily target graph (Charts), weekly fat vs water breakdown, safety education
- Nutrition: personalized calories/macros (Mifflin-St Jeor, explained), full meal plan avoiding disliked foods, branded products (Tyson, Ben's Original, Fairlife, Fage, etc.) with nearby stores (Walmart, Kroger, Publix, Whole Foods, Aldi, Target), distance + est. price, swap/shuffle with instant recalculation, prep time/ingredients/instructions
- Food Tracker: wrestler-focused database, VisionKit barcode scanner, quick-add favorites, daily calorie/protein/carb/fat bars, workout logging that adjusts calories
- Hydration Coach: exact target (kg × 40 ml, explained), water-loading protocol for final 3–4 days, bottle visual, 7-day history chart
- Rehydration & Recovery: activates on weigh-in day — timed electrolyte/fluid schedule, sodium/potassium/magnesium guidance, 24–48h food reintroduction, warning signs
- Progress: weight vs predicted curve, calorie adherence, water consistency, weekly summary

## Tech
- SwiftUI + SwiftData + Charts + VisionKit, MVVM-ish (Views + Calculators/Services), iOS 18, dark-only, red/black/gold
- Accessibility: Dynamic Type (system fonts), VoiceOver labels, high-contrast palette
- Offline: all data in SwiftData on-device; store lookup is deterministic local data (no location sent anywhere) — replace `StoreService` with a retailer API for live inventory

## Disclaimer
Guidance only — not medical advice. Consult your coach, athletic trainer, or doctor before cutting weight, especially if under 18.

## CI
GitHub Actions (`.github/workflows/ios.yml`) builds on macOS with Xcode 16 on every push/PR.

## Build
Open `WrestleCut.xcodeproj` in Xcode 16+, select an iPhone simulator (iOS 18), Run.
