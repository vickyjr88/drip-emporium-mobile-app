# Keep classes from the http package
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }
-keep class com.squareup.okio.** { *; }

# Keep classes from your DataRepository
-keep class com.dripemporium.app.services.DataRepository { *; }
