plugins {
    id("com.android.application")
    kotlin("android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.oerol.pose"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.oerol.pose"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    sourceSets.getByName("main") {
        // Single source of truth: the same pose JSONs and model photos the iOS
        // app bundles, referenced in place — no duplicated assets in the repo.
        assets.srcDir("../../App/Resources/Poses")
    }

    buildFeatures { compose = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    implementation(project(":posekit"))
    implementation(platform("androidx.compose:compose-bom:2024.09.03"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.navigation:navigation-compose:2.8.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")

    val camerax = "1.3.4"
    implementation("androidx.camera:camera-core:$camerax")
    implementation("androidx.camera:camera-camera2:$camerax")
    implementation("androidx.camera:camera-lifecycle:$camerax")
    implementation("androidx.camera:camera-view:$camerax")

    // Bundled-model pose detector — on-device, no Play Services download.
    implementation("com.google.mlkit:pose-detection:18.0.0-beta5")

    testImplementation("junit:junit:4.13.2")
}
