#!/bin/zsh

##
##  update-brotli.zsh
##  swift-brotli
##
##  Created by Fang Ling on 2026/3/14.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
##

# This script creates a copy of brotli that is suitable for building with the
# Swift Package Manager.
#
# Usage:
#   Run this script in the package root. It will place a local copy of the
#   brotli sources in Sources/CBrotli.
#   Any prior contents of Sources/CBrotli will be deleted.
#

set -euo pipefail

CURRENT_WORKING_DIRECTORY=$(pwd)
TEMPORARY_DIRECTORY=$(mktemp -d /tmp/swift-brotli-XXXXXX)
SOURCE_DIRECTORY="${TEMPORARY_DIRECTORY}/Sources/brotli"
DESTINATION_DIRECTORY="Sources/CBrotli"
TRASH_DIRECTORY="${TEMPORARY_DIRECTORY}/Trash"
SOURCES=(
  "common/*.c"
  "common/*.h"
  "dec/*.c"
  "dec/*.h"
  "enc/*.c"
  "enc/*.h"
)

# Brotli revision must be passed as the first argument to this script.
if [ "$#" -gt 0 ]; then
  BROTLI_REVISION="$1"
else
  echo "Usage: $0 <brotli-revision>"
  exit 1
fi

echo "=========================================="
echo "TRASHING any previously-copied brotli code"
echo "=========================================="
mkdir -p "${TRASH_DIRECTORY}/CBrotli"
mv "${DESTINATION_DIRECTORY}/"* "${TRASH_DIRECTORY}/CBrotli" || true

echo "================"
echo "PREPARING brotli"
echo "================"
mkdir -p "${SOURCE_DIRECTORY}"
git clone https://github.com/google/brotli.git "${SOURCE_DIRECTORY}"
cd "${SOURCE_DIRECTORY}"
git checkout "${BROTLI_REVISION}"
cd "${CURRENT_WORKING_DIRECTORY}"

echo "=============="
echo "COPYING brotli"
echo "=============="
mkdir -p "${DESTINATION_DIRECTORY}/brotli"
for SOURCE in "${SOURCES[@]}"
do
  for FILE in "${SOURCE_DIRECTORY}/c/"${~SOURCE}
  do
    FILE_PATH=${FILE#"$SOURCE_DIRECTORY"}
    DESTINATION="${DESTINATION_DIRECTORY}/brotli${FILE_PATH}"
    mkdir -p $(dirname "${DESTINATION}")

    cp "${FILE}" "${DESTINATION}"
  done
done
mv "${DESTINATION_DIRECTORY}/brotli/c/"* "${DESTINATION_DIRECTORY}/brotli"
rmdir "${DESTINATION_DIRECTORY}/brotli/c"
cp -r "${SOURCE_DIRECTORY}/c/include" "${DESTINATION_DIRECTORY}/include"
cp "${SOURCE_DIRECTORY}/LICENSE" "${DESTINATION_DIRECTORY}/LICENSE.txt"

echo "========================="
echo "RECORDING brotli revision"
echo "========================="
cat << EOF > "${DESTINATION_DIRECTORY}/revision.txt"
This directory is derived from brotli
  cloned from https://github.com/google/brotli.git
EOF
echo "at revision ${BROTLI_REVISION}" >> "${DESTINATION_DIRECTORY}/revision.txt"

echo "============================"
echo "CLEANING temporary directory"
echo "============================"
rm -rf "${TEMPORARY_DIRECTORY}"
