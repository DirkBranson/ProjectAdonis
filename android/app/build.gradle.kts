plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // This must be here for Firebase!
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // This is your internal code ID
    namespace = "com.escaplemos.adonis" 
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
        // This is your public Store/Firebase ID
        applicationId = "com.escaplemos.adonis"
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}