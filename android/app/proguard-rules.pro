# Reglas de ofuscación para la compilación release.
#
# R8 elimina en release el código que "parece" no usarse. El problema es que
# WorkManager y Room construyen sus clases por reflexión, así que R8 no ve las
# referencias y las borra. El SDK de anuncios de Google arrastra WorkManager,
# y sin estas reglas la app CIERRA al arrancar con:
#   RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase

# --- WorkManager y Room ---
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class * { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Los inicializadores de androidx.startup también se descubren por reflexión.
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer { *; }

# --- Google Mobile Ads / Play Services ---
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.**

# --- Flutter ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
