#!/bin/bash

# Check args
if [ "$#" -lt 1  ]; then
    echo "oeadd-version: Remove Odoo <versions>... (space-separated list of version name) from multiverse."
    echo ""
    echo "Usage: oe-rm-version <versions>..."
    exit 1
fi

# Check for $MULTIVERSEPATH in ~/.bashrc
if [ -z ${MULTIVERSEPATH+x} ]; then
    echo "\$MULTIVERSEPATH not found in $HOME/.bashrc, please run .init.sh"
    exit 1
fi

# Remove branch from worktree
for version in "$@"
do
    for i in "odoo" "enterprise" "design-themes"
    do
        git -C "$MULTIVERSEPATH/master/$i" worktree remove "$MULTIVERSEPATH/$version/$i" 2>/dev/null
    done
    rm -r "$MULTIVERSEPATH/$version"
done

for i in "odoo" "enterprise" "design-themes"
do
    git -C "$MULTIVERSEPATH/master/$i" worktree prune
done