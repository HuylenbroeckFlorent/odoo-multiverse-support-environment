#! /bin/bash

odoo-bin-help() {
    echo "NAME"
    echo -e '\t odoo-bin - launch any version of odoo-bin.'
    echo "DESCRIPTION"
    echo -e "\t From outside of any '$MULTIVERSEPATH/*/odoo/' directory, launches odoo-bin from"
    echo -e "\t the chosen version. From inside any '$MULTIVERSEPATH/*/odoo/ directory', launches"
    echo -e "\t that specific version of odoo-bin."
    echo "SYNOPSIS:"
    echo -e '\t odoo-bin <version> [--debug] [args...]'
    echo -e "\t\t Launches 'version' version of odoo-bin with args as parameters."
    echo
    echo -e '\t odoo-bin [--debug] [args...]'
    echo -e "\t\t Launches the version of odoo-bin in the current directory with args as parameters."
    echo 
    echo "OPTIONS"
    echo -e "\t --debug launches odoo-bin as a debugpy process that can be listened to on port 5678."
    exit 1
}

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

# Display help message if --help or -h is passed as argument.
if [[ $# -gt 0 ]] && [[ $1 =~ ^("-h"|"--help")$ ]]; then
    odoo-bin-help
    exit 0
fi

if [[ $# -gt 0 ]] && [[ $1 =~ (master|saas-[0-9]+.[1-4]|[0-9]+.0) ]] && [[ "$(ls $MULTIVERSEPATH)" =~ ^.*"$1".*$ ]]; then
    version="$1"
    shift
elif [[ "$(pwd)" =~ "$MULTIVERSEPATH"/(master|saas-[0-9]+.[1-4]|[0-9]+.0)/odoo ]]; then
    version=$(pwd)
    version=${version##$MULTIVERSEPATH/}
    version=${version%%/*}
else
    echo 'Could not find version'
    echo 'Run --help for help'
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

# Launch command (',$ODOOHOME/internal/default,$ODOOHOME/internal/trial' could be added to addons path)
if [[ debug ]]; then
    python3 -m debugpy --listen localhost:5678 $MULTIVERSEPATH/$version/odoo/odoo-bin $@ "--addons-path=$MULTIVERSEPATH/$version/odoo/addons,$MULTIVERSEPATH/$version/enterprise,$MULTIVERSEPATH/$version/design-themes" --max-cron-threads=0
else
    $MULTIVERSEPATH/$version/odoo/odoo-bin $@ "--addons-path=$MULTIVERSEPATH/$version/odoo/addons,$MULTIVERSEPATH/$version/enterprise,$MULTIVERSEPATH/$version/design-themes" --max-cron-threads=0
fi