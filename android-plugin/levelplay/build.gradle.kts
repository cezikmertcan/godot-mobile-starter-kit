import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val pluginName = "LevelPlayAds"
val pluginPackageName = "com.godotmobile.levelplay"
val godotVersion = "4.7.1.stable"
val levelPlayVersion = "9.5.0"

android {
    namespace = pluginPackageName
    compileSdk = 35

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = pluginName
        manifestPlaceholders["godotPluginPackageName"] = pluginPackageName
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"$pluginName\"")
        setProperty("archivesBaseName", pluginName)
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

dependencies {
    implementation("org.godotengine:godot:$godotVersion")
    implementation("com.unity3d.ads-mediation:mediation-sdk:$levelPlayVersion")
    implementation("com.unity3d.ads-mediation:unityads-adapter:5.11.0")
    implementation("com.unity3d.ads:unity-ads:4.19.0")
    implementation("com.google.android.gms:play-services-appset:16.0.0")
    implementation("com.google.android.gms:play-services-ads-identifier:18.1.0")
    implementation("com.google.android.gms:play-services-basement:18.1.0")
}

val repositoryRoot = projectDir.parentFile.parentFile
val addonBinDirectory = repositoryRoot.resolve("addons/LevelPlayAds/bin")

val copyDebugAar by tasks.registering(Copy::class) {
    dependsOn("assembleDebug")
    from(layout.buildDirectory.dir("outputs/aar"))
    include("$pluginName-debug.aar")
    into(addonBinDirectory.resolve("debug"))
}

val copyReleaseAar by tasks.registering(Copy::class) {
    dependsOn("assembleRelease")
    from(layout.buildDirectory.dir("outputs/aar"))
    include("$pluginName-release.aar")
    into(addonBinDirectory.resolve("release"))
}

tasks.register("packagePlugin") {
    group = "build"
    description = "Builds both plugin variants and copies them into the Godot addon."
    dependsOn(copyDebugAar, copyReleaseAar)
}
