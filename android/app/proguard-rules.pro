# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Kotlin
-keep class kotlin.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable
-dontwarn kotlin.**

# Supabase / Ktor / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# OkHttp (used by Supabase internals)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Biometric (local_auth)
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# SQLite / SQLCipher (Drift)
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Serialization / JSON (Dart ↔ platform channel payloads are plain maps)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
