#!/bin/sh
# Indica que el script debe ejecutarse utilizando el intérprete sh

# Inicializar el directorio de datos si está vacío
# Se comprueba si no existe el directorio mysql dentro del datadir configurado
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    # Muestra un mensaje informativo durante la inicialización
    echo "Inicializando base de datos..."

    # Inicializa la estructura interna de MariaDB
    # Usa el usuario y el directorio de datos definidos por variables de entorno
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
fi

# Arrancar MariaDB en segundo plano
# Muestra un mensaje indicando que el servicio va a iniciarse
echo "Arrancando MariaDB..."

# Inicia el servidor MariaDB en segundo plano usando mariadbd-safe
mariadbd-safe --user=${DB_USER} --datadir=${DB_DATADIR} &

# Guarda el identificador del proceso (PID) del servidor MariaDB
PID=$!

# Esperar unos segundos para asegurar que el servidor esté listo
sleep 10

# Ejecuta comandos SQL como el usuario root utilizando un bloque heredoc
/usr/bin/mariadb -u root <<EOF
# Establece la contraseña del usuario root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';

# Crea la base de datos de la aplicación con codificación UTF-8
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Crea un usuario específico para la aplicación con acceso remoto
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';

# Concede todos los privilegios sobre la base de datos creada
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

# Aplica los cambios de permisos
FLUSH PRIVILEGES;
EOF

# Ejecutar todos los scripts SQL presentes en el directorio /entrypointsql
# Se comprueba previamente que el directorio exista
if [ -d "/entrypointsql" ]; then

    # Recorre todos los archivos con extensión .sql del directorio
    for f in /entrypointsql/*.sql; do

        # Comprueba que el archivo existe y es un fichero regular
        if [ -f "$f" ]; then
            # Muestra qué script SQL se está ejecutando
            echo "Ejecutando $f..."

            # Ejecuta el script SQL como root usando la contraseña definida
            /usr/bin/mariadb -u root -p"${DB_ROOT_PASS}" < "$f"
        fi
    done
fi

# Mantener el proceso principal activo
# Espera a que finalice el proceso de MariaDB
wait $PID
