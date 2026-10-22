import org.gradle.api.artifacts.repositories.MavenArtifactRepository

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// android_file_picker 2.1.1 declares legacy buildscript versions. Use the
// consuming project's pinned toolchain instead of resolving a second AGP/KGP.
gradle.beforeProject {
    // JetBrains artifacts are published on Maven Central. Missing-object
    // responses from Google can be surfaced as upstream 503s by cloud proxies.
    // Apply to late repositories added by native Flutter plugin scripts too.
    val centralOnlyGroups = Action<MavenArtifactRepository> {
        if (url.host == "dl.google.com" || url.host == "maven.google.com") {
            content { excludeGroupByRegex("org\\.jetbrains(\\..*)?") }
        }
    }
    repositories.withType(MavenArtifactRepository::class.java).configureEach(centralOnlyGroups)
    buildscript.repositories.withType(MavenArtifactRepository::class.java).configureEach(centralOnlyGroups)
    if (name == "android_file_picker") {
        buildscript.configurations.configureEach {
            resolutionStrategy.force(
                "com.android.tools.build:gradle:9.1.0",
                "org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.0",
            )
        }
    }
}
