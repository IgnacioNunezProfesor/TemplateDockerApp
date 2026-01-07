#!/bin/sh
set -e  # Detener el script si ocurre cualquier error

# Inicializar datadir si está vacío
if [ ! -d "${DB_DATADIR}/mysql" ]; then   # Comprueba si no existe el directorio de MySQL
    echo "Inicializando base de datos..." # Mensaje informativo
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}  # Inicializa el datadir
fi

# Arrancar MariaDB en segundo plano
echo "Arrancando MariaDB..."  # Aviso de arranque
mysqld_safe --user=${DB_USER} --datadir=${DB_DATADIR} &  # Inicia MariaDB en background
PID=$!  # Guarda el PID del proceso para controlarlo después

# Esperar a que el servidor esté listo
sleep 10  # Pausa para permitir que MariaDB termine de arrancar

mysql -u root <<EOF  # Ejecuta comandos SQL como root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';  # Cambia contraseña de root
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;  # Crea la BD
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';  # Crea usuario
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';  # Da permisos completos
FLUSH PRIVILEGES;  # Recarga permisos
EOF

# Ejecutar todos los scripts SQL en /entrysql
if [ -d "/entrypointsql" ]; then  # Comprueba si existe el directorio
    for f in /entrypointsql/*.sql; do  # Recorre todos los .sql
        if [ -f "$f" ]; then  # Verifica que el archivo existe
            echo "Ejecutando $f..."  # Mensaje informativo
            mysql -u root -p"${DB_ROOT_PASS}" < "$f"  # Ejecuta el script SQL
        fi
    done
fi

# Mantener el proceso principal
wait $PID  # Espera a que termine el proceso de MariaDB
