group = "io.qualtive.qualtive"
version = "0.0.1"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://central.sonatype.com/repository/maven-snapshots/")
    }
}

rootProject.allprojects {
    repositories {
        maven("https://central.sonatype.com/repository/maven-snapshots/")
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "io.qualtive.qualtive"

    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Pinned to https://github.com/nightshift-habits/qualtive-client-android/commit/00e88474c22e44d67b36dfb48cdc0d93b22e33cd
    implementation("io.qualtive:client:0.1.0-20260828.083152-3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    testImplementation("junit:junit:4.13.2")
}
