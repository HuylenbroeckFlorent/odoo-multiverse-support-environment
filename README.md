# odoo-init-support-env

Run ```.init.sh``` to set-up multiverse.

Run ```.add-version.sh <space-separated-version-names>``` to add some specific versions to multiverse.

Run ```.add-version.sh $(cat currently_supported_versions.txt)``` to install all currently used versions.
  
Run ```.migrate.sh <database> <target-version-name>``` to migrate a database to a given version.
