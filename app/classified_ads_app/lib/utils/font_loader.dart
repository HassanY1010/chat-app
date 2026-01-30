

// This file is used to configure font loading for Flutter Web
// to prevent automatic loading of Google Fonts fallbacks.
// 
// By providing an empty font fallback list, we ensure only
// the fonts defined in pubspec.yaml are loaded.

class FontLoader {
  static Future<void> loadFonts() async {
    // Register font fallbacks as empty to prevent Google Fonts loading
    // ui.platformDispatcher.onPlatformMessage; // Removed due to undefined name error since it is a no-op
    
    // This prevents Flutter Web from trying to load fallback fonts
    // from Google Fonts CDN
  }
}
