# R8 rules for Habesha Hub. Flutter, Firebase and the plugins ship their own keep rules;
# these only cover what they don't.

# Readable Crashlytics stack traces (the Crashlytics Gradle plugin uploads the mapping file)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter engine references Play Core (deferred components) even when it isn't used
-dontwarn com.google.android.play.core.**

# Game pages call HabeshaApp.postMessage(...) through the WebView JavaScript channel
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Google Play Billing (in_app_purchase)
-keep class com.android.vending.billing.** { *; }
