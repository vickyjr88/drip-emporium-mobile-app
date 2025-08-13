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
# Flutter specific rules (usually already present, but good to double check)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase SDKs (essential for Auth, Firestore, etc.)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.auth.** { *; }

# For Paystack Flutter SDK
-keep class co.paystack.android.** { *; }
-keep class co.paystack.android.model.** { *; }
-keep class co.paystack.android.api.** { *; }

# For url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# For share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# For cached_network_image (Glide library)
-keep class com.bumptech.glide.** { *; }
-keep class com.bumptech.glide.load.resource.bitmap.** { *; }
-keep class com.bumptech.glide.load.resource.drawable.** { *; }
-keep class com.bumptech.glide.request.** { *; }
-keep class com.bumptech.glide.annotation.** { *; }

# Your custom Dart code that might be accessed via reflection (less common, but can be a fallback)
# The package name below is derived from your pubspec.yaml's name (drip_emporium_mobile_app)
# You might need to adjust 'com.dripemporium.drip_emporium_mobile_app' if your package name is different.
-keep class com.dripemporium.drip_emporium_mobile_app.** { *; }
-keep class * extends com.dripemporium.drip_emporium_mobile_app.** { *; }

# If you have specific classes in your services, providers, or models that are causing issues,
# you can add more granular rules like these (replace with your actual package/class names):
# -keep class com.dripemporium.drip_emporium_mobile_app.services.DataRepository { *; }
# -keep class com.dripemporium.drip_emporium_mobile_app.providers.ProductsProvider { *; }
# -keep class com.dripemporium.drip_emporium_mobile_app.models.** { *; } # If you have a models folder
# Rules for Google Play Services (essential for Google Sign-In)
-keep class com.google.android.gms.** { *; }

# Rules for Firebase Authentication (if you're using it with Google Sign-In)
-keep class com.google.firebase.auth.** { *; }

# General Firebase rules (good to have if you're using other Firebase services)
-keep class com.google.firebase.** { *; }

# Play Core Library rules to prevent R8 from stripping essential classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
