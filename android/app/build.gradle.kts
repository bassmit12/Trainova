import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties file if it exists
val keystorePropertiesFile = rootProject.file("key.properties")
val useKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.trainova.fitness"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("src/main/AndroidManifest.xml")
            kotlin.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // Updated application ID to the proper package name
        applicationId = "com.trainova.fitness"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // Add signing configuration if key.properties exists
    if (useKeystore) {
        val properties = Properties()
        properties.load(keystorePropertiesFile.inputStream())
        
        signingConfigs {
            create("release") {
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (useKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Signing with the debug keys for now, so `flutter run --release` works.
                signingConfig = signingConfigs.getByName("debug")
            }
            // Enable optimization, shrinking and obfuscation
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // Enable build cache
    buildFeatures {
        buildConfig = true
    }

    // Speed up packaging
    packagingOptions {
        resources {
            excludes += listOf("META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/license.txt", "META-INF/NOTICE", "META-INF/NOTICE.txt", "META-INF/notice.txt", "META-INF/ASL2.0")
        }
    }

    // Increase daemon memory for faster builds
    dexOptions {
        javaMaxHeapSize = "4g"
    }
}

kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    
    // Add Play Core library to fix the missing classes error
    implementation("com.google.android.play:core:1.10.3")
    // Add Play Core KTX for Kotlin extensions (optional but recommended)
    implementation("com.google.android.play:core-ktx:1.8.1")
}
