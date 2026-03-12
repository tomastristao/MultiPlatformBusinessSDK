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
include(":business-sdk")
include(":modules:toggle-identity-sdk")
include(":modules:advice-slip-sdk")
include(":modules:cat-facts-sdk")
include(":modules:open-brewery-sdk")
include(":modules:pokemon-sdk")
include(":modules:rick-and-morty-sdk")
project(":business-sdk").projectDir = file("business-sdk")
project(":modules:toggle-identity-sdk").projectDir = file("modules/toggle-identity-sdk")
project(":modules:advice-slip-sdk").projectDir = file("modules/advice-slip-sdk")
project(":modules:cat-facts-sdk").projectDir = file("modules/cat-facts-sdk")
project(":modules:open-brewery-sdk").projectDir = file("modules/open-brewery-sdk")
project(":modules:pokemon-sdk").projectDir = file("modules/pokemon-sdk")
project(":modules:rick-and-morty-sdk").projectDir = file("modules/rick-and-morty-sdk")
