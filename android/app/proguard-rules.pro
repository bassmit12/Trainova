-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.trainova.fitness.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }

# Optimize and don't warn about certain classes
-dontwarn org.xmlpull.v1.**
-dontwarn okio.**
-dontwarn org.bouncycastle.**
-dontwarn kotlin.**

# Faster builds
-dontpreverify
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*