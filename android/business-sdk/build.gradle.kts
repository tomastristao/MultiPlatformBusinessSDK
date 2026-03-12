    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "com.multiplatformbusinesssdk"
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
        api(project(":sdk-core"))
        api(project(":modules:advice-slip-sdk"))
        api(project(":modules:cat-facts-sdk"))
        api(project(":modules:pokemon-sdk"))
        api(project(":modules:rick-and-morty-sdk"))
    }

afterEvaluate {
    publishing {
        publications {
            create("release", org.gradle.api.publish.maven.MavenPublication::class) {
                from(components["release"])
                groupId = "com.multiplatformbusinesssdk"
                artifactId = "business-sdk-android"
                version = System.getenv("SDK_VERSION") ?: "0.1.0-SNAPSHOT"

                pom {
                    name.set("Business SDK Android")
                    description.set("Umbrella Android package exposing all generated SDK modules from this repository.")
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

