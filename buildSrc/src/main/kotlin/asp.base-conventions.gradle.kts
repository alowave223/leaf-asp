import java.io.File

plugins {
    `java-library`
    id("asp.internal-conventions")
}

java {
    withSourcesJar()
    withJavadocJar()
}

// #region agent log
runCatching {
    val timestamp = System.currentTimeMillis()
    val line = """{"sessionId":"a86b73","runId":"post-fix","hypothesisId":"H12","location":"buildSrc/src/main/kotlin/asp.base-conventions.gradle.kts","message":"Base conventions plugin applied","data":{"project":"$name"},"timestamp":$timestamp}"""
    File("/home/alowave/Documents/leaf-asp/.cursor/debug-a86b73.log").appendText(line + "\n")
}
// #endregion
