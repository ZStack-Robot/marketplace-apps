#!/bin/bash
set -e

REPO_PATH="${1:-/opt/zstack-marketplace-repo/}"
ARCHIVE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0)

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="/tmp/zstack_marketplace_repo_import_${TIMESTAMP}.log"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

tail -n+$ARCHIVE $0 | tar xzv -C "$TEMP_DIR" > /dev/null

if [ ! -d "$REPO_PATH" ]; then
    echo "Creating repository directory: $REPO_PATH" | tee -a "$LOG_FILE"
    mkdir -p "$REPO_PATH"
fi

if [ -f "$TEMP_DIR/refresh_index.py" ]; then

    PYTHON_EXEC=${MARKETPLACE_REPO_PYTHON_EXEC:-python}
    $PYTHON_EXEC "$TEMP_DIR/refresh_index.py" --root_path "$REPO_PATH" | tee -a "$LOG_FILE"

    # echo "Copying refresh_index.py to $REPO_PATH" | tee -a "$LOG_FILE"
    # cp "$TEMP_DIR/refresh_index.py" "$REPO_PATH/"
else
    echo "Error: refresh_index.py not found in the extracted files" | tee -a "$LOG_FILE"
    exit 1
fi


find "$TEMP_DIR" -type f -name "*.bin" | while read -r bin_file; do
    bin_name=`basename $bin_file`
    echo "===============================================" | tee -a "$LOG_FILE"
    echo "Importing $bin_name" | tee -a "$LOG_FILE"
    bash "$bin_file" "$REPO_PATH" 2>&1 | tee -a $LOG_FILE
    echo "Import $bin_name successfully!" | tee -a "$LOG_FILE"
done

echo "All application have been imported to $REPO_PATH." | tee -a "$LOG_FILE"
exit 0

# the empty line below __ARCHIVE_BELOW__ is required

__ARCHIVE_BELOW__
