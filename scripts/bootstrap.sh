# Synopsis  : ./bootstrap.sh {admin-password}
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# ---
# Creates initial /db/www/scaffold/config and /db/www/scaffold/mesh collections
# You should then use curl {home}/admin/deploy?t=[targets] to terminate the installation
# and then restore some application data / users from an application backup using {exist}/bin/backup.sh
../../../../bin/client.sh -u admin -P $1 -m /db/www/scaffold/mesh --parse ../mesh
../../../../bin/client.sh -u admin -P $1 -m /db/www/scaffold/config --parse ../config
