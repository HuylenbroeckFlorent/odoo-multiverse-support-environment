#!/bin/bash

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

for repo in $(find $ODOOHOME -mindepth 2 -name ".git")
do
	git -C "${repo%".git"}" pull
done