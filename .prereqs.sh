#!/bin/bash

# Disclaimer
echo "Starting"
echo "NOTE : some command might require root privilege or user interaction (installing git, psql or python)"

# Check for git installation
echo -e "\t Checking Git installation"
git_matching="git version.*$"
if ! [[ "$(git --version)" =~ $git_matching ]]; then
	sudo apt install git
fi

# Checking for python installation
echo -e "\t Checking python installation"
py3_matching="Python 3.*$"
if ! [[ "$(python3 --version)" =~ $py3_matching ]]; then
	sudo apt install python3
	sudo apt install python3-pip
fi

# Checking for psql installation
echo -e "\t Checking PSQL installation and users"
psql_matching="psql \(PostgreSQL\).*$"
if ! [[ "$(psql --version)" =~ $psql_matching ]]; then
	sudo apt install postgresql postgresql-client
fi

# Checking for psql user and its roles
if ! [[ "$(psql postgres -tAc "SELECT * FROM pg_roles WHERE rolname='$USER'")" =~ ^"$USER"\|t\|t\|(t|f|)\|t\|t\|(t|f|)\|(-?[0-9]*|)\|(\**|)\|(t|f|)\|(t|f|)\|(t|f|)\|([0-9]*|)$ ]]; then
	sudo -u postgres psql -U postgres -c "CREATE USER $USER;"
	sudo -u postgres psql -U postgres -c "ALTER USER $USER SUPERUSER CREATEDB INHERIT LOGIN"
	createdb "$USER"
fi

# Checking for trial psql user
psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='trial'" | grep -q 1 || sudo -u postgres psql -U postgres -c "CREATE USER trial;"

echo "Done"
