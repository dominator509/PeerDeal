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
    val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
        taskName.substringAfterLast(':').contains("release", ignoreCase = true)
    }
    val hasReleaseSigning = releaseSigningValues.any { !it.isNullOrBlank() }
    if (hasReleaseSigning && releaseSigningValues.any { it.isNullOrBlank() }) {
        throw GradleException(
            "PEERDEAL_ANDROID_KEYSTORE, PEERDEAL_ANDROID_KEYSTORE_PASSWORD, " +
                "PEERDEAL_ANDROID_KEY_ALIAS, and PEERDEAL_ANDROID_KEY_PASSWORD " +
                "must be provided together.",
        )
    }
    val hasUnsafeReleaseSigningValue = releaseSigningValues.any { value ->
        value != null &&
            (value != value.trim() ||
                value.any { character ->
                    character.code <= 0x20 || character.code == 0x7F
                })
    }
    if (hasReleaseSigning && hasUnsafeReleaseSigningValue) {
        throw GradleException(
            "PEERDEAL_ANDROID_* signing values must be unpadded and control-free.",
        )
    }
    if (releaseTaskRequested && !hasReleaseSigning) {
        throw GradleException(
            "Android release builds require all four PEERDEAL_ANDROID_* signing " +
                "values; use a debug build until operator-owned signing is configured.",
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
