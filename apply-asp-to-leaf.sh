#!/bin/bash
set -euo pipefail

# =============================================================================
# apply-asp-to-leaf.sh
# Automates applying AdvancedSlimePaper (ASP) patches to Leaf for slime world
# compatibility. Creates a combined Leaf+ASP project.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
LEAF_DIR="$WORK_DIR/leaf"
ASP_DIR="$WORK_DIR/asp"
REPORT_FILE="$SCRIPT_DIR/patch-report.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Initialize report
echo "=== ASP -> Leaf Patch Application Report ===" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

report() {
    echo "$1" >> "$REPORT_FILE"
}

# =============================================================================
# Phase 1: Clone repositories if not present
# =============================================================================
phase1_clone() {
    log_info "Phase 1: Setting up repositories..."

    mkdir -p "$WORK_DIR"

    if [ ! -d "$LEAF_DIR/.git" ]; then
        log_info "Cloning Leaf ver/1.21.4..."
        git clone --branch ver/1.21.4 https://github.com/Winds-Studio/Leaf.git "$LEAF_DIR"
    else
        log_ok "Leaf repository already present"
    fi

    if [ ! -d "$ASP_DIR/.git" ]; then
        log_info "Cloning ASP mc/1.21.4..."
        git clone --branch mc/1.21.4 https://github.com/InfernalSuite/AdvancedSlimePaper.git "$ASP_DIR"
    else
        log_ok "ASP repository already present"
    fi

    report "Phase 1: Repositories cloned successfully"
}

# =============================================================================
# Phase 2: Copy ASP standalone modules into Leaf
# =============================================================================
phase2_copy_modules() {
    log_info "Phase 2: Copying ASP standalone modules..."

    # Copy buildSrc (Leaf doesn't have one)
    if [ ! -d "$LEAF_DIR/buildSrc" ]; then
        cp -r "$ASP_DIR/buildSrc" "$LEAF_DIR/buildSrc"
        log_ok "Copied buildSrc"
        report "  [OK] Copied buildSrc (convention plugins)"
    fi

    # Copy version catalog
    if [ ! -f "$LEAF_DIR/gradle/libs.versions.toml" ]; then
        cp "$ASP_DIR/gradle/libs.versions.toml" "$LEAF_DIR/gradle/libs.versions.toml"
        log_ok "Copied gradle version catalog"
        report "  [OK] Copied gradle/libs.versions.toml"
    fi

    # Copy standalone modules
    for module in api core plugin importer; do
        if [ ! -d "$LEAF_DIR/$module" ]; then
            cp -r "$ASP_DIR/$module" "$LEAF_DIR/$module"
            log_ok "Copied module: $module"
            report "  [OK] Copied module: $module"
        fi
    done

    # Copy loaders (has sub-modules)
    if [ ! -d "$LEAF_DIR/loaders" ]; then
        cp -r "$ASP_DIR/loaders" "$LEAF_DIR/loaders"
        log_ok "Copied module: loaders (with sub-modules)"
        report "  [OK] Copied module: loaders (file, mongo, mysql, redis, api)"
    fi

    # Copy ASP server implementation source code into leaf-server/src/
    log_info "Copying ASP server source code..."
    local asp_server_src="$ASP_DIR/aspaper-server/src/main/java/com/infernalsuite"
    local leaf_server_src="$LEAF_DIR/leaf-server/src/main/java/com/infernalsuite"

    if [ ! -d "$leaf_server_src" ]; then
        mkdir -p "$(dirname "$leaf_server_src")"
        cp -r "$asp_server_src" "$leaf_server_src"
        log_ok "Copied ASP server source (com.infernalsuite.asp.*)"
        report "  [OK] Copied ASP server source code (22 Java files)"
    fi

    # Copy META-INF services
    local asp_resources="$ASP_DIR/aspaper-server/src/main/resources"
    local leaf_resources="$LEAF_DIR/leaf-server/src/main/resources"
    if [ -d "$asp_resources/META-INF" ]; then
        mkdir -p "$leaf_resources/META-INF/services"
        cp -r "$asp_resources/META-INF/services/"* "$leaf_resources/META-INF/services/" 2>/dev/null || true
        log_ok "Copied META-INF/services entries"
        report "  [OK] Copied META-INF/services (AdvancedSlimePaperAPI, SlimeNMSBridge)"
    fi

    report ""
}

