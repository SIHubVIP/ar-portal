plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.petya.bashnya"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.petya.bashnya"
        minSdk = 24
        targetSdk = 34
        versionCode = (System.getenv("GITHUB_RUN_NUMBER") ?: "1").toInt()
        versionName = "0.2." + (System.getenv("GITHUB_RUN_NUMBER") ?: "0")
    }

    // Один постоянный ключ: новые сборки ставятся поверх старых.
    signingConfigs {
        getByName("debug") {
            storeFile = rootProject.file("../keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("debug") { signingConfig = signingConfigs.getByName("debug") }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
