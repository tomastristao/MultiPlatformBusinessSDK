plugins {
    id("com.android.library")
    kotlin("android")
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
