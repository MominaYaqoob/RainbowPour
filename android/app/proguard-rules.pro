# Release (R8) rules for Rainbow Pour.
#
# WorkManager (pulled in by Google Mobile Ads / Firebase) creates its Room
# database through the generated class androidx.work.impl.WorkDatabase_Impl.
# R8 full mode keeps that class (library rule) but REMOVES its default
# constructor, so the app crashed on launch in release builds with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
# Keep the constructor of every Room database.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}

# audioplayers (sound effects and music). R8 full mode can rename or strip the
# plugin's enums and player classes, which are looked up by name from Dart; the
# game then plays no sound at all in release builds (it worked in debug).
-keep class xyz.luan.audioplayers.** { *; }
-keepclassmembers enum xyz.luan.audioplayers.** { *; }
