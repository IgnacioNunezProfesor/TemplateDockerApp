#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

# Validación de variables obligatorias
: "${DB_UNIX_USER:?Falta DB_UNIX_USER (usuario SQL)}"
: "${DB_ROOT_PASS:?Falta DB_ROOT_PASS}"
: "${DB_SERVER_DATADIR:?Falta DB_SERVER_DATADIR}"

# Inicializar datadir si está vacío
if [ ! -d "${DB_SERVER_DATADIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db --datadir="${DB_SERVER_DATADIR}"
fi

echo "[Entrypoint] Arrancando MariaDB..."
mariadbd --datadir="${DB_SERVER_DATADIR}" & PID=$!

# Esperar a que MariaDB esté listo
echo "[Entrypoint] Esperando a MariaDB..."
until mariadb-admin ping --silent; do
    sleep 1
done

echo "[Entrypoint] Configurando usuarios SQL y base de datos..."
mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
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
