#!/bin/bash

set -e

if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]
then
    echo "Bench already exists, skipping init"
    exit 0
fi

rm -rf /workspaces/frappe_codespace/.git

source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18

echo "nvm use 18" >> ~/.bashrc
cd /workspace

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u root -p123 -e "SELECT 1" >/dev/null 2>&1
do
    echo "MariaDB is unavailable - sleeping"
    sleep 1
done

echo "MariaDB is up - executing command"

bench init \
--ignore-exist \
--skip-redis-config-generation \
frappe-bench

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove redis from Procfile
sed -i '/redis/d' ./Procfile

# Add debug output
echo "Creating new site..."
echo "MariaDB connection test:"
mysql -h mariadb -u root -p123 -e "SELECT VERSION()"

bench new-site dev.localhost \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket \
--verbose

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost