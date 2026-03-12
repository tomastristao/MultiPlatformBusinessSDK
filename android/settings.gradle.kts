pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MultiPlatformBusinessSDK"
include(":sdk-core")
include(":modules:pokemon-sdk")
project(":modules:pokemon-sdk").projectDir = file("modules/pokemon-sdk")
