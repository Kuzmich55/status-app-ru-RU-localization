#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
QMLLINT="${QTDIR}/bin/qmllint"

[[ ! -x "$QMLLINT" ]] && QMLLINT="${QTDIR}/libexec/qmllint"

if [[ ! -x "$QMLLINT" ]]; then
    echo "Error: qmllint not found at $QMLLINT"
    echo "Set QTDIR environment variable to your Qt installation path"
    exit 1
fi

echo "Using qmllint: $QMLLINT"
echo "Validating QML files in: $ROOT_DIR/ui"
echo ""

# Use .qmllint.ini config file for warning settings
# Only pass import paths and max-warnings on command line
LINT_ARGS=(
    "-I" "$ROOT_DIR/ui"
    "-I" "$ROOT_DIR/ui/imports"
    "-I" "$ROOT_DIR/ui/app"
    "-I" "$ROOT_DIR/ui/StatusQ/src"
    "-I" "${QTDIR}/qml"
    "--max-warnings" "0"
)

ERRORS=0
CHECKED=0
FAILED_FILES=()

while IFS= read -r -d '' qml_file; do
    CHECKED=$((CHECKED + 1))

    if ! output=$("$QMLLINT" "${LINT_ARGS[@]}" "$qml_file" 2>&1); then
        # Filter out Info: lines, only show Warning: lines
        warnings=$(echo "$output" | grep -E "^Warning:" || true)
        if [[ -n "$warnings" ]]; then
            echo "FAIL: $qml_file"
            echo "$warnings" | while IFS= read -r line; do
                printf "  %s\n" "$line"
            done
            echo ""
        fi
        FAILED_FILES+=("$qml_file")
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$ROOT_DIR/ui" -name "*.qml" -print0)

echo "Files checked: $CHECKED"
echo "Errors found: $ERRORS"

if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo "Failed files:"
    for f in "${FAILED_FILES[@]}"; do
        echo "  - $f"
    done
    echo ""
    echo "QML validation failed. Please fix the errors above."
    exit 1
fi

echo "QML is validated"
exit 0
