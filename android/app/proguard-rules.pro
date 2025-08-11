# Keep classes from the http package
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }
-keep class com.squareup.okio.** { *; }

# Keep classes from your DataRepository
-keep class com.dripemporium.app.services.DataRepository { *; }

# Rules for BouncyCastle, Conscrypt, OpenJSSE, and SLF4J to prevent R8 from removing them
-keep class org.bouncycastle.** { *; }
-keep class org.conscrypt.** { *; }
-keep class org.openjsse.** { *; }
-keep class org.slf4j.** { *; }

# Aggressive keep rules for platform-specific SSL/TLS providers often used by OkHttp
-keep class okhttp3.internal.platform.** { *; }
-keep class okhttp3.internal.platform.android.** { *; }

# Don't warn about missing classes from these packages (as a fallback)
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn org.slf4j.**

# Keep MainActivity to prevent ClassNotFoundException
-keep class com.dripemporium.app.MainActivity { *; }
