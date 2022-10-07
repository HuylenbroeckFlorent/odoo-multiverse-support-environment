#! /bin/bash

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

if [[ "$(pwd)" =~ "$MULTIVERSEPATH"/(saas-)?[0-9]+(.[0-9])?/odoo ]]; then
	version=$(pwd)
    version=${version##$MULTIVERSEPATH/}
    version=${version%%/*}
    args="$@"
elif [[ "$(ls $MULTIVERSEPATH)" =~ ^.*"$1".*$ ]]; then
    version="$1"
    args="${@:2}"
else
    echo "Usage:"
    echo "From outside of any version's odoo directory:"
    echo "oe-odoo-bin <version> <args>"
    echo "From a specific version's odoo directory:"
    echo "oe-odoo-bin <args>"
    echo
    echo "Ensure the target version exists in your multiverse setup. You can add a version by calling oe-add-version <version>"
    exit 1
fi

echo "Running from $MULTIVERSEPATH/$version/odoo/"
$MULTIVERSEPATH/$version/odoo/odoo-bin $args "--addons-path=$MULTIVERSEPATH/$version/odoo/addons,$MULTIVERSEPATH/$version/enterprise,$MULTIVERSEPATH/$version/design-themes" --max-cron-threads=0
# ,$ODOOHOME/internal/default,$ODOOHOME/internal/trial