```markdown
# leaf-asp Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns, coding conventions, and key workflows used in the `leaf-asp` Java codebase. The repository is focused on integrating and extending server-side features, configuration modules, and patch management for a Minecraft server environment. You'll learn how to batch-integrate upstream changes, add or update configuration modules, and manage patch files, all while adhering to the project's coding and commit conventions.

## Coding Conventions

- **File Naming:**  
  Use PascalCase for Java class files.  
  _Example:_  
  ```
  MyAwesomeClass.java
  ```

- **Import Style:**  
  Use relative imports within the package structure.  
  _Example:_  
  ```java
  import org.dreeam.leaf.config.modules.GameplayConfig;
  ```

- **Export Style:**  
  Use named exports for classes and interfaces.  
  _Example:_  
  ```java
  public class GameplayConfig { ... }
  ```

- **Commit Messages:**  
  - Freeform, no strict prefix required.
  - Average message length: ~41 characters.
  - Batch commits group related changes.

## Workflows

### Batch Integration Workflow
**Trigger:** When integrating upstream changes or large feature sets from ASP into Leaf, often as part of a migration or sync effort.  
**Command:** `/batch-integrate`

1. Prepare a batch of related changes from ASP or upstream.
2. Update core Java implementation files (e.g., serialization, util, exceptions).
3. Update or add server-side files (e.g., config modules, async tasks, protocol handlers).
4. Update or add plugin-related files (e.g., command parsers, resource templates).
5. Update patch files in `leaf-server/minecraft-patches` or `paper-patches`.
6. Update build scripts or configuration files as needed.
7. Commit all related changes together under a batch commit message.

_Example commit message:_  
```
Integrate ASP batch: update serialization, config, and plugin modules
```

### Add or Update Config Module
**Trigger:** When introducing a new configuration option or modifying an existing one for server behavior.  
**Command:** `/add-config-module`

1. Create or update a Java file in `leaf-server/src/main/java/org/dreeam/leaf/config/modules/`.
2. If needed, update `EnumConfigCategory.java` to register the new config.
3. Optionally, update or add annotation files (e.g., `Experimental.java`, `DoNotLoad.java`).
4. Update related configuration resource files if necessary.
5. Commit changes with a message referencing the config module.

_Example:_  
```java
// leaf-server/src/main/java/org/dreeam/leaf/config/modules/GameplayConfig.java
package org.dreeam.leaf.config.modules;

public class GameplayConfig {
    // Configuration logic here
}
```
```java
// Register in EnumConfigCategory.java
GAMEPLAY_CONFIG,
```

### Add or Update Patch File
**Trigger:** When a new patch is needed for the server or an existing patch must be updated.  
**Command:** `/add-patch`

1. Create or update a `.patch` file in `leaf-server/minecraft-patches` or `leaf-server/paper-patches`.
2. If necessary, update related Java files that interact with the patch.
3. Commit the patch file and any supporting code changes.

_Example:_  
```
leaf-server/minecraft-patches/0010-Improve-Chunk-Loading.patch
```

## Testing Patterns

- **Framework:** Unknown (not explicitly detected).
- **File Pattern:** Test files follow the `*.test.*` naming convention.
- **Example:**  
  ```
  GameplayConfig.test.java
  ```
- **Note:** Ensure tests are named accordingly and placed alongside the relevant modules or in a dedicated test directory.

## Commands

| Command             | Purpose                                                      |
|---------------------|--------------------------------------------------------------|
| /batch-integrate    | Integrate a batch of upstream or ASP changes into Leaf       |
| /add-config-module  | Add or update a configuration module                        |
| /add-patch          | Add or update a Minecraft or Paper patch file               |
```
