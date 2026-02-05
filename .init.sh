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
odoofin_version="19.0"

### Cloning odoo/internal
echo -e "\t Cloning odoo/internal"
cd "$odoohome"
git clone --branch "master" git@github.com:odoo/internal.git 2> /dev/null
psql -l | grep -q meta || createdb meta > /dev/null
psql -l | grep -q meta && psql meta < $odoohome/internal/setup/meta.sql > /dev/null 2>&1

# Cloning odoo/odoofin
echo -e "\t Cloning odoo/odoofin"
git clone --branch "$odoofin_version" "git@github.com:odoo/odoofin.git" odoofin/odoo/addons 2> /dev/null
if [[ ! -d $odoohome/.venv/src/$odoofin_version ]]; then
	python3 -m venv --system-site-packages "$odoohome/.venv/src/$odoofin_version"
fi
source $odoohome/.venv/src/$odoofin_version/bin/activate
python3 -c "import pkg_resources; pkg_resources.require(open('$odoohome/odoofin/odoo/addons/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo -e "\t\t Installing odoofin requirements" && pip3 install -r "$odoohome/odoofin/odoo/addons/requirements.txt" >/dev/null) 
deactivate

### Cloning odoo/support-tools
echo -e "\t Cloning odoo/support-tools"
git clone --branch "master" git@github.com:odoo/support-tools.git 2> /dev/null

# Configuring support-tools.
echo -e "\t Configuring support-tools"
if [[ ! -d $odoohome/.venv/support-tools ]]; then
	python3 -m venv --system-site-packages "$odoohome/.venv/support-tools"
fi	
source $odoohome/.venv/support-tools/bin/activate
python3 -c "import pkg_resources; pkg_resources.require(open('$odoohome/support-tools/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo -e "\t\t Installing support-tools requirements" && pip3 install -r "$odoohome/support-tools/requirements.txt" >/dev/null) 

### Creating multiverse worktree
mkdir -p $worktreesrc
mkdir -p $odoohome/.venv/src
echo -e "\t\t Settings config keys"
$odoohome/support-tools/oe-support.py config worktree-src "$worktreesrc" >/dev/null
$odoohome/support-tools/oe-support.py config src "$odoohome/src" >/dev/null
$odoohome/support-tools/oe-support.py config venvs-dir "$odoohome/.venv/src" >/dev/null
$odoohome/support-tools/oe-support.py config internal "$odoohome/internal" >/dev/null
deactivate
echo -e "\t Configuring multiverse worktree"

# Cloning odoo/odoo, odoo/enterprise, odoo/design-themes, odoo/upgrade odoo/upgrade-util master branches
cd $worktreesrc
for i in "odoo" "enterprise" "design-themes" "upgrade" "upgrade-util"
do
	echo -e "\t Cloning odoo/$i"
	git clone --branch "master" "git@github.com:odoo/$i.git" 2> /dev/null

	git -C "$worktreesrc/$i" remote rename origin $i 2> /dev/null
	git -C "$worktreesrc/$i" remote set-url --push $i no_push
	if [[ $i =~ (odoo|enterprise)$ ]]; then
		git -C "$worktreesrc/$i" remote add $i-dev git@github.com:odoo-dev/$i.git 2> /dev/null
	fi

	# Check if requirements for odoo and upgrade are met, else install them.
	if [[ $i =~ (odoo|upgrade)$ ]]; then
		if [[ ! -d $odoohome/.venv/src/master ]]; then
    		python3 -m venv --system-site-packages "$odoohome/.venv/src/master"
    	fi
		source $odoohome/.venv/src/master/bin/activate
		python3 -c "import pkg_resources; pkg_resources.require(open('$worktreesrc/$i/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo -e "\t\t Installing $i requirements" && pip3 install -r "$worktreesrc/$i/requirements.txt" >/dev/null)
		deactivate
	fi
done

# Exporting to ~/.bashrc
echo -e "\t Exporting to $HOME/.bashrc"
sed -i "/export ODOOHOME=.*/d" $HOME/.bashrc
sed -i "/export ODOOFIN_VERSION=.*/d" $HOME/.bashrc
sed -i '/source.*multiverserc/d' $HOME/.bashrc
echo "export ODOOHOME=$odoohome" >> $HOME/.bashrc
echo "export ODOOFIN_VERSION=$odoofin_version" >> $HOME/.bashrc
echo "source $odoohome/utils/.multiverserc" >> $HOME/.bashrc
source $HOME/.bashrc

echo "Done"
