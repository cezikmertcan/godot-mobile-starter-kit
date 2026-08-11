# LevelPlay and mediation adapters use reflection for parts of their lifecycle.
-keep public interface com.ironsource.mediationsdk.** { *; }
-keep public class com.ironsource.** { *; }
-keep class com.ironsource.adapters.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.appset.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.ironsource.**
-dontwarn com.ironsource.adapters.**
