---
name: add-or-update-config-module
description: Workflow command scaffold for add-or-update-config-module in leaf-asp.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-update-config-module

Use this workflow when working on **add-or-update-config-module** in `leaf-asp`.

## Goal

Adding or updating a configuration module for gameplay, optimization, or network features in the Leaf server. Involves creating or modifying files under config/modules and updating related enums or annotations.

## Common Files

- `leaf-server/src/main/java/org/dreeam/leaf/config/modules/**`
- `leaf-server/src/main/java/org/dreeam/leaf/config/EnumConfigCategory.java`
- `leaf-server/src/main/java/org/dreeam/leaf/config/annotations/**`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create or update a Java file in leaf-server/src/main/java/org/dreeam/leaf/config/modules/**.
- If needed, update EnumConfigCategory.java to register the new config.
- Optionally, update or add annotation files (e.g., Experimental.java, DoNotLoad.java).
- Update related configuration resource files if necessary.
- Commit changes with a message referencing the config module.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.