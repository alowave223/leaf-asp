---
name: add-or-update-patch-file
description: Workflow command scaffold for add-or-update-patch-file in leaf-asp.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-update-patch-file

Use this workflow when working on **add-or-update-patch-file** in `leaf-asp`.

## Goal

Adding or updating a patch file for Minecraft or Paper, typically to introduce or modify server features or bugfixes.

## Common Files

- `leaf-server/minecraft-patches/**`
- `leaf-server/paper-patches/**`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create or update a .patch file in leaf-server/minecraft-patches or leaf-server/paper-patches.
- If necessary, update related Java files that interact with the patch.
- Commit the patch file and any supporting code changes.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.