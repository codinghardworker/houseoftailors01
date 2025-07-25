# Flutter Wrapper - Essential rules to prevent R8 from breaking MethodChannels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter MethodChannel communication
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase & Network
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.auth.api.internal.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Network security
-keep class org.apache.http.** { *; }
-keep class android.net.http.** { *; }

# JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Stripe Android SDK - Comprehensive rules
-keep class com.stripe.** { *; }
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.core.** { *; }
-keep class com.stripe.android.payments.** { *; }
-keep class com.stripe.android.paymentsheet.** { *; }
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.view.** { *; }
-keep class com.stripe.android.cards.** { *; }

# Stripe push provisioning
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Stripe Flutter plugin
-keep class io.flutter.plugins.stripe.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Stripe networking and API
-keep class com.stripe.android.networking.** { *; }
-keep class com.stripe.android.exception.** { *; }
-keepclassmembers class com.stripe.android.model.** {
    <fields>;
    <methods>;
}

# Stripe payment methods and intents
-keep class com.stripe.android.model.PaymentMethod { *; }
-keep class com.stripe.android.model.PaymentMethodCreateParams { *; }
-keep class com.stripe.android.model.PaymentIntent { *; }
-keep class com.stripe.android.model.SetupIntent { *; }
-keep class com.stripe.android.model.Customer { *; }
-keep class com.stripe.android.model.CustomerSource { *; }

# Stripe PaymentSheet specific
-keep class com.stripe.android.paymentsheet.PaymentSheet { *; }
-keep class com.stripe.android.paymentsheet.PaymentSheetResult { *; }
-keep class com.stripe.android.paymentsheet.PaymentSheetConfiguration { *; }
-keep class com.stripe.android.paymentsheet.state.** { *; }

# Stripe connection and initialization
-keep class com.stripe.android.Stripe { *; }
-keep class com.stripe.android.ApiResultCallback { *; }
-keep class com.stripe.android.PaymentConfiguration { *; }

# Stripe serialization
-keepclassmembers class * implements android.os.Parcelable {
    static android.os.Parcelable$Creator CREATOR;
}

# Image loading (Cached Network Image)
-keep class com.bumptech.glide.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.exifinterface.** { *; }
-keepclassmembers class * extends android.content.ContentProvider {
    public <init>();
}

# Camera and Media
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.camera.**

# Google Play Core (required for Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**