plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.peerdeal.peerdeal_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val releaseKeystorePath = providers.environmentVariable("PEERDEAL_ANDROID_KEYSTORE").orNull
    val releaseKeystorePassword =
        providers.environmentVariable("PEERDEAL_ANDROID_KEYSTORE_PASSWORD").orNull
    val releaseKeyAlias = providers.environmentVariable("PEERDEAL_ANDROID_KEY_ALIAS").orNull
    val releaseKeyPassword =
        providers.environmentVariable("PEERDEAL_ANDROID_KEY_PASSWORD").orNull
    val releaseSigningValues = listOf(
        releaseKeystorePath,
        releaseKeystorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    )
    val hasReleaseSigning = releaseSigningValues.any { !it.isNullOrBlank() }
    if (hasReleaseSigning && releaseSigningValues.any { it.isNullOrBlank() }) {
        throw GradleException(
            "PEERDEAL_ANDROID_KEYSTORE, PEERDEAL_ANDROID_KEYSTORE_PASSWORD, " +
                "PEERDEAL_ANDROID_KEY_ALIAS, and PEERDEAL_ANDROID_KEY_PASSWORD " +
                "must be provided together.",
        )
    }
    if (hasReleaseSigning && !file(releaseKeystorePath!!).isFile) {
        throw GradleException("PEERDEAL_ANDROID_KEYSTORE must point to a file.")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.peerdeal.peerdeal_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
