# Flutter
  -keep class io.flutter.** { *; }
  -keep class io.flutter.plugins.** { *; }

  # SQFlite
  -keep class com.tekartik.sqflite.** { *; }

  # Connectivity Plus
  -keep class dev.fluttercommunity.plus.connectivity.** { *; }

  # Secure Storage
  -keep class com.it_nomads.fluttersecurestorage.** { *; }

  # Image Picker
  -keep class io.flutter.plugins.imagepicker.** { *; }

  # WebView (official webview_flutter package)
  -keep class io.flutter.plugins.webviewflutter.** { *; }
  -dontwarn io.flutter.plugins.webviewflutter.**

  # Google Play Core (referenced by Flutter deferred components / split install)
  -keep class com.google.android.play.core.** { *; }
  -dontwarn com.google.android.play.core.**

  # Encrypt / PointyCastle
  -keep class org.bouncycastle.** { *; }
  -dontwarn org.bouncycastle.**
  -keep class com.shaded.fasterxml.jackson.** { *; }

  # Permission Handler
  -keep class com.baseflow.permissionhandler.** { *; }

  # Gson / JSON
  -keepattributes Signature
  -keepattributes *Annotation*
  -dontwarn sun.misc.**
  -keep class com.google.gson.** { *; }

  # General
  -dontwarn javax.annotation.**
  -dontwarn org.conscrypt.**
  -dontwarn org.openjsse.**
  