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

### Cloning odoo/support-tools
echo -e "\t Init support-tools"
git clone --branch "master" git@github.com:odoo/support-tools.git 2> /dev/null

### Cloning odoo/internal
echo -e "\t Init internal"
cd "$odoohome"
git clone --branch "master" git@github.com:odoo/internal.git 2> /dev/null
psql -l | grep -q meta || createdb meta > /dev/null
psql -l | grep -q meta && psql meta < $odoohome/internal/setup/meta.sql > /dev/null 2>&1

# Configuring support-tools.
if [[ ! -d $ODOOHOME/.venv/src/support-tools ]]; then
	python3 -m venv "$ODOOHOME/.venv/support-tools"
    sed 's/include-system-site-packages = false/include-system-site-packages = true/' "$ODOOHOME/.venv/support-tools/pyvenv.cfg" >/dev/null
fi	
source $ODOOHOME/.venv/support-tools/bin/activate
python3 -c "import pkg_resources; pkg_resources.require(open('$odoohome/support-tools/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo -e "\t\t Installing support-tools requirements..." && pip3 install -r "$odoohome/support-tools/requirements.txt" >/dev/null) 

### Creating multiverse worktree
echo -e "\t Init multiverse worktree"
mkdir -p $worktreesrc
mkdir -p $odoohome/.venv/src
$odoohome/support-tools/oe-support.py config worktree-src "$worktreesrc"
$odoohome/support-tools/oe-support.py config src "$odoohome/src"
$odoohome/support-tools/oe-support.py config venvs-dir "$odoohome/.venv/src"
$odoohome/support-tools/oe-support.py config internal "$odoohome/internal"
deactivate

# Cloning odoo/odoo, odoo/enterprise, odoo/design-themes, odoo/upgrade odoo/upgrade-util master branches
cd $worktreesrc
for i in "odoo" "enterprise" "design-themes" "upgrade" "upgrade-util"
do
	git clone --branch "master" "git@github.com:odoo/$i.git" 2> /dev/null

	git -C "$worktreesrc/$i" remote rename origin $i 2> /dev/null
	git -C "$worktreesrc/$i" remote set-url --push $i no_push
	if [[ $i =~ (odoo|enterprise)$ ]]; then
		git -C "$worktreesrc/$i" remote add $i-dev git@github.com:odoo-dev/$i.git 2> /dev/null
	fi

	# Check if requirements for odoo and upgrade are met, else install them.
	if [[ $i =~ (odoo|upgrade)$ ]]; then
		if [[ ! -d $ODOOHOME/.venv/src/master ]]; then
    		python3 -m venv "$ODOOHOME/.venv/src/master"
    		sed 's/include-system-site-packages = false/include-system-site-packages = true/' "$ODOOHOME/.venv/src/master/pyvenv.cfg" >/dev/null
    	fi
		source $odoohome/.venv/src/master/bin/activate
		python3 -c "import pkg_resources; pkg_resources.require(open('$worktreesrc/$i/requirements.txt',mode='r'))" 2>&1 | grep -q "" && (echo -e "\t Installing $i requirements." && pip3 install -r "$worktreesrc/$i/requirements.txt" >/dev/null)
		deactivate
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
