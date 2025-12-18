#!/bin/sh

# Inicializar datadir si está vacío
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    # Muestra mensaje indicando que se va a inicializar la base de datos
    echo "Inicializando base de datos..."
    # Ejecuta el instalador de MariaDB para crear las tablas del sistema en el datadir
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
fi

# Arrancar MariaDB en segundo plano
echo "Arrancando MariaDB..."
# Lanza el servidor MariaDB en modo seguro como proceso en segundo plano
mariadbd-safe --user=${DB_USER} --datadir=${DB_DATADIR} &
# Guarda el PID del proceso lanzado para poder esperar al final
PID=$!

# Esperar a que el servidor esté listo
sleep 10
# Pausa fija de 10 segundos para dar tiempo a que el servidor arranque

# Ejecuta comandos SQL directamente desde un bloque heredado (here-document)
# 1. Cambia la contraseña del usuario root local
# 2. Crea la base de datos especificada
# 3. Crea el usuario de la base de datos con los privilegios adecuados
# 4. Refresca los privilegios para que los cambios tengan efecto
# 5. Aplica los cambios de privilegios

/usr/bin/mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Ejecutar todos los scripts SQL en /entrysql
if [ -d "/entrypointsql" ]; then
    # Hace un bucle sobre todos los archivos .sql en el directorio /entrypointsql
    for f in /entrypointsql/*.sql; do
        # Verifica que el archivo existe y es regular
        if [ -f "$f" ]; then
            # Muestra qué archivo se va a ejecutar
            echo "Ejecutando $f..."
            # Ejecuta el script SQL usando root con contraseña
            /usr/bin/mariadb -u root -p"${DB_ROOT_PASS}" < "$f"
        fi
    done
fi

# Mantener el proceso principal
# Espera a que el proceso mysqld lanzado en segundo plano termine
wait $PID
