#!/bin/sh
# Indica que el script debe ejecutarse usando el intérprete sh

set -e
# Hace que el script se detenga inmediatamente si ocurre cualquier error

# Inicializar el directorio de datos si está vacío
# Se comprueba si no existe el directorio mysql dentro del datadir
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    # Mensaje informativo indicando que se va a inicializar la base de datos
    echo "Inicializando base de datos..."

    # Inicializa los archivos internos de MariaDB
    # Se ejecuta con el usuario y directorio de datos definidos por variables de entorno
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
fi

# Arrancar MariaDB en segundo plano
# Se muestra un mensaje indicando que el servicio va a iniciarse
echo "Arrancando MariaDB..."

# Inicia el servidor MariaDB usando mysqld_safe en background
mysqld_safe --user=${DB_USER} --datadir=${DB_DATADIR} &

# Guarda el PID (identificador del proceso) del servidor MariaDB
PID=$!

# Esperar a que el servidor esté listo para aceptar conexiones
sleep 10

# Ejecuta comandos SQL como el usuario root usando un bloque heredoc
mysql -u root <<EOF
# Establece la contraseña del usuario root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';

# Crea la base de datos de Moodle con codificación UTF-8
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Crea un usuario para la aplicación con acceso remoto
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';

# Concede todos los privilegios sobre la base de datos al usuario creado
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

# Aplica los cambios de permisos
FLUSH PRIVILEGES;
EOF

# Ejecutar todos los scripts SQL presentes en el directorio /entrypointsql
# Se comprueba primero si el directorio existe
if [ -d "/entrypointsql" ]; then

    # Recorre todos los archivos con extensión .sql dentro del directorio
    for f in /entrypointsql/*.sql; do

        # Comprueba que el archivo existe realmente
        if [ -f "$f" ]; then
            # Muestra qué script SQL se está ejecutando
            echo "Ejecutando $f..."

            # Ejecuta el script SQL usando el usuario root y su contraseña
            mysql -u root -p"${DB_ROOT_PASS}" < "$f"
        fi
    done
fi

# Mantener el proceso principal activo
# Espera a que finalice el proceso de MariaDB
wait $PID
