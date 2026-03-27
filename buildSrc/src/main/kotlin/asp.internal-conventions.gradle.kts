import net.kyori.indra.git.IndraGitExtension
import org.gradle.kotlin.dsl.the
import java.io.File

fun debugLog(hypothesisId: String, message: String, data: String) {
    // #region agent log
    runCatching {
        val timestamp = System.currentTimeMillis()
        val line = """{"sessionId":"a86b73","runId":"post-fix","hypothesisId":"$hypothesisId","location":"buildSrc/src/main/kotlin/asp.internal-conventions.gradle.kts","message":"$message","data":{"detail":"${data.replace("\"", "\\\"")}"},"timestamp":$timestamp}"""
        File("/home/alowave/Documents/leaf-asp/.cursor/debug-a86b73.log").appendText(line + "\n")
    }
    // #endregion
}

val configurationCacheRequested = gradle.startParameter.isConfigurationCacheRequested
debugLog("H14", "Configuration cache requested check", "requested=$configurationCacheRequested")

if (!configurationCacheRequested) {
    apply(plugin = "net.kyori.indra.git")
    debugLog("H15", "Applied indra git plugin", "applied=true")
} else {
    debugLog("H15", "Applied indra git plugin", "applied=false")
}

val apiVersion = rootProject.providers.gradleProperty("apiVersion").get()
val versionSuffix = if (!configurationCacheRequested && plugins.hasPlugin("net.kyori.indra.git")) {
    the<IndraGitExtension>().commit()?.name ?: "SNAPSHOT"
} else {
    "SNAPSHOT"
}
debugLog("H16", "Computed version suffix", "suffix=$versionSuffix")
version = "$apiVersion-$versionSuffix"
