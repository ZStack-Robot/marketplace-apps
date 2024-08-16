#!/bin/bash
set -e

ARCHIVE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0)
REPO_PATH="${1:-/opt/zstack-marketplace-repo/}"

if [ ! -d $REPO_PATH ]; then
    echo "Error: repo path not found"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

tail -n+$ARCHIVE $0 | tar xzv -C "$TEMP_DIR" > /dev/null

cd "$TEMP_DIR"

if [ -f "info" ]; then
    source ./info
else
    echo "Error: info file not found"
    exit 1
fi

if [ -z "$APP_ID" ] || [ -z "$VERSION" ] || [ -z "$ARCH" ]; then
    echo "Error: APP_ID, VERSION, or ARCH not set in info file"
    exit 1
fi

REPO_APP_PATH="$REPO_PATH"/"$APP_ID"/"$ARCH"/"$VERSION"

mkdir -p $REPO_APP_PATH
mv -f application.tar.gz $REPO_APP_PATH/
if [ -f  image.qcow2 ];then
    mv -f image.qcow2 $REPO_APP_PATH/
fi

PYTHON_EXEC=${MARKETPLACE_REPO_PYTHON_EXEC:-python}
$PYTHON_EXEC "./refresh_index.py" --root_path $REPO_PATH 

echo "Import completed."
exit 0

# the empty line below __ARCHIVE_BELOW__ is required

__ARCHIVE_BELOW__
