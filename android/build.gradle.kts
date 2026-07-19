// Root build: plugin versions are declared once here (apply false) so the
// modules can apply them without version conflicts.
plugins {
    id("com.android.application") version "8.5.2" apply false
    kotlin("jvm") version "2.0.21" apply false
    kotlin("android") version "2.0.21" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21" apply false
}
