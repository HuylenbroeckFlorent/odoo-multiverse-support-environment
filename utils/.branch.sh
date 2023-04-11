#!/bin/bash

branch-help() {
	echo "NAME"
	echo -e '\t branch - add/create/delete branches inside the multiverse setup.'
	echo "DESCRIPTION"
	echo -e "\t Allows to manage branches inside the multiverse setup ($ODOOHOME/src)."
	echo -e "\t Official versions branches can be added using 'add', new branches can be"
	echo -e "\t created from an existing version using 'new', and branches can be deleted"
	echo -e "\t using 'rm'."
	echo "SYNOPSIS:"
	echo -e '\t branch add <version> [versions...]'
	echo -e '\t\t create a new branch corresponding to each given version (Official Odoo versions).'
	echo
	echo -e '\t branch new <version> <name>'
	echo -e "\t\t creates a new branch from version 'version' named 'version-name'."
	echo
	echo -e '\t branch rm <name> [names...]'
	echo -e '\t\t deletes branches corresponding to each given branch name.'
}

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run $ODOOHOME/.init.sh"
    exit 1
fi

# Check that enough valid arguments were provided
if ! [[ $# -gt 0 ]]; then
	echo "No argument provided"
	echo "Type --help for help"
	exit 1
fi

# Display help message if --help or -h is passed as argument.
if [[ $# -gt 0 ]] && [[ $1 =~ ^("-h"|"--help")$ ]]; then
    branch-help
    exit 0
fi

# Check that a valid action was selected
actions=(add rm new)
if ! [[ " "${actions[@]}" " == *" "$1" "* ]]; then
	echo "Invalid action"
	echo "Valid actions are : ${actions[@]}"
	echo "Type --help for help"
	exit 1
fi

action=$1
shift

if ! [[ $# -gt 0 ]]; then
	echo "Missing argument for action $action"
	echo "Type --help for help"
	exit 1
fi

### Manage different actions

# Add existing branch(es)
if [[ $action == "add" ]]; then
	for version in $@
	do
		if [[ $version =~ (master|saas-[0-9]+.[1-4]|[0-9]+.0) ]]; then
			mkdir -p "$MULTIVERSEPATH/$version"
		    for i in "odoo" "enterprise" "design-themes"
		    do
		        git -C "$MULTIVERSEPATH/master/$i" fetch "$i" "$version"
		        git -C "$MULTIVERSEPATH/master/$i" worktree add --track -b "$version" "$MULTIVERSEPATH/$version/$i" "$i/$version"
		        
		        if [[ $i == "odoo" ]]; then
		        	if ! [ -d "$MULTIVERSEPATH/$version/$i/.venv" ]; then
						virtualenv $MULTIVERSEPATH/$version/$i/.venv >/dev/null
					fi
					source $MULTIVERSEPATH/$version/$i/.venv/bin/activate
					python3 -c "import pkg_resources; pkg_resources.require(open('$MULTIVERSEPATH/$version/$i/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo "Installing $i requirements in virtual environment..." && pip3 install -r "$MULTIVERSEPATH/$version/$i/requirements.txt" >/dev/null )
					deactivate
		        fi
		    done
		else
			echo "Version '$version' not recognized"
		fi
	done
fi

# Create a new branch from an existing branch
if [[ $action == "new" ]]; then
	if [[ $1 =~ (master|saas-[0-9]+.[1-4]|[0-9]+.0) ]] && [[ $# -gt 0 ]]; then
		version=$1
		shift
		name="$version-$1"
		echo "Create a new $version branch named '$name' ? (y/n)"
		read answer
		positive_answers=(yes y ok oui Y YES OK)
		if [[ " "${positive_answers[@]}" " == *" "$answer" "* ]]; then
			mkdir -p "$MULTIVERSEPATH/$name"
		    for i in "odoo" "enterprise" "design-themes"
		    do
		        git -C "$MULTIVERSEPATH/master/$i" fetch "$i" "$version"
		        git -C "$MULTIVERSEPATH/master/$i" worktree add --track -b "$name" "$MULTIVERSEPATH/$name/$i" "$i/$version"

		        if [[ $i == "odoo" ]]; then
		        	if ! [ -d "$MULTIVERSEPATH/$name/$i/.venv" ]; then
						virtualenv $MULTIVERSEPATH/$name/$i/.venv >/dev/null
					fi
					source $MULTIVERSEPATH/$name/$i/.venv/bin/activate
					python3 -c "import pkg_resources; pkg_resources.require(open('$MULTIVERSEPATH/$name/$i/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo "Installing $i requirements in virtual environment..." && pip3 install -r "$MULTIVERSEPATH/$name/$i/requirements.txt" >/dev/null ) 
					deactivate
		        fi
		    done
		else
			echo "Aborted."
			exit 1
		fi
	else
		echo "Version '$version' not recognized."
		exit 1
	fi
fi

# Remove branches
if [[ $action == "rm" ]]; then
	for name in $@
	do
		if [[ -d $MULTIVERSEPATH/$name ]]; then
			for i in "odoo" "enterprise" "design-themes"
		    do
		        git -C "$MULTIVERSEPATH/master/$i" worktree remove "$MULTIVERSEPATH/$name/$i" 2>/dev/null
		        git -C "$MULTIVERSEPATH/master/$i" branch -d $name 2>/dev/null
		        git -C "$MULTIVERSEPATH/master/$i" worktree prune 2>/dev/null
		    done
		    rm -r "$MULTIVERSEPATH/$name"
		else
			echo "Branch '$name' not found in the worktree."
		fi
	done
fi