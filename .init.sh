#!/bin/bash

# Ensure we create multiverse inside user's home
home_matching="$HOME/.*$"
if ! [[ "$(pwd)" =~ $home_matching ]]; then
	echo "Please execute in a subdirectory of $HOME"
	exit 1
fi

# Disclaimer
echo "Some command will require root privilege or user interaction (installing git, psql or python)"

# Check for git installation
git_matching="git version.*$"
if ! [[ "$(git --version)" =~ $git_matching ]]; then
	sudo apt install git
fi

# Checking for python installation
py3_matching="Python 3.*$"
if ! [[ "$(python3 --version)" =~ $py3_matching ]]; then
	sudo apt install python3
	sudo apt install python3-pip
fi

# Checking for psql installation
psql_matching="psql \(PostgreSQL\).*$"
if ! [[ "$(psql --version)" =~ $psql_matching ]]; then
	sudo apt install postgresql postgresql-client
fi
# Checking for psql user
if ! [[ "$(psql postgres -tAc "SELECT * FROM pg_roles WHERE rolname='$USER'")" =~ ^"$USER"\|t\|t\|(t|f|)\|t\|t\|(t|f|)\|(-?[0-9]*|)\|(\**|)\|(t|f|)\|(t|f|)\|(t|f|)\|([0-9]*|)$ ]]; then
	sudo -u postgres psql -U postgres -c "CREATE USER $USER;"
	sudo -u postgres psql -U postgres -c "ALTER USER $USER SUPERUSER CREATEDB INHERIT LOGIN"
	createdb "$USER"
fi
# Checking for trial psql user
psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='trial'" | grep -q 1 || sudo -u postgres psql -U postgres -c "CREATE USER trial;"

# Paths
odoohome=$(pwd)
worktreesrc="$odoohome/src/master"

# Cloning and configuring odoo/support-tools
git clone --branch "master" git@github.com:odoo/support-tools.git
cd "$odoohome/support-tools"
# Check if requirements are met, else install them.
python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || pip3 install -r "requirements.txt" # https://stackoverflow.com/a/65606063

# Cloning odoo/internal
cd "$odoohome"
git clone --branch "master" git@github.com:odoo/internal.git
$odoohome/support-tools/oe-support.py config internal "$odoohome/internal"
createdb meta
psql meta < $odoohome/internal/setup/meta.sql

### Creating multiverse worktree
mkdir -p $worktreesrc
$odoohome/support-tools/oe-support.py config worktree-src "$worktreesrc"
$odoohome/support-tools/oe-support.py config src "$odoohome/src"
cd $worktreesrc

# Cloning odoo/odoo, odoo/enterprise, odoo/design-themes, odoo/upgrade master branches
for i in "odoo" "enterprise" "design-themes" "upgrade"
do
	git clone --branch "master" "git@github.com:odoo/$i.git"

	if [[ $i =~ odoo$ ]]; then
		pushd "$i"
		git remote add odoo-dev git@github.com:odoo-dev/odoo.git
		git remote rename origin odoo
		git remote set-url --push odoo no_push
		popd
	fi

	if [[ $i =~ enterprise$ ]]; then
		pushd "$i"
		git remote add enterprise-dev git@github.com:odoo-dev/enterprise.git
		git remote rename origin enterprise
		git remote set-url --push enterprise no_push
		popd
	fi

	if [[ $i == "design-themes" ]]; then
		pushd "$i"
		git remote rename origin design-themes
		git remote set-url --push design-themes no_push
		popd
	fi

	# Check if requirements for odoo and upgrade are met, else install them.
	if [[ $i =~ (odoo|upgrade)$ ]]; then
		pushd "$i"
		python3 -c "import pkg_resources; pkg_resources.require(open('requirements.txt',mode='r'))" || pip3 install -r "requirements.txt"
		popd
	fi
done

sed -i "/export ODOOHOME=.*/d" $HOME/.bashrc
sed -i '/source.*multiverserc/d' $HOME/.bashrc
echo "export ODOOHOME=$odoohome" >> $HOME/.bashrc
echo "source $odoohome/utils/.multiverserc" >> $HOME/.bashrc
source $HOME/.bashrc