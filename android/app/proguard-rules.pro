# Loop release R8 keep rules (2026-11-11).
#
# 2026-10-18: R8 broke WorkManager, which the ads SDK pulls in. Room creates
# WorkDatabase_Impl through a reflected no-arg constructor, so the app crashed
# right at startup. Keep every generated RoomDatabase implementation and its
# constructor.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** extends androidx.room.RoomDatabase { *; }
-keepnames class androidx.work.** { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# Native ad factory is registered from MainActivity by direct reference, but
# keep the class names to make crash reports readable.
-keepnames class com.loop.loop.** { *; }

# Flutter engine references Play Core deferred components optionally.
-dontwarn com.google.android.play.core.**
