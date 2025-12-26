#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

# Validación de variables obligatorias
: "${DB_USER:?Falta DB_USER (usuario SQL)}"
: "${DB_PASS:?Falta DB_PASS (password SQL)}"
: "${DB_ROOT_PASS:?Falta DB_ROOT_PASS}"
: "${DB_NAME:?Falta DB_NAME}"
: "${DB_UNIX_USER:?Falta DB_UNIX_USER (usuario UNIX)}"

# Inicializar datadir si está vacío
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db --user="${DB_UNIX_USER}" --datadir="${DB_DATADIR}"
fi

echo "[Entrypoint] Arrancando MariaDB..."
mariadbd --user="${DB_UNIX_USER}" --datadir="${DB_DATADIR}" &
PID=$!

# Esperar a que MariaDB esté listo
echo "[Entrypoint] Esperando a MariaDB..."
until mariadb-admin ping --silent; do
    sleep 1
done

echo "[Entrypoint] Configurando usuarios SQL y base de datos..."
mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Ejecutar scripts SQL adicionales
if [ -d "/entrypointsql" ]; then
    for f in /entrypointsql/*.sql; do
        [ -f "$f" ] || continue
        echo "[Entrypoint] Ejecutando script: $f"
        mariadb -u root -p"${DB_ROOT_PASS}" < "$f"
    done
fi

echo "[Entrypoint] MariaDB listo."
wait "$PID"
