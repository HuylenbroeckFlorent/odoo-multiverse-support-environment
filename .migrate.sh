#!/bin/bash

## TODO Check for intermediate versions

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please append \"export \$MULTIVERSEPATH=<path-to-src>\" to $HOME/.bashrc and run 'source $HOME/.bashrc'"
    exit 1
fi

# Check args
if [ "$#" -ne 2  ]; then
    echo ".migrate: Create a duplicate of <database> called <database-target_version> and migrate it to the target version."
    echo ""
    echo "Usage: .migrate <database> <target_version>"
    exit 1
fi

echo "Copying database $1 to $1-$2"

# Drop database if it exists then (re-)create it.
dropdb "$1-$2" 2> /dev/null
createdb -T "$1" "$1-$2"

# Add symlink to upgrade repo.
rm -f "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"
ln -s "$MULTIVERSEPATH/master/upgrade/" "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"

# Migrate the db.
$MULTIVERSEPATH/$2/odoo/odoo-bin -d "$1-$2" -u all --addons-path=$MULTIVERSEPATH/$2/odoo/addons,$MULTIVERSEPATH/$2/enterprise,$MULTIVERSEPATH/$2/design-themes --stop-after-init

# Remove symlink to upgrade repo.
rm -f "$MULTIVERSEPATH/$2/odoo/odoo/addons/base/maintenance"