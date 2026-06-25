allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun configureProject(p: Project) {
        if (p.extensions.findByName("android") != null) {
            val android = p.extensions.getByName("android")
            try {
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Integer::class.java)
                setCompileSdk.invoke(android, 34)
            } catch (e: Exception) {
                try {
                    val compileSdkVersion = android.javaClass.getMethod("compileSdkVersion", java.lang.Integer::class.java)
                    compileSdkVersion.invoke(android, 34)
                } catch (ex: Exception) {}
            }
            
            try {
                val defaultConfig = android.javaClass.getMethod("getDefaultConfig").invoke(android)
                try {
                    val setTargetSdk = defaultConfig.javaClass.getMethod("setTargetSdk", Integer::class.java)
                    setTargetSdk.invoke(defaultConfig, 34)
                } catch (ex: Exception) {
                    try {
                        val targetSdk = defaultConfig.javaClass.getMethod("targetSdk", java.lang.Integer::class.java)
                        targetSdk.invoke(defaultConfig, 34)
                    } catch (ex2: Exception) {}
                }
            } catch (e: Exception) {}
        }
    }

    if (project.state.executed) {
        configureProject(project)
    } else {
        project.afterEvaluate {
            configureProject(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
