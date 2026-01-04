#!/bin/sh

# Inicializar datadir si está vacío
if [ ! -d "${DB_DATADIR}/mysql" ]; then # Comprueba si no existe la carpeta
    echo "Inicializando base de datos..."
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR} # Inicializa los archivos básicos de MariaDB en el directorio de datos, usa el usuario DB_USER y el directorio DB_DATADIR
fi

# Arrancar MariaDB en segundo plano
echo "Arrancando MariaDB..." # El servidor va a arrancar
mariadbd-safe --user=${DB_USER} --datadir=${DB_DATADIR} & # Arranca MariaDB en modo seguro (en segundo plano por el &)
PID=$! # Guarda el PID del proceso que se acaba de lanzar (permite esperar a que termine más adelante)

# Esperar a que el servidor esté listo
sleep 10

/usr/bin/mariadb -u root <<EOF # Ejecuta comandos SQL como usuario root
-- Cambiar contraseña del root 
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}'; 
-- Crear base de datos principal
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Crear usuario para Moodle con permisos completos
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Ejecutar todos los scripts SQL en /entrysql
if [ -d "/entrypointsql" ]; then # Comprueba si existe la carpeta /entrypointsql
    for f in /entrypointsql/*.sql; do # Recorre todos los archivos .sql dentro de esa carpeta
        if [ -f "$f" ]; then # Comprueba que el archivo realmente existe
            echo "Ejecutando $f..." # Muestra el archivo SQL que se está ejecutando
            /usr/bin/mariadb -u root -p"${DB_ROOT_PASS}" < "$f" # Ejecuta el archivo SQL usando el cliente MariaDB
        fi
    done
fi

# Mantener el proceso principal
wait $PID # Espera a que el proceso de MariaDB (el que arrancó antes) termine
# Evita que el contenedor Docker se cierre
