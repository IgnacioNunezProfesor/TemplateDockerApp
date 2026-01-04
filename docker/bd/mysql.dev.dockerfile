# Alpine Linux como base
FROM alpine:latest 

# Variables de entorno configurables (solo disponibles durante la construcción de la imagen)
ARG DB_PORT=${DB_PORT} \ 
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_DATADIR=${DB_DATADIR} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Define variables que existirán dentro del contenedor en ejecución.
ENV DB_PORT=${DB_PORT} \
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Instalar mariadb, cliente y utilidades
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \ 
    # Crear grupo del usuario de la base de datos
    addgroup -S ${DB_USER} && \
    # Crear usuario del sistema para MariaDB
    adduser -S ${DB_USER} -G ${DB_USER} && \
    # Crear directorios de datos, logs y scripts SQL
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    # Asignar permisos al usuario de MariaDB
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    # Permisos de lectura/ejecución
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    # Limpiar cachés para reducir tamaño de la imagen
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    # Inicializar estructura básica de MariaDB
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}

# Copiar script de arranque al contenedor
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh
# Copiar scripts SQL iniciales
COPY ./docker/bd/sql/*.sql /entrypointsql/
# Copiar configuración personalizada de MariaDB
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf
# Ajustar permisos del entrypoint y mostrar contenido
RUN  chown -R ${DB_USER}:${DB_USER} /entrypoint* && chmod 755 /entrypoint.sh && ls -la /entrypoint*
# Convertir el script a formato UNIX (por si viene de Windows)
RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

#USER ${DB_USER}
# Exponer puerto
EXPOSE ${DB_PORT}

# Entrypoint y comando por defecto
ENTRYPOINT ["sh", "/entrypoint.sh" ]


