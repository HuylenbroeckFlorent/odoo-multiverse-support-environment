#! /bin/bash

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

if [[ $# -gt 0 ]] && [[ $1 =~ (master|saas-[0-9]+.[1-4]|[0-9]+.0) ]] && [[ "$(ls $MULTIVERSEPATH)" =~ ^.*"$1".*$ ]]; then
    version="$1"
    shift

elif [[ "$(pwd)" =~ "$MULTIVERSEPATH"/(master|saas-[0-9]+.[1-4]|[0-9]+.0)/odoo ]]; then
    version=$(pwd)
    version=${version##$MULTIVERSEPATH/}
    version=${version%%/*}
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

# Check for --debug flag
debug=false
for arg in $@
do
    shift 
    if [[ "$arg" = "--debug" ]]; then 
        debug=true 
        continue
    fi
    set -- "$@" "$arg"
done

if [[ debug ]]; then
    python3 -m debugpy --listen localhost:5678 $MULTIVERSEPATH/$version/odoo/odoo-bin $@ "--addons-path=$MULTIVERSEPATH/$version/odoo/addons,$MULTIVERSEPATH/$version/enterprise,$MULTIVERSEPATH/$version/design-themes" --max-cron-threads=0
    # ,$ODOOHOME/internal/default,$ODOOHOME/internal/trial
else
    $MULTIVERSEPATH/$version/odoo/odoo-bin $@ "--addons-path=$MULTIVERSEPATH/$version/odoo/addons,$MULTIVERSEPATH/$version/enterprise,$MULTIVERSEPATH/$version/design-themes" --max-cron-threads=0
    # ,$ODOOHOME/internal/default,$ODOOHOME/internal/trial
fi