// Pure-JVM Kotlin library — the Android port of PoseKit's scoring math.
// No Android plugin on purpose: tests run on any JVM (Windows dev machine,
// Linux CI). The future Android app module consumes it as a project
// dependency; org.json is provided by the Android framework at runtime.
plugins {
    kotlin("jvm")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.json:json:20240303")
    testImplementation("junit:junit:4.13.2")
}

kotlin {
    jvmToolchain(17)
}
