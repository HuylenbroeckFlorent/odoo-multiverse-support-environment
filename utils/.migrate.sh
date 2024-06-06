#!/bin/bash

## TODO Check for intermediate versions

migrate-help() {
    echo "NAME"
    echo -e "\t migrate - migrate a database to a newer version of Odoo."
    echo "DESCRIPTION"
    echo -e "\t Migrates a database to a specified version of Odoo. The original"
    echo -e "\t database will be kept, a copy will be migrated."
    echo "SYNOPSIS:"
    echo -e '\t migrate <database> <target_version>'
    echo -e "\t\t migrate a copy of the PSQL database 'database' to the version 'target_version'."
}

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

# Display help message if --help or -h is passed as argument.
if [[ $# -gt 0 ]] && [[ $1 =~ ^("-h"|"--help")$ ]]; then
    migrate-help
    exit 0
fi

# Check args
if [ "$#" -ne 2  ]; then
    echo "Wrong number of arguments specified."
    echp "Run --help for help"
    exit 1
fi

cd "$MULTIVERSEPATH/$2" || exit 1

vnumber=${2%%".0"}

echo "Copying database $1 to $1-$vnumber"

# Drop database if it exists then (re-)create it.
dropdb "$1-$vnumber" 2> /dev/null
createdb -T "$1" "$1-$vnumber"

# Add symlink to upgrade repo.
# rm -f "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"
# ln -s "$MULTIVERSEPATH/master/upgrade/" "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"

# Migrate the db.
$MULTIVERSEPATH/$2/odoo/odoo-bin    -d "$1-$vnumber" \
                                    -u all \
                                    --addons-path=$MULTIVERSEPATH/$2/odoo/addons,$MULTIVERSEPATH/$2/enterprise,$MULTIVERSEPATH/$2/design-themes \
                                    --upgrade-path=$MULTIVERSEPATH/master/upgrade-util/src,$MULTIVERSEPATH/master/upgrade/migrations \
                                    --stop-after-init

# Remove symlink to upgrade repo.
# rm -f "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"