#!/bin/bash

if [[ $1 == "--list" ]]; then
    # Commented for test pass
    apphost=$(yc compute instance list | grep "reddit-app" | awk {'print $10'})
    dbhost=$(yc compute instance list | grep "reddit-db" | awk {'print $10'})
    # apphost="62.84.118.162"
    # dbhost="158.160.63.158"

    cat <<EOT
{
    "_meta": {
        "hostvars": {}
    },
    "app": {
        "hosts": ["${apphost}"],
        "vars": {
            "ansible_user": "ubuntu",
            "ansible_private_key_file": "~/.ssh/appuser"
        }
    },
    "db": {
        "hosts": ["${dbhost}"],
        "vars": {
            "ansible_user": "ubuntu",
            "ansible_private_key_file": "~/.ssh/appuser"
        }
    }
}
EOT
elif [[ $1 == "--host" ]]; then
    echo '{"_meta": {"hostvars": {}}}'
else
    echo '{}'
fi
