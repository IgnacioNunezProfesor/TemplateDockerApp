#!/bin/sh

# Salir si ocurre un error, si hay variables no definidas, o si falla un pipe
set -e

# Verifica si el directorio de datos de MariaDB no está inicializado
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    echo "Inicializando base de datos..."
    # Inicializa las tablas del sistema de MariaDB en el datadir especificado
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
fi

# Arranca el servidor MariaDB en segundo plano
echo "Arrancando MariaDB..."
mysqld_safe --user=${DB_USER} --datadir=${DB_DATADIR} &
# Guarda el PID del proceso para poder esperar al final
PID=$!

# Espera para dar tiempo a que arranque el servidor
sleep 10

# Ejecuta comandos SQL para configurar el usuario root, la base de datos y el usuario de aplicación
# 1. Cambia la contraseña del usuario root local
# 2. Crea la base de datos especificada
# 3. Crea el usuario de la base de datos con los privilegios adecuados
# 4. Refresca los privilegios para que los cambios tengan efecto
# 5. Aplica los cambios de privilegios

mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Si existe el directorio /entrysql, ejecuta todos los scripts .sql que contiene
if [ -d "/entrypointsql" ]; then
    for f in /entrypointsql/*.sql; do
        if [ -f "$f" ]; then
            echo "Ejecutando $f..."
            # Ejecuta el script SQL usando root con contraseña
            mysql -u root -p"${DB_ROOT_PASS}" < "$f"
        fi
    done
fi

# Espera a que el proceso mysqld_safe termine para mantener el contenedor activo
wait $PID
