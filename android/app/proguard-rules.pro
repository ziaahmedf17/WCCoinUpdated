# Keep Facebook Audience Network classes
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Keep Unity Ads classes
-keep class com.unity3d.ads.** { *; }
-dontwarn com.unity3d.**

# Keep Google mediation adapters
-keep class com.google.ads.mediation.** { *; }
-dontwarn com.google.ads.mediation.**

# Keep annotations used by Facebook
-keepattributes *Annotation*

# Prevent R8 from removing dynamically referenced classes
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.infer.annotation.**
