# ============================================
# Flutter Core Rules
# ============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ============================================
# Shared Preferences (CRITICAL!)
# ============================================
-keep class androidx.preference.** { *; }
-keepclassmembers class * implements android.content.SharedPreferences {
    *;
}

# ============================================
# Dio & HTTP
# ============================================
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# Provider (State Management)
# ============================================
-keep class provider.** { *; }
-keep class androidx.lifecycle.** { *; }

# ============================================
# Image Picker
# ============================================
-keep class io.flutter.plugins.imagepicker.** { *; }

# ============================================
# Google Maps
# ============================================
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }

# ============================================
# Notifications
# ============================================
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# ============================================
# Pusher & Socket.IO
# ============================================
-keep class com.pusher.** { *; }
-keep class io.socket.** { *; }
-dontwarn com.pusher.**

# ============================================
# PDF & Printing
# ============================================
-keep class printing.** { *; }
-keep class pdf.** { *; }

# ============================================
# SVG
# ============================================
-keep class flutter_svg.** { *; }

# ============================================
# URL Launcher
# ============================================
-keep class io.flutter.plugins.urllauncher.** { *; }

# ============================================
# Play Core
# ============================================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ============================================
# General Android Rules
# ============================================
-keep class com.example.classified_ads_app.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================
# Suppress Warnings
# ============================================
-dontwarn org.slf4j.**
-dontwarn ch.qos.logback.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
