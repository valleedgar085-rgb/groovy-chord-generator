# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
<<<<<<< HEAD
# proguardFiles setting in build.gradle.
=======
# proguardFiles setting in build.gradle.kts.
>>>>>>> ca49d278b2e4ae9b502e55d500969999ab9151d1
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

<<<<<<< HEAD
# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
=======
# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebView
-keep class android.webkit.WebView { *; }
-keep class android.webkit.WebViewClient { *; }

# Flutter-specific ProGuard rules for better performance
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase optimizations
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Prevent obfuscation of audio players
-keep class xyz.luan.audioplayers.** { *; }

# General Android optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
>>>>>>> ca49d278b2e4ae9b502e55d500969999ab9151d1
