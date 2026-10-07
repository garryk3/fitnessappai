import java.util.Properties

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

    // Временный release-ключ (задача 48.6): android/key.properties и
    // android/app/upload-keystore.jks лежат в git осознанно — ключ не
    // секретный, заменяется перед публикацией в Google Play. Без файла
    // (новый разработчик, чистый клон) сборка откатывается на debug, чтобы
    // `flutter run --release` и локальная проверка не падали.
    val keystoreProperties = Properties().apply {
        val propertiesFile = rootProject.file("key.properties")
        if (propertiesFile.exists()) {
            propertiesFile.inputStream().use { load(it) }
        }
    }
    val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
