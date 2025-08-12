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

# Keep MainActivity and its superclasses to prevent ClassNotFoundException
-keep class com.dripemporium.app.MainActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# Keep rule for Paystack TLSSocketFactory
-keep class com.paystack.android.tls.TLSSocketFactory { *; }

# Keep annotations for serialization
-keepattributes *Annotation*

# Keep Paystack SDK classes and their members from obfuscation
-keep class co.paystack.** { *; }

# Keep all classes from the Paystack SDK
-keep class com.paystack.** { *; }
-keep class co.paystack.** { *; }
