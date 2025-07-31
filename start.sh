#!/bin/bash
set -e

echo "---"
echo "🔁 Setting up persistent storage symlinks and fixing permissions..."
echo "---"

PERSISTENT_STORAGE=/workspace/storage
TARGET_DIRS=("datasets" "config" "outputs" "models")

for dir in "${TARGET_DIRS[@]}"; do
  APP_PATH="/workspace/simpletuner/${dir}"
  STORAGE_PATH="${PERSISTENT_STORAGE}/${dir}"

  mkdir -p "${STORAGE_PATH}"

  if [ -e "${APP_PATH}" ] || [ -L "${APP_PATH}" ]; then
    rm -rf "${APP_PATH}"
  fi

  ln -s "${STORAGE_PATH}" "${APP_PATH}"
  echo "Linked ${APP_PATH} -> ${STORAGE_PATH}"
done

chmod -R u+rwX "${PERSISTENT_STORAGE}"
chown -R root:root "${PERSISTENT_STORAGE}"

echo "---"
echo "🚀 Starting JupyterLab in /workspace/simpletuner"
echo "---"

cd /workspace/simpletuner

exec "$@"
