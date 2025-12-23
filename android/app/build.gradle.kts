plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply the Google services Gradle plugin so google-services.json is processed
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fn_flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.fn_flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += listOf("default")
    productFlavors {
        create("dev") {
            dimension = "default"

            resValue("string", "app_name", "Finance Notes Dev")
        }
        create("prod") {
            dimension = "default"
            resValue("string", "app_name", "Finance Notes")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM to keep Firebase libraries in sync
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Example Firebase SDK (analytics) – safe even if you don't use it directly yet
    implementation("com.google.firebase:firebase-analytics")
}
