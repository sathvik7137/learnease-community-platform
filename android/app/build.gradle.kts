plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.learnease.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.learnease.app"
        minSdk = 21  // Updated for better compatibility
        targetSdk = 34  // Latest stable Android version
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true  // Support for large apps
    }

    signingConfigs {
        release {
            // You need to create a keystore file and add these properties
            // Instructions: Run this command to create keystore:
            // keytool -genkey -v -keystore c:\Users\CyberBot\learnease-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias learnease
            storeFile = file("C:\\Users\\CyberBot\\learnease-release-key.jks")
            storePassword = System.getenv("LEARNEASE_STORE_PASSWORD") ?: "temp123"
            keyAlias = "learnease"
            keyPassword = System.getenv("LEARNEASE_KEY_PASSWORD") ?: "temp123"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
