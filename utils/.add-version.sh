#!/bin/bash

# Check args
if [ "$#" -lt 1  ]; then
    echo "oeadd-version: Add Odoo <versions>... (space-separated list of version name) to multiverse."
    echo ""
    echo "Usage: oeadd-version <versions>..."
    exit 1
fi

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

for i in "odoo" "enterprise" "design-themes"
do
    git -C "$MULTIVERSEPATH/master/$i" worktree prune
done

# Add branch to worktree
for version in "$@"
do
    mkdir -p "$MULTIVERSEPATH/$version"
    for i in "odoo" "enterprise" "design-themes"
    do
        git -C "$MULTIVERSEPATH/master/$i" fetch "origin" "$version"
        git -C "$MULTIVERSEPATH/master/$i" worktree add --track -b "$version" "$MULTIVERSEPATH/$version/$i" "origin/$version"
    done
done