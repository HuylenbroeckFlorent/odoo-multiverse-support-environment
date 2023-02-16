#!/bin/bash

# Ensure we create multiverse inside user's home
home_matching="^$HOME/.*$"
if ! [[ "$(pwd)" =~ $home_matching ]]; then
	echo "Please execute in a subdirectory of $HOME"
	exit 1
fi

echo "Starting"
# Paths

odoohome=$(pwd)
worktreesrc="$odoohome/src/master"

### Cloning and configuring odoo/support-tools
echo -e "\t Init support-tools"
git clone --branch "master" git@github.com:odoo/support-tools.git 2> /dev/null
cd "$odoohome/support-tools"
# Check if requirements are met, else install them.
python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || pip3 install -r "requirements.txt" # https://stackoverflow.com/a/65606063


### Cloning odoo/internal
echo -e "\t Init internal"
cd "$odoohome"
git clone --branch "master" git@github.com:odoo/internal.git 2> /dev/null
$odoohome/support-tools/oe-support.py config internal "$odoohome/internal"
psql -l | grep -q meta || createdb meta > /dev/null
psql -l | grep -q meta && psql meta < $odoohome/internal/setup/meta.sql > /dev/null 2&>1


### Creating multiverse worktree
echo -e "\t Init multiverse worktree"
mkdir -p $worktreesrc
$odoohome/support-tools/oe-support.py config worktree-src "$worktreesrc"
$odoohome/support-tools/oe-support.py config src "$odoohome/src"
cd $worktreesrc

# Cloning odoo/odoo, odoo/enterprise, odoo/design-themes, odoo/upgrade master branches
for i in "odoo" "enterprise" "design-themes" "upgrade"
do
	git clone --branch "master" "git@github.com:odoo/$i.git" 2> /dev/null

	if [[ $i =~ odoo$ ]]; then
		pushd "$i" >/dev/null
		git remote add odoo-dev git@github.com:odoo-dev/odoo.git 2> /dev/null
		git remote rename origin odoo 2> /dev/null
		git remote set-url --push odoo no_push
		popd >/dev/null
	fi

	if [[ $i =~ enterprise$ ]]; then
		pushd "$i" >/dev/null
		git remote add enterprise-dev git@github.com:odoo-dev/enterprise.git 2> /dev/null
		git remote rename origin enterprise 2> /dev/null
		git remote set-url --push enterprise no_push
		popd >/dev/null
	fi

	if [[ $i == "design-themes" ]]; then
		pushd "$i" >/dev/null
		git remote rename origin design-themes 2> /dev/null
		git remote set-url --push design-themes no_push
		popd >/dev/null
	fi

	# Check if requirements for odoo and upgrade are met, else install them.
	if [[ $i =~ (odoo|upgrade)$ ]]; then
		pushd "$i" >/dev/null
		python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || pip3 install -r "requirements.txt"
		popd >/dev/null
	fi
done


# Exporting to ~/.bashrc
echo -e "\t Exporting to $HOME/.bashrc"
sed -i "/export ODOOHOME=.*/d" $HOME/.bashrc
sed -i '/source.*multiverserc/d' $HOME/.bashrc
echo "export ODOOHOME=$odoohome" >> $HOME/.bashrc
echo "source $odoohome/utils/.multiverserc" >> $HOME/.bashrc
source $HOME/.bashrc

echo "Done"