plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services Plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.hotel_mobile"
    compileSdk = 36  // Android 16 (API level 36) - required by dependencies
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hotel_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Android 5.0 (API level 21)
        targetSdk = 36  // Android 16 (API level 36) - required by dependencies
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Tối ưu APK size - chỉ build cho emulator x86_64 (giảm kích thước)
        ndk {
            abiFilters += listOf("x86_64") // Chỉ build cho emulator
            // Đổi thành listOf("arm64-v8a", "armeabi-v7a", "x86_64") khi build cho thiết bị thật
        }
    }

    buildTypes {
        debug {
            // Tối ưu cho debug build - giảm kích thước
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    // Giảm kích thước APK
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "**/attach_hotspot_windows.dll"
            excludes += "META-INF/licenses/**"
            excludes += "META-INF/AL2.0"
            excludes += "META-INF/LGPL2.1"
        }
    }
}

flutter {
    source = "../.."
}

repositories {
    flatDir {
        dirs("libs")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // AndroidX dependencies (bắt buộc cho AppCompatActivity)
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // VNPay SDK - chỉ load nếu AAR file tồn tại
    if (file("libs/merchant-1.0.25.aar").exists()) {
        implementation(files("libs/merchant-1.0.25.aar"))
        implementation("com.google.code.gson:gson:2.10.1")
        implementation("com.squareup.okhttp3:okhttp:4.12.0")
    }
}
