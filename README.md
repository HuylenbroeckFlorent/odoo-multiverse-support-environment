# Odoo multiverse support environment
## Setup

1. Run ```.prereqs.sh``` to check that your system has all the requirement for multiverse setup installed.
2. Run ```.init.sh``` to set-up multiverse.
3. Run ```oe``` for help.

## Commands
- `oe` - Display help menu.
- `cdo`/`cde` - Navigate to the 'odoo'/'enterprise' directory of any version in multiverse.
- `oe-pull` - Pull (and rebase) all the repos in multiverse.
- `oe-support` - Launches Odoo support-tools.
- `oe-odoo-bin` - Launch an odoo-bin instance from any version in multiverse.
- `oe-branch` - Manage Odoo branches in multiverse (add existing, remove, create).
- `oe-migrate` - Migrate a copy of an Odoo database to a newer version.

Run `--help` on any command for help.
