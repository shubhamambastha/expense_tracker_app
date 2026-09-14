plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shubhamambastha.expensetracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shubhamambastha.expensetracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Auth0 Flutter SDK — domain/scheme from dart-define at build time.
        // Custom scheme (not "https") so Android doesn't need App Links/Digital Asset
        // Link verification on the Auth0 tenant domain — see docs/auth0_setup.md.
        val auth0Domain =
            project.findProperty("AUTH0_DOMAIN") as String?
                ?: System.getenv("AUTH0_DOMAIN")
                ?: "YOUR_AUTH0_DOMAIN"
        val auth0Scheme =
            project.findProperty("AUTH0_CALLBACK_SCHEME") as String?
                ?: System.getenv("AUTH0_CALLBACK_SCHEME")
                ?: "https"
        manifestPlaceholders["auth0Domain"] = auth0Domain
        manifestPlaceholders["auth0Scheme"] = auth0Scheme
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
