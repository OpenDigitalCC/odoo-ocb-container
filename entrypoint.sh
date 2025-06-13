#!/bin/bash
set -e

exec > /dev/stdout 2>&1

ODOO_UID=${ODOO_UID:-10000}
ODOO_USER=${ODOO_USER:-odoo}

# Set defaults
# Set paths
export ODOO_BASE_DIR=${ODOO_BASE_DIR:-/srv/odoo}
export ODOO_CONF_PATH="${ODOO_BASE_DIR}/conf/${ODOO_BRANCH}"
export ODOO_SRC_DIR="${ODOO_BASE_DIR}/source/${ODOO_BRANCH}"

# Files
export ODOO_CONF_FILE="${ODOO_CONF_PATH}/odoo.conf"

# ------------------------ Functions -------------------------

create_odoo_conf_from_env() {
    local conf_file="${ODOO_CONF_FILE}"
    echo "Creating conf file ${ODOO_CONF_FILE}"
    mkdir -p "$(dirname "$conf_file")"
    echo "[options]" > "$conf_file"

    # Generate a random password if ODOO_CONF_ADMIN_PASSWD is not set
    if [[ -z "${ODOO_CONF_ADMIN_PASSWD:-}" ]]; then
	echo "Generating random odoo admin password"
        export ODOO_CONF_ADMIN_PASSWD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%^&*()\-_=+{}[];:,.<>/?')
    fi
    while IFS='=' read -r var value; do
        if [[ "$var" = ODOO_CONF_* ]]; then
            key=$(echo "$var" | sed -e 's/ODOO_CONF_//' -e 's/-/_/g' -e 's/\(.*\)/\L\1/')
            echo "$key = $value" >> "$conf_file"
	    echo "CONFIG: setting $key to $value"
        fi
    done < <(env)
}

set_permissions() {
    echo "Running as $(id -u) and setting permissions to $ODOO_UID / $ODOO_USER"
    mkdir -p "${ODOO_CONF_DATA_DIR}"
    chown -R $ODOO_UID "${ODOO_CONF_DATA_DIR}" 
}

# add_odoo_user() {
# 
#     if ! getent group odoo >/dev/null; then
#         addgroup --gid "$odoo_gid" odoo
#     fi
# 
#     if ! getent passwd odoo >/dev/null; then
#         adduser --uid "$odoo_uid" --gid "$odoo_gid" --system --disabled-password --no-create-home odoo
#     fi
# }

check_and_init_db() {
#TODO: check compose arg to see if a default DB should be created or not
    local init_file="${ODOO_CONF_PATH}/default_database_initialised"
    local db_name="${ODOO_CONF_DB_NAME}"

    if [ ! -f "$init_file" ]; then
        echo "Initialization file $init_file not found. Initializing database '$db_name'."
	mkdir -p "$(dirname "$init_file")"
        # Initialize the database (example using createdb command)
	gosu $ODOO_USER ${ODOO_SRC_DIR}/odoo-bin --config=${ODOO_CONF_FILE} -i base,remove_odoo_enterprise,disable_odoo_online --stop-after-init --no-http --without-demo=all 
        if [ $? -eq 0 ]; then
            echo "Database '$db_name' initialized successfully."
	    echo "$db_name $(date --iso-8601=seconds)" > "$init_file"
        else
            echo "Failed to initialize database '$db_name'." >&2
            return 1
        fi
    else
	DB_INIT_DATA=$(cat "$init_file")
        echo "Initialization file found: $DB_INIT_DATA"
    fi
}

create_addons_dirs() {
    # Split comma-separated paths
    IFS=',' read -ra paths <<< "$ODOO_CONF_ADDONS_PATH"
    for path in "${paths[@]}"; do
        # Expand variables in path
        expanded_path=$(eval echo "$path")
        if [ ! -d $expanded_path ]
	then 	
          echo "Creating directory: $expanded_path"
          mkdir -p "$expanded_path"
	fi
    done
}



# ------------------------


# Set file permissions
set_permissions

# make the conf file
create_odoo_conf_from_env

# make sure addon paths exist
create_addons_dirs

# initialise database if not previously initialised
check_and_init_db

# check if we should update odoo code on restart from compose arg
# TODO


# Run odoo
echo "Ready, running Odoo"
exec gosu $ODOO_USER ${ODOO_SRC_DIR}/odoo-bin --config=${ODOO_CONF_FILE} "$@"