# =============================================================================
# Phase 3: Build system integration
# =============================================================================
phase3_build_integration() {
    log_info "Phase 3: Integrating build system..."

    # 3a. Update settings.gradle.kts to include ASP modules
    log_info "Updating settings.gradle.kts..."
    local settings_file="$LEAF_DIR/settings.gradle.kts"

    # Check if ASP modules already added
    if ! grep -q ":asp-api" "$settings_file" 2>/dev/null && ! grep -q '":api"' "$settings_file" 2>/dev/null; then
        cat >> "$settings_file" << 'SETTINGS_EOF'

// ASP modules
include(":api")
include(":core")
include(":importer")
include(":loaders")
include(":plugin")

include("loaders:mongo-loader")
findProject(":loaders:mongo-loader")?.name = "mongo-loader"
include("loaders:api-loader")
findProject(":loaders:api-loader")?.name = "api-loader"
include("loaders:file-loader")
findProject(":loaders:file-loader")?.name = "file-loader"
include("loaders:mysql-loader")
findProject(":loaders:mysql-loader")?.name = "mysql-loader"
include("loaders:redis-loader")
findProject(":loaders:redis-loader")?.name = "redis-loader"
SETTINGS_EOF
        log_ok "Updated settings.gradle.kts"
        report "  [OK] Updated settings.gradle.kts with ASP module includes"
    fi

    # 3b. Update gradle.properties to add ASP-specific properties
    local props_file="$LEAF_DIR/gradle.properties"
    if ! grep -q "apiVersion" "$props_file" 2>/dev/null; then
        cat >> "$props_file" << 'PROPS_EOF'

# ASP properties
apiVersion=4.2.0-SNAPSHOT
PROPS_EOF
        log_ok "Updated gradle.properties"
        report "  [OK] Updated gradle.properties with ASP apiVersion"
    fi

    # 3c. Update leaf-server/build.gradle.kts.patch to add :core dependency
    log_info "Updating leaf-server build patch to add ASP dependencies..."
    local build_patch="$LEAF_DIR/leaf-server/build.gradle.kts.patch"

    if ! grep -q ":core" "$build_patch" 2>/dev/null; then
        # Add :core dependency after the :leaf-api dependency line
        sed -i '/implementation(project(":leaf-api"))/a\    implementation(project(":core")) // ASP - Slime world core\n    implementation("commons-io:commons-io:2.18.0") // ASP - Required by ASP' "$build_patch"
        log_ok "Added :core dependency to leaf-server build"
        report "  [OK] Added :core and commons-io dependencies to leaf-server"
    fi

    # 3d. Update root build.gradle.kts to add ASP repositories
    local root_build="$LEAF_DIR/build.gradle.kts"
    if ! grep -q "infernalsuite" "$root_build" 2>/dev/null; then
        # Add ASP maven repo to subprojects repositories
        sed -i '/maven(leafMavenPublicUrl)/a\        maven("https://repo.infernalsuite.com/repository/maven-snapshots/") // ASP' "$root_build"
        log_ok "Added InfernalSuite Maven repo to root build"
        report "  [OK] Added InfernalSuite Maven repo"
    fi

    report ""
}

