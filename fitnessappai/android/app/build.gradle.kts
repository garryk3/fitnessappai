plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fitnessappai"
    compileSdk = flutter.compileSdkVersion
    // NDK закреплён явно, чтобы версия не «плыла» вместе с `channel: stable`
    // в .github/workflows/ci.yml: обновление Flutter в тулчейне подняло бы и
    // требуемую версию NDK, и локальные сборки на машинах без неё. Значение
    // совпадает с дефолтом Flutter 3.47.4 (FlutterExtension.kt: ndkVersion),
    // то есть меняется источник истины, а не сам номер версии.
    // См. PLAN.md 47.18: при обновлении Flutter сверить версию с дефолтом.
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.fitnessappai"
        // Требование проекта: Android 12+ (API 31+).
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Плейсхолдер для плагинов, читающих иконку уведомления из манифеста.
        // Сам flutter_local_notifications берёт иконку из Dart
        // (AndroidInitializationSettings), а R8-шринковка ресурсов
        // отключается через res/raw/keep.xml — placeholder шринковщику
        // невидим и сам по себе ресурс не сохраняет.
        manifestPlaceholders["default_notification_icon"] = "@drawable/ic_stat_launcher"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
