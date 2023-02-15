#!/bin/bash

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

for repo in $(find $ODOOHOME -mindepth 2 -maxdepth 2 -name ".git")
do
	stripped_repo=${repo%."git"}
	echo "Pulling $(basename $stripped_repo)"
	git -C "$stripped_repo" pull --rebase > /dev/null
done

for repo in $(find $MULTIVERSEPATH -name ".git" | sort)
do
	stripped_repo=${repo%."git"}
	version=$(basename $(dirname $stripped_repo))
	if [[ $version =~ ^(master|saas-[0-9]+.[1-4]|[0-9]+.0)$ ]]; then
		echo "Pulling $(basename $(dirname $stripped_repo))/$(basename $stripped_repo)"
		git -C "$stripped_repo" pull --rebase > /dev/null
	else
		echo "Skipped $version"
	fi
done