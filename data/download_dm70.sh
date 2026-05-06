#!/bin/bash
# --------------------------------------------------------

BASE_URL="https://dl.fbaipublicfiles.com/dailymoth-70h/"
FILES=(
    "unblurred_clips.tar.gz"
    "manifests.tar.gz"
)

CHECKSUMS=(
    "3e69046f6cf415cec89c3544d0523325  unblurred_clips.tar.gz"
    "69e500cc5cfad3133c4b589428865472  manifests.tar.gz"
)

echo "Starting download"
for file in "${FILES[@]}"; do
    wget --continue "${BASE_URL}${file}"
done

echo -e "\nVerifying checksums"
for checksum in "${CHECKSUMS[@]}"; do
    echo "$checksum" | md5sum --check
    if [ $? -ne 0 ]; then
        echo "Checksum verification failed for ${checksum##* }"
        exit 1
    fi
done


#echo -e "\nExtracting archives"
#for file in "${FILES[@]}"; do
#    tar -xvf "$file"
#done

#prefix="$(pwd)/dailymoth-70h"
#echo -e "\nCreating symlinks"
#ln -s "$prefix"/manifests "$prefix"/unblurred_clips/manifests
#ln -s "$prefix"/manifests "$prefix"/blurred_clips/manifests