    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "com.multiplatformbusinesssdk.core"
        compileSdk = 34

        defaultConfig {
            minSdk = 26
        }

        publishing {
            singleVariant("release") {
                withSourcesJar()
            }
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
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.9.0")
    }

afterEvaluate {
    publishing {
        publications {
            create("release", org.gradle.api.publish.maven.MavenPublication::class) {
                from(components["release"])
                groupId = "com.multiplatformbusinesssdk"
                artifactId = "business-sdk-android-core"
                version = System.getenv("SDK_VERSION") ?: "0.1.0-SNAPSHOT"

                pom {
                    name.set("Business SDK Android Core")
                    description.set("Core networking primitives for generated Android SDK modules.")
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

