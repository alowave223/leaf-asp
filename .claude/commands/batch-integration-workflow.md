---
name: batch-integration-workflow
description: Workflow command scaffold for batch-integration-workflow in leaf-asp.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /batch-integration-workflow

Use this workflow when working on **batch-integration-workflow** in `leaf-asp`.

## Goal

Integrating a large set of changes from ASP into the Leaf project, typically in batches. Each batch touches a variety of core, server, plugin, and patch files, often grouped by functionality or subsystem.

## Common Files

- `core/src/main/java/com/infernalsuite/asp/**`
- `leaf-server/src/main/java/org/dreeam/leaf/**`
- `leaf-server/src/main/java/org/leavesmc/leaves/**`
- `leaf-server/minecraft-patches/**`
- `leaf-server/paper-patches/**`
- `plugin/src/main/java/com/infernalsuite/asp/plugin/**`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Prepare a batch of related changes from ASP or upstream.
- Update core Java implementation files (e.g., serialization, util, exceptions).
- Update or add server-side files (e.g., config modules, async tasks, protocol handlers).
- Update or add plugin-related files (e.g., command parsers, resource templates).
- Update patch files in leaf-server/minecraft-patches or paper-patches.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.