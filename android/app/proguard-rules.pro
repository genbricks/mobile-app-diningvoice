# Retrofit
-keepattributes Signature
-keepattributes *Annotation*
-keep class io.genbricks.diningvoice.data.model.** { *; }
-keep class io.genbricks.diningvoice.data.api.** { *; }

# Gson
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
