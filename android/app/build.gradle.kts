import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

fun loadAndroidLocalProperties(): Properties {
    val props = Properties()
    val file = rootProject.file("local.properties")
    if (file.isFile) {
        FileInputStream(file).use { props.load(it) }
    }
    return props
}

fun encodeDartDefine(key: String, value: String): String =
    Base64.getEncoder().encodeToString("$key=$value".toByteArray(Charsets.UTF_8))

fun dartDefinesContainsKey(existing: String, key: String): Boolean {
    if (existing.isBlank()) {
        return false
    }
    return existing.split(',').any { encoded ->
        try {
            String(Base64.getDecoder().decode(encoded)).startsWith("$key=")
        } catch (_: IllegalArgumentException) {
            false
        }
    }
}

val androidLocalProperties = loadAndroidLocalProperties()
val mapsApiKey =
    androidLocalProperties.getProperty("GOOGLE_MAPS_API_KEY")?.trim()
        ?: (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)?.trim()
        ?: ""

if (mapsApiKey.isNotEmpty() && !dartDefinesContainsKey(
        project.findProperty("dart-defines")?.toString().orEmpty(),
        "HANDOVER_MAP_ENABLED",
    )
) {
    val autoDefine = encodeDartDefine("HANDOVER_MAP_ENABLED", "true")
    val existing = project.findProperty("dart-defines")?.toString()?.trim().orEmpty()
    val merged = if (existing.isEmpty()) autoDefine else "$existing,$autoDefine"
    project.extensions.extraProperties["dart-defines"] = merged
}

android {
    namespace = "app.sharingbridge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "app.sharingbridge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
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
