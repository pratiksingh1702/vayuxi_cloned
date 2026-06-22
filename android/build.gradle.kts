allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let {
            (it as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

val cleanDuplicateAndroidResourceCopies by tasks.registering {
    doLast {
        val buildRoot = rootProject.layout.buildDirectory.get().asFile
        if (!buildRoot.exists()) return@doLast

        val duplicateGeneratedFile = Regex(""".* \d+\.(xml|flat|arsc|png|webp|jpg|jpeg|json)$""")
        buildRoot.listFiles()?.forEach { projectBuildDir ->
            listOf(
                projectBuildDir.resolve("intermediates/packaged_res"),
                projectBuildDir.resolve("intermediates/merged_res"),
                projectBuildDir.resolve("intermediates/merged-not-compiled-resources")
            )
                .filter { it.exists() }
                .forEach { resourceDir ->
                    resourceDir.walkTopDown()
                        .filter { it.isFile && duplicateGeneratedFile.matches(it.name) }
                        .forEach { it.delete() }
                }
        }
    }
}

subprojects {
    tasks.matching {
        it.name.contains("Resources", ignoreCase = true)
    }.configureEach {
        if (providers.gradleProperty("cleanDuplicateAndroidResources").isPresent) {
            dependsOn(cleanDuplicateAndroidResourceCopies)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
