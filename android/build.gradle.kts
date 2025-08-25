import java.util.Properties
import java.io.FileInputStream

//buildscript {
//    ext.kotlin_version = "2.1.0" // New: Define Kotlin version
//    repositories {
//        google()
//        mavenCentral()
//    }
//    dependencies {
//        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
//    }
//}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Load key.properties
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        keystoreProperties.forEach { key, value ->
            project.ext.set(key.toString(), value)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
