#!/bin/bash

pull-help() {
	echo "NAME"
	echo -e "\t pull-all - pull and rebase all version of Odoo in '$MULTIVERSEPATH'."
	echo "DESCRIPTION"
	echo -e "\t Pulls and rebases all the official repos of Odoo."
	echo -e "\t Local branches will be skipped."
	echo "SYNOPSIS:"
	echo -e '\t pull-all'
	echo -e "\t\t pulls and rebases all version of Odoo in '$MULTIVERSEPATH'."
}
# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

# Display help message if --help or -h is passed as argument.
if [[ $# -gt 0 ]] && [[ $1 =~ ^("-h"|"--help")$ ]]; then
    pull-help
    exit 0
fi

for repo in $(find $ODOOHOME -mindepth 2 -maxdepth 4 -not -path "$MULTIVERSEPATH/*" -name ".git")
do
	stripped_repo=${repo%."git"}
	echo "Pulling ${stripped_repo##$ODOOHOME/}"
	git -C "$stripped_repo" pull --rebase > /dev/null
done

for repo in $(find $MULTIVERSEPATH -name ".git" | sort)
do
	stripped_repo=${repo%."git"}
	version=$(basename $(dirname $stripped_repo))
	if [[ $version =~ ^(master|saas-[0-9]+.[1-4]|[0-9]+.0)$ ]]; then
		echo "Pulling ${stripped_repo##$MULTIVERSEPATH/}"
		git -C "$stripped_repo" pull --rebase > /dev/null
	else
		echo "Skipped $version"
	fi
done