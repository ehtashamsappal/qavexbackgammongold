# Qavex Backgammon Gold ProGuard rules
-keep class com.qavex.qavexbackgammongold.** { *; }
# flame / flutter
-keep class io.flutter.** { *; }
# Play Core (referenced by Flutter embedding, not bundled)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
