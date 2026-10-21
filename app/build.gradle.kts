plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.petya.arportal"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.petya.arportal"
        minSdk = 24
        targetSdk = 34
        versionCode = (System.getenv("GITHUB_RUN_NUMBER") ?: "1").toInt()
        versionName = "0.1." + (System.getenv("GITHUB_RUN_NUMBER") ?: "0")
    }

    // Постоянный ключ подписи: новые сборки ставятся поверх старых без удаления.
    signingConfigs {
        getByName("debug") {
            storeFile = rootProject.file("keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.google.ar:core:1.44.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-ktx:1.13.1")
}
