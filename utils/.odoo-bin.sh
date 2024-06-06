#! /bin/bash

odoo-bin-help() {
    echo "NAME"
    echo -e '\t odoo-bin - launch any version of odoo-bin.'
    echo "DESCRIPTION"
    echo -e "\t From outside of any '$MULTIVERSEPATH/*/odoo/' directory, launches odoo-bin from"
    echo -e "\t the chosen version. From inside any '$MULTIVERSEPATH/*/odoo/ directory', launches"
    echo -e "\t that specific version of odoo-bin. Version 'odoofin' can also be used to launch"
    echo -e "\t an odooFin server."
    echo "SYNOPSIS:"
    echo -e '\t odoo-bin <version> [--debug] [args...]'
    echo -e "\t\t Launches 'version' version of odoo-bin with args as parameters."
    echo
    echo -e '\t odoo-bin odoofin [--debug] [args...]'
    echo -e "\t\t Launches an odoofin server with args as parameters."
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

odoofin=false
if [[ $# -gt 0 ]] && [[ $1 =~ (master|saas-[0-9]+.[1-4]|[0-9]+.0) ]] && [[ "$(ls $MULTIVERSEPATH)" =~ ^.*"$1".*$ ]]; then
    version="$1"
    shift
elif [[ $# -gt 0 ]] && [[ $1 =~ odoofin ]]; then
    odoofin=true
    version="17.0"
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

# Check for flags
# --debug  to start a debugpy environment
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

# Build arguments
addonspath="--addons-path=\
$MULTIVERSEPATH/$version/odoo/addons,\
$MULTIVERSEPATH/$version/enterprise,\
$MULTIVERSEPATH/$version/design-themes,\
$ODOOHOME/internal/default,\
$ODOOHOME/internal/trial"

upgradepath="--upgrade-path=\
$MULTIVERSEPATH/master/upgrade-util/src,\
$MULTIVERSEPATH/master/upgrade/migrations"

args=$@

if [ "$odoofin" = true ]; then
    addonspath="${addonspath},$ODOOHOME/odoofin"
    args="${args} --unaccent --http-port 6969"
    export REQUESTS_CA_BUNDLE=/etc/ssl/certs/nginx-selfsigned.crt
fi

# Build command
commandline="$MULTIVERSEPATH/$version/odoo/odoo-bin $args $addonspath $upgradepath --max-cron-threads=0"

if [ "$debug" = true ]; then
    pip3 list | grep -q "debugpy" || (echo "Debugpy not found. Installing..." && pip3 install debugpy >/dev/null) 2>/dev/null
    commandline="python3 -m debugpy --listen localhost:5678 ${commandline}"
fi

# Launch command
echo -e "Running the following command\n\t$commandline"
eval $commandline

# Cleanup after execution
if [ "$odoofin" = true ]; then
    unset REQUESTS_CA_BUNDLE
fi
