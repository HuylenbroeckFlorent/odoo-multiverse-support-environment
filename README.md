# odoo-init-support-env

Run ```.init.sh``` to set-up multiverse.

Run ```.add-version.s <space-separated-version-names>``` to add some specific versions to multiverse.
  
Run ```.migrate <database> <target-version-name>``` to migrate a database to a given version.

Run ```.add-version.sh $(cat currently_supported_versions.txt)``` to install all currently supported versions.