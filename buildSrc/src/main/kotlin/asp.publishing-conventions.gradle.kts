import com.infernalsuite.asp.conventions.PublishConfiguration.Companion.publishConfiguration
import org.gradle.api.publish.PublishingExtension
import org.gradle.api.publish.maven.MavenPublication
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.named
import java.io.File

plugins {
    `maven-publish`
}

val publishConfig = project.publishConfiguration()

fun debugLog(hypothesisId: String, message: String, data: String) {
    // #region agent log
    runCatching {
        val timestamp = System.currentTimeMillis()
        val line = """{"sessionId":"a86b73","runId":"post-fix","hypothesisId":"$hypothesisId","location":"buildSrc/src/main/kotlin/asp.publishing-conventions.gradle.kts","message":"$message","data":{"detail":"${data.replace("\"", "\\\"")}"},"timestamp":$timestamp}"""
        File("/home/alowave/Documents/leaf-asp/.cursor/debug-a86b73.log").appendText(line + "\n")
    }
    // #endregion
}

extensions.configure<PublishingExtension> {
    val existing = publications.findByName("maven")
    debugLog("H17", "Maven publication pre-check", "exists=${existing != null}")
    if (existing == null) {
        publications.create<MavenPublication>("maven") {
            val javaComponent = project.components.findByName("java")
            debugLog("H18", "Java component lookup for maven publication", "exists=${javaComponent != null}")
            if (javaComponent != null) {
                from(javaComponent)
            }
        }
    }

    publications.named<MavenPublication>("maven") {
        pom {
            name.convention(publishConfig.name)
            description.convention(publishConfig.description)
        }
    }
}

debugLog("H13", "Publishing conventions plugin applied", "project=$name")
