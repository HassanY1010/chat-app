# Icon Design System

## Philosophy
The new icon system is built on the principles of **Clarity**, **Softness**, and **Modernity**. 
Inspired by top-tier apps like Airbnb and Stripe, these icons feature:
-   **Rounded Corners:** A 3px-4px border radius on most shapes to appear friendly and touchable.
-   **Unified Stroke:** A consistent 1.5px stroke width for visual balance.
-   **Open/Broken Lines:** Where energetic, we use subtle breaks in the lines to add character (e.g., distinct connection points).
-   **Pixel Perfection:** Aligned to a 24px grid to ensure sharpness at any size.

## Technical Specs
-   **Format:** SVG (Vector)
-   **Grid Size:** 24x24px
-   **Live Area:** 22x22px (1px padding)
-   **Stroke Width:** 1.5px
-   **Cap/Join:** Round / Round
-   **Color:** `currentColor` (allows dynamic tinting in code)

## Usage in Flutter
To use these icons, ensure `flutter_svg` is added to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_svg: ^2.0.0
```

Usage:
```dart
SvgPicture.asset(
  'assets/icons/new_design/home.svg',
  color: Colors.blue,
  width: 24,
  height: 24,
)
```
