    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "com.multiplatformbusinesssdk.rickandmorty"
        compileSdk = 34

        defaultConfig {
            minSdk = 26
        }

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }
    }

    dependencies {
        implementation(project(":sdk-core"))
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.9.0")
    }

publishing {
    singleVariant("release") {
        withSourcesJar()
    }
}

afterEvaluate {
    extensions.configure<PublishingExtension>("publishing") {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.multiplatformbusinesssdk"
                artifactId = "rick-and-morty-sdk-android"
                version = System.getenv("SDK_VERSION") ?: "0.1.0-SNAPSHOT"

                pom {
                    name.set("RickAndMortySDK Android")
                    description.set("Generated Android business SDK for RickAndMortySDK.")
                }
            }
        }

        repositories {
            maven {
                name = "GitHubPackages"
                val repository = System.getenv("GITHUB_REPOSITORY") ?: "OWNER/REPO"
                url = uri("https://maven.pkg.github.com/$repository")
                credentials {
                    username = System.getenv("GITHUB_ACTOR")
                    password = System.getenv("GITHUB_TOKEN")
                }
            }
        }
    }
}

