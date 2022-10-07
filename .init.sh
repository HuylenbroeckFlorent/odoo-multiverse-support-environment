#!/bin/bash

# Ensure we create multiverse inside user's home
home_matching="$HOME/.*$"
if ! [[ "$(pwd)" =~ $home_matching ]]; then
	echo "Please execute in a subdirectory of $HOME"
	exit 1
fi

# Disclaimer
echo "Some command will require root privilege or user interaction (installing git, psql or python and its libraries)"


# Check for git installation
git_matching="git version.*$"
if ! [[ "$(git --version)" =~ $git_matching ]]; then
	sudo apt install git
fi

# Checking for python installation
py3_matching="Python 3.*$"
if ! [[ "$(python3 --version)" =~ $py3_matching ]]; then
	sudo apt install python3
fi

# Checking for psql installation
psql_matching="psql \(PostgreSQL\).*$"
if ! [[ "$(psql --version)" =~ $psql_matching ]]; then
	sudo apt install postgresql postgresql-client
fi

# Paths
odoohome=$(pwd)
worktreesrc="$odoohome/src/master"

# Cloning and configuring odoo/support-tools
git clone --branch "master" git@github.com:odoo/support-tools.git
cd "$odoohome/support-tools"
# Check if requirements are met, else install them.
python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || sudo pip3 install -r "requirements.txt" # https://stackoverflow.com/a/65606063

# Cloning odoo/internal
cd "$odoohome"
git clone --branch "master" git@github.com:odoo/internal.git
$odoohome/support-tools/oe-support.py config internal "$odoohome/internal"

### Creating multiverse worktree
mkdir -p $worktreesrc
$odoohome/support-tools/oe-support.py config worktree-src "$worktreesrc"
cd $worktreesrc

# Cloning odoo/odoo, odoo/enterprise, odoo/design-themes, odoo/upgrade master branches
for i in "odoo" "enterprise" "design-themes" "upgrade"
do
	git clone --branch "master" "git@github.com:odoo/$i.git"

	# Check if requirements dor odoo and upgrade are met, else install them.
	if [[ $i =~ (odoo|upgrade)$ ]]; then
		pushd "$i"
		python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || sudo pip3 install -r "requirements.txt"
		popd
	fi
done

sed -i "/export ODOOHOME=.*/d" $ODOOHOME/utils/.multiverserc
echo "export ODOOHOME=$ODOOHOME" >> $ODOOHOME/utils/.multiverserc
sed -i '/source.*multiverserc/d' $HOME/.bashrc
echo "source $ODOOHOME/utils/.multiverserc" >> $HOME/.bashrc
source $HOME/.bashrc
