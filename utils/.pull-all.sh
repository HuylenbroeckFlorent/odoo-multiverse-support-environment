#!/bin/bash

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

for repo in $(find $ODOOHOME -mindepth 2 -name ".git" | sort)
do
	stripped_repo=${repo%."git"}
	if [[ $stripped_repo =~ "$MULTIVERSEPATH".*$ ]]; then
		echo "Pulling $(basename $(dirname $stripped_repo))/$(basename $stripped_repo)"
	else
		echo "Pulling $(basename $stripped_repo)"
	fi
	git -C "$stripped_repo" pull --rebase > /dev/null
done