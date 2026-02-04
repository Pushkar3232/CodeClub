# Flutter specific ProGuard rules
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature

# Prevent stripping of Firebase serialization
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Keep model classes if using reflection
-keep class com.example.codeclub.** { *; }

# Suppress warnings for missing classes
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