# =============================================================================
# Phase 4: Apply ASP patches to Leaf's patch directories
# =============================================================================
phase4_apply_patches() {
    log_info "Phase 4: Applying ASP patches..."

    local mc_features_dir="$LEAF_DIR/leaf-server/minecraft-patches/features"
    local paper_features_dir="$LEAF_DIR/leaf-server/paper-patches/features"
    local mc_sources_dir="$LEAF_DIR/leaf-server/minecraft-patches/sources"
    local paper_files_dir="$LEAF_DIR/leaf-server/paper-patches/files"

    # Find the highest existing patch numbers
    local mc_max=$(ls "$mc_features_dir" 2>/dev/null | grep -oP '^\d+' | sort -n | tail -1)
    local paper_max=$(ls "$paper_features_dir" 2>/dev/null | grep -oP '^\d+' | sort -n | tail -1)
    mc_max=${mc_max:-0}
    paper_max=${paper_max:-0}

    # Remove leading zeros for arithmetic
    mc_max=$((10#$mc_max))
    paper_max=$((10#$paper_max))

    log_info "Current max patch numbers: minecraft=$mc_max, paper=$paper_max"

    # -------------------------------------------------------------------------
    # 4a. Copy minecraft source patches (sources/*.java.patch)
    # These are paperweight source-level patches applied to individual files
    # -------------------------------------------------------------------------
    report "--- Minecraft Source Patches ---"
    local asp_mc_sources="$ASP_DIR/aspaper-server/minecraft-patches/sources"
    if [ -d "$asp_mc_sources" ]; then
        mkdir -p "$mc_sources_dir"
        local count=0
        while IFS= read -r -d '' patch; do
            local rel_path="${patch#$asp_mc_sources/}"
            local dest="$mc_sources_dir/$rel_path"
            mkdir -p "$(dirname "$dest")"
            cp "$patch" "$dest"
            count=$((count + 1))
            log_ok "Copied source patch: $rel_path"
            report "  [OK] $rel_path"
        done < <(find "$asp_mc_sources" -name "*.patch" -print0)
        log_ok "Copied $count minecraft source patches"
    fi

    # -------------------------------------------------------------------------
    # 4b. Copy minecraft feature patches (renumbered)
    # Skip branding-related patches
    # -------------------------------------------------------------------------
    report ""
    report "--- Minecraft Feature Patches ---"
    local asp_mc_features="$ASP_DIR/aspaper-server/minecraft-patches/features"
    if [ -d "$asp_mc_features" ]; then
        local counter=$((mc_max + 1))
        for patch in "$asp_mc_features"/*.patch; do
            [ -f "$patch" ] || continue
            local basename=$(basename "$patch")
            local patch_name="${basename#[0-9]*-}" # Remove number prefix

            # Skip branding patches
            if echo "$basename" | grep -qi "branding"; then
                log_warn "Skipping branding patch: $basename"
                report "  [SKIP] $basename (branding)"
                continue
            fi

            local new_name=$(printf "%04d-%s" "$counter" "$patch_name")
            cp "$patch" "$mc_features_dir/$new_name"

            # Update the patch number in the file header
            sed -i "s/^\(Subject: \[PATCH\]\)/Subject: [PATCH]/" "$mc_features_dir/$new_name"

            log_ok "Copied minecraft feature: $basename -> $new_name"
            report "  [OK] $basename -> $new_name"
            counter=$((counter + 1))
        done
    fi

    # -------------------------------------------------------------------------
    # 4c. Copy paper feature patches (renumbered, skip branding/warnings)
    # -------------------------------------------------------------------------
    report ""
    report "--- Paper Feature Patches ---"
    local asp_paper_features="$ASP_DIR/aspaper-server/paper-patches/features"
    if [ -d "$asp_paper_features" ]; then
        local counter=$((paper_max + 1))
        for patch in "$asp_paper_features"/*.patch; do
            [ -f "$patch" ] || continue
            local basename=$(basename "$patch")
            local patch_name="${basename#[0-9]*-}" # Remove number prefix

            # Skip branding and warning patches
            if echo "$basename" | grep -qiE "branding|warning|old-swm"; then
                log_warn "Skipping non-functional patch: $basename"
                report "  [SKIP] $basename (branding/warning)"
                continue
            fi

            local new_name=$(printf "%04d-%s" "$counter" "$patch_name")
            cp "$patch" "$paper_features_dir/$new_name"

            log_ok "Copied paper feature: $basename -> $new_name"
            report "  [OK] $basename -> $new_name"
            counter=$((counter + 1))
        done
    fi

    # -------------------------------------------------------------------------
    # 4d. Copy paper file-level patches (source patches for specific files)
    # Skip Metrics.java.patch (branding change)
    # -------------------------------------------------------------------------
    report ""
    report "--- Paper File Patches ---"
    local asp_paper_files="$ASP_DIR/aspaper-server/paper-patches/files"
    if [ -d "$asp_paper_files" ]; then
        local count=0
        while IFS= read -r -d '' patch; do
            local rel_path="${patch#$asp_paper_files/}"

            # Skip branding patches
            if echo "$rel_path" | grep -qi "Metrics"; then
                log_warn "Skipping branding file patch: $rel_path"
                report "  [SKIP] $rel_path (branding/metrics)"
                continue
            fi

            local dest="$paper_files_dir/$rel_path"
            mkdir -p "$(dirname "$dest")"
            cp "$patch" "$dest"
            count=$((count + 1))
            log_ok "Copied paper file patch: $rel_path"
            report "  [OK] $rel_path"
        done < <(find "$asp_paper_files" -name "*.patch" -print0)
        log_ok "Copied $count paper file patches"
    fi

    report ""
}

# =============================================================================
# Phase 5: Try to build and apply patches
# =============================================================================
phase5_build() {
    log_info "Phase 5: Attempting to apply all patches via Gradle..."
    report "--- Build Attempt ---"

    cd "$LEAF_DIR"

    # Make gradlew executable
    chmod +x gradlew

    log_info "Running ./gradlew applyAllPatches..."
    if ./gradlew applyAllPatches --stacktrace 2>&1 | tee "$SCRIPT_DIR/build-output.log"; then
        log_ok "applyAllPatches succeeded!"
        report "  [OK] ./gradlew applyAllPatches - SUCCESS"
        return 0
    else
        log_error "applyAllPatches failed. Check build-output.log for details."
        report "  [FAIL] ./gradlew applyAllPatches - FAILED (see build-output.log)"
        return 1
    fi
}

# =============================================================================
# Phase 6: Fallback - apply patches manually to source
# =============================================================================
phase6_manual_apply() {
    log_info "Phase 6: Attempting manual patch application..."
    report ""
    report "--- Manual Patch Application ---"

    cd "$LEAF_DIR"

    # First, try applying patches without the ASP-specific ones to get the base source
    log_info "Temporarily removing ASP patches to get clean Leaf source..."

    # Backup ASP patches
    local backup_dir="$WORK_DIR/asp-patches-backup"
    mkdir -p "$backup_dir"

    # Backup and remove source patches
    if [ -d "$LEAF_DIR/leaf-server/minecraft-patches/sources" ]; then
        cp -r "$LEAF_DIR/leaf-server/minecraft-patches/sources" "$backup_dir/mc-sources"
        rm -rf "$LEAF_DIR/leaf-server/minecraft-patches/sources"
    fi

    # Backup and remove ASP feature patches (they have higher numbers)
    local mc_features_dir="$LEAF_DIR/leaf-server/minecraft-patches/features"
    local paper_features_dir="$LEAF_DIR/leaf-server/paper-patches/features"
    local paper_files_dir="$LEAF_DIR/leaf-server/paper-patches/files"

    mkdir -p "$backup_dir/mc-features" "$backup_dir/paper-features" "$backup_dir/paper-files"

    # Move ASP minecraft feature patches (0195+)
    for f in "$mc_features_dir"/019[5-9]-*.patch "$mc_features_dir"/02[0-9][0-9]-*.patch; do
        [ -f "$f" ] && mv "$f" "$backup_dir/mc-features/"
    done

    # Move ASP paper feature patches (0046+)
    for f in "$paper_features_dir"/004[6-9]-*.patch "$paper_features_dir"/005[0-9]-*.patch; do
        [ -f "$f" ] && mv "$f" "$backup_dir/paper-features/"
    done

    # Move paper file patches
    if [ -d "$paper_files_dir" ]; then
        cp -r "$paper_files_dir/"* "$backup_dir/paper-files/" 2>/dev/null || true
        rm -rf "$paper_files_dir"
    fi

    # Try to build clean Leaf first
    log_info "Building clean Leaf to get patched source..."
    if ./gradlew applyAllPatches --stacktrace 2>&1 | tee "$SCRIPT_DIR/clean-build-output.log"; then
        log_ok "Clean Leaf build succeeded!"
        report "  [OK] Clean Leaf applyAllPatches succeeded"
    else
        log_error "Even clean Leaf build failed. Cannot proceed."
        report "  [FAIL] Clean Leaf build failed - cannot proceed with manual application"

        # Restore patches
        restore_asp_patches "$backup_dir"
        return 1
    fi

    # Now apply ASP patches manually to the generated source
    log_info "Applying ASP patches to generated source..."

    # Find the generated minecraft source directory
    local mc_src=""
    for candidate in \
        "$LEAF_DIR/.gradle/caches/paperweight/upstreams/leaf/leafMinecraft/src/main/java" \
        "$LEAF_DIR/leaf-server/src/minecraft/java" \
        "$LEAF_DIR/.gradle/caches/paperweight"/**/src/main/java; do
        if [ -d "$candidate" ]; then
            mc_src="$candidate"
            break
        fi
    done

    if [ -z "$mc_src" ]; then
        # Search more broadly
        mc_src=$(find "$LEAF_DIR" -path "*/src/minecraft/java/net/minecraft" -type d 2>/dev/null | head -1 | sed 's|/net/minecraft||')
        if [ -z "$mc_src" ]; then
            mc_src=$(find "$LEAF_DIR/.gradle" -path "*/src/main/java/net/minecraft" -type d 2>/dev/null | head -1 | sed 's|/net/minecraft||')
        fi
    fi

    if [ -n "$mc_src" ]; then
        log_ok "Found minecraft source at: $mc_src"
        report "  [OK] Minecraft source found at: $mc_src"

        # Apply source patches manually
        apply_source_patches "$mc_src" "$backup_dir/mc-sources"
    else
        log_warn "Could not find generated minecraft source directory"
        report "  [WARN] Could not locate minecraft source - trying feature-only approach"
    fi

    # Find the generated paper source directory
    local paper_src=""
    for candidate in \
        "$LEAF_DIR/paper-server/src/main/java" \
        "$LEAF_DIR/.gradle/caches/paperweight"/**/paper-server/src/main/java; do
        if [ -d "$candidate" ]; then
            paper_src="$candidate"
            break
        fi
    done

    if [ -z "$paper_src" ]; then
        paper_src=$(find "$LEAF_DIR" -path "*/paper-server/src/main/java/org/bukkit" -type d 2>/dev/null | head -1 | sed 's|/org/bukkit||')
    fi

    if [ -n "$paper_src" ]; then
        log_ok "Found paper source at: $paper_src"
        report "  [OK] Paper source found at: $paper_src"

        # Apply file patches manually
        apply_file_patches "$paper_src" "$backup_dir/paper-files"
    fi

    # Now restore ASP patches and try the full build
    restore_asp_patches "$backup_dir"

    # Restore source patches
    if [ -d "$backup_dir/mc-sources" ]; then
        mkdir -p "$LEAF_DIR/leaf-server/minecraft-patches/sources"
        cp -r "$backup_dir/mc-sources/"* "$LEAF_DIR/leaf-server/minecraft-patches/sources/"
    fi

    log_info "Attempting full build with all patches..."
    if ./gradlew applyAllPatches --stacktrace 2>&1 | tee "$SCRIPT_DIR/full-build-output.log"; then
        log_ok "Full build with ASP patches succeeded!"
        report "  [OK] Full build with ASP patches - SUCCESS"
    else
        log_warn "Full build failed - some patches may need manual adjustment"
        report "  [WARN] Full build failed - manual adjustment may be needed"
        report "  Check full-build-output.log for details"
    fi
}

apply_source_patches() {
    local src_dir="$1"
    local patches_dir="$2"

    [ -d "$patches_dir" ] || return

    while IFS= read -r -d '' patch; do
        local rel_path="${patch#$patches_dir/}"
        local target_file="$src_dir/${rel_path%.patch}" # Remove .patch extension

        if [ -f "$target_file" ]; then
            log_info "Applying source patch to: $rel_path"

            # Try with decreasing strictness
            if patch -p1 --forward --directory="$src_dir" < "$patch" 2>/dev/null; then
                log_ok "Applied: $rel_path (exact)"
                report "  [OK] Source patch applied (exact): $rel_path"
            elif patch -p1 --forward --fuzz=3 --directory="$src_dir" < "$patch" 2>/dev/null; then
                log_ok "Applied: $rel_path (fuzz=3)"
                report "  [OK] Source patch applied (fuzz=3): $rel_path"
            else
                log_warn "Failed to apply source patch: $rel_path"
                report "  [FAIL] Source patch failed: $rel_path"
            fi
        else
            log_warn "Target file not found for patch: $rel_path -> $target_file"
            report "  [WARN] Target not found: $rel_path"
        fi
    done < <(find "$patches_dir" -name "*.patch" -print0)
}

apply_file_patches() {
    local src_dir="$1"
    local patches_dir="$2"

    [ -d "$patches_dir" ] || return

    while IFS= read -r -d '' patch; do
        local rel_path="${patch#$patches_dir/}"

        log_info "Applying file patch: $rel_path"

        if patch -p1 --forward --directory="$src_dir" < "$patch" 2>/dev/null; then
            log_ok "Applied file patch: $rel_path (exact)"
            report "  [OK] File patch applied: $rel_path"
        elif patch -p1 --forward --fuzz=3 --directory="$src_dir" < "$patch" 2>/dev/null; then
            log_ok "Applied file patch: $rel_path (fuzz=3)"
            report "  [OK] File patch applied (fuzz=3): $rel_path"
        else
            log_warn "Failed to apply file patch: $rel_path"
            report "  [FAIL] File patch failed: $rel_path"
        fi
    done < <(find "$patches_dir" -name "*.patch" -print0)
}

restore_asp_patches() {
    local backup_dir="$1"

    # Restore ASP minecraft feature patches
    for f in "$backup_dir/mc-features/"*.patch; do
        [ -f "$f" ] && cp "$f" "$LEAF_DIR/leaf-server/minecraft-patches/features/"
    done

    # Restore ASP paper feature patches
    for f in "$backup_dir/paper-features/"*.patch; do
        [ -f "$f" ] && cp "$f" "$LEAF_DIR/leaf-server/paper-patches/features/"
    done

    # Restore paper file patches
    if [ -d "$backup_dir/paper-files" ] && [ "$(ls -A "$backup_dir/paper-files" 2>/dev/null)" ]; then
        mkdir -p "$LEAF_DIR/leaf-server/paper-patches/files"
        cp -r "$backup_dir/paper-files/"* "$LEAF_DIR/leaf-server/paper-patches/files/" 2>/dev/null || true
    fi
}

# =============================================================================
# Main execution
# =============================================================================
main() {
    log_info "=== ASP -> Leaf Integration Script ==="
    log_info "Working directory: $SCRIPT_DIR"
    echo ""

    phase1_clone
    echo ""

    phase2_copy_modules
    echo ""

    phase3_build_integration
    echo ""

    phase4_apply_patches
    echo ""

    if phase5_build; then
        log_ok "=== Integration completed successfully! ==="
    else
        log_warn "Direct build failed. Attempting manual patch application..."
        echo ""
        phase6_manual_apply
    fi

    echo ""
    report ""
    report "=== End of Report ==="

    log_info "Report saved to: $REPORT_FILE"
    log_info "Build logs saved to: $SCRIPT_DIR/build-output.log"

    echo ""
    cat "$REPORT_FILE"
}

main "$@"
