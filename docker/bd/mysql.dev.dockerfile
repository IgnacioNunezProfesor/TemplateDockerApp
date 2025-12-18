# Usa la imagen base Alpine Linux (ligera para contenedores)
FROM alpine:latest

# Define argumentos de construcción (solo disponibles durante el build)
ARG DB_PORT=${DB_PORT} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_DATADIR=${DB_DATADIR} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Exporta variables de entorno para que existan en tiempo de ejecución del contenedor
ENV DB_PORT=${DB_PORT} \
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Ejecuta pasos de instalación y preparación en una sola capa:
# - Actualiza índices de apk
# - Instala MariaDB, cliente y utilidades
# - Crea grupo y usuario del servicio según DB_USER
# - Crea directorios de datos, logs y de scripts de entrada
# - Ajusta propiedad y permisos de esos directorios
# - Limpia cachés temporales para reducir tamaño
# - Inicializa el datadir de MariaDB con tablas del sistema
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \
    addgroup -S ${DB_USER} && \
    adduser -S ${DB_USER} -G ${DB_USER} && \
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}

# Copia el script de entrada al contenedor (ruta destino /entrypoint.sh)
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh
# Copia todos los archivos .sql al directorio /entrypointsql del contenedor
COPY ./docker/bd/sql/*.sql /entrypointsql/
# Copia la configuración de MySQL/MariaDB a /etc/my.cnf
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf

# Ajusta propietario y permisos del script y ruta /entrypoint*
# Muestra listado (ls -la) para verificación durante el build
RUN  chown -R ${DB_USER}:${DB_USER} /entrypoint* && chmod 755 /entrypoint.sh && ls -la /entrypoint*
# Convierte el script a fin de línea Unix y asegura permisos de ejecución
RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

#USER ${DB_USER}
# Exponer puerto
EXPOSE ${DB_PORT}

# Define el entrypoint: ejecuta el script /entrypoint.sh con sh al arrancar el contenedor
ENTRYPOINT ["sh", "/entrypoint.sh" ]


