pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
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

rootProject.name = "Android-Dev-Portfolio"

include(":exno1")
project(":exno1").projectDir = file("exno1/app")

include(":exno2")
project(":exno2").projectDir = file("exno2/app")

include(":exno3")
project(":exno3").projectDir = file("exno3/app")

include(":exno4")
project(":exno4").projectDir = file("exno4/app")

include(":exno5")
project(":exno5").projectDir = file("exno5/app")

include(":exno6")
project(":exno6").projectDir = file("exno6/app")

include(":exno7")
project(":exno7").projectDir = file("exno7/app")

include(":exno8")
project(":exno8").projectDir = file("exno8/app")

include(":exno9")
project(":exno9").projectDir = file("exno9/app")

include(":exno10")
project(":exno10").projectDir = file("exno10/app")
