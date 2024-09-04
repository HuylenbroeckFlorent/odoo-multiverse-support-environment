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
fi

# Checking for pip installation
echo -e "\t Checkin pip installation"
pip3_matching="*/pip*"
if ! [[ "$(pip3 --version)" =~ $py3_matching ]]; then
	sudo apt install python3-pip
	sudo apt install libpq-dev
fi

# Install psycopg2 for requirement.txt install
pip3 install psycopg2-binary

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

# sudo apt install libpq-dev python3-cffi libsasl2-dev libldap2-dev libsass