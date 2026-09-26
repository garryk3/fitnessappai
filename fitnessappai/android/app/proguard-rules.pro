# Правила R8/ProGuard приложения.
#
# Flutter подключает этот файл автоматически, как только он существует
# (FlutterPlugin.kt: `if (proguardRulesPro.exists()) releaseBuildType.proguardFiles.add(...)`).
# Без него release-сборка минифицируется только правилами самого Flutter.

# flutter_local_notifications сериализует запланированные уведомления через
# Gson, а десериализация в ScheduledNotificationReceiver идёт по reflection.
# Начиная с v19 плагин поставляет правила Gson сам, но явные правики дешевле
# и защищают от регрессий при смене версии плагина.
-keep class com.dexterous.** { *; }
-keepattributes Signature

# Gson читает generic-типы из TypeToken только при наличии подписи.
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.JsonAdapter
