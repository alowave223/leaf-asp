plugins {
    `kotlin-dsl`
}

import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.plugin.use.PluginDependency
import java.io.File

group = "com.infernalsuite"

repositories {
    mavenLocal()
    mavenCentral()
    gradlePluginPortal()
}

fun convertPlugin(plugin: Provider<PluginDependency>): String {
    val id = plugin.get().pluginId
    return "$id:$id.gradle.plugin:${plugin.get().version}"
}

fun debugLog(hypothesisId: String, message: String, data: String) {
    // #region agent log
    runCatching {
        val timestamp = System.currentTimeMillis()
        val line = """{"sessionId":"a86b73","runId":"pre-fix","hypothesisId":"$hypothesisId","location":"buildSrc/build.gradle.kts","message":"$message","data":{"detail":"${data.replace("\"", "\\\"")}"},"timestamp":$timestamp}"""
        File("/home/alowave/Documents/leaf-asp/.cursor/debug-a86b73.log").appendText(line + "\n")
    }
    // #endregion
}

val catalogs = extensions.findByType(VersionCatalogsExtension::class.java)
debugLog("H1", "Version catalog extension lookup", "catalogsPresent=${catalogs != null}")
val libsCatalog = runCatching { catalogs?.named("libs") }.getOrNull()
debugLog("H2", "Named libs catalog lookup", "libsCatalogPresent=${libsCatalog != null}")
val blossomAlias = runCatching { libsCatalog?.findPlugin("blossom")?.get() }.getOrNull()
debugLog("H3", "Plugin alias lookup", "blossomAliasPresent=${blossomAlias != null}")
val librariesForLibsClassPresent = runCatching {
    Class.forName("org.gradle.accessors.dm.LibrariesForLibs")
}.isSuccess
debugLog("H6", "LibrariesForLibs class lookup", "classPresent=$librariesForLibsClassPresent")
val accessorsDirExists = File(buildDir, "generated-sources").exists()
debugLog("H7", "Generated accessors directory check", "generatedSourcesExists=$accessorsDirExists")
val baseConventionsFileExists = File(projectDir, "src/main/kotlin/asp.base-conventions.gradle.kts").exists()
debugLog("H10", "Base conventions script check", "fileExists=$baseConventionsFileExists")
val publishingConventionsFileExists = File(projectDir, "src/main/kotlin/asp.publishing-conventions.gradle.kts").exists()
debugLog("H11", "Publishing conventions script check", "fileExists=$publishingConventionsFileExists")

dependencies {
    if (catalogs != null) {
        implementation(files(catalogs.javaClass.superclass.protectionDomain.codeSource.location))
        debugLog("H4", "Added catalog codeSource dependency", "added=true")
    } else {
        debugLog("H4", "Added catalog codeSource dependency", "added=false")
    }
    libsCatalog?.findPlugin("blossom")?.ifPresent { implementation(convertPlugin(it)) }
    libsCatalog?.findPlugin("indragit")?.ifPresent { implementation(convertPlugin(it)) }
    libsCatalog?.findPlugin("profiles")?.ifPresent { implementation(convertPlugin(it)) }
    libsCatalog?.findPlugin("kotlin-jvm")?.ifPresent { implementation(convertPlugin(it)) }
    libsCatalog?.findPlugin("lombok")?.ifPresent { implementation(convertPlugin(it)) }
    // implementation(convertPlugin(libs.plugins.paperweight.patcher)) // Removed - conflicts with root project's paperweight plugin
    libsCatalog?.findPlugin("plugin-yml-paper")?.ifPresent { implementation(convertPlugin(it)) }
    libsCatalog?.findPlugin("shadow")?.ifPresent { implementation(convertPlugin(it)) }
    debugLog("H5", "Dependency wiring completed", "buildSrc dependencies block evaluated")
}
