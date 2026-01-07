FROM alpine:latest
# Imagen base mínima y ligera para construir el contenedor

# Variables de entorno configurables
ARG DB_PORT=${DB_PORT} \                 
# Puerto de la base de datos 
    DB_USER=${DB_USER} \                 
    # Usuario de la BD
    DB_PASS=${DB_PASS} \                 
    # Contraseña del usuario
    DB_ROOT_PASS=${DB_ROOT_PASS} \       
    # Contraseña del root
    DB_NAME=${DB_NAME} \                 
    # Nombre de la base de datos
    DB_DATADIR=${DB_DATADIR} \           
    # Ruta del datadir
    DB_LOG_DIR=${DB_LOG_DIR}             
    # Ruta de logs

ENV DB_PORT=${DB_PORT} \                 
# Exporta las variables al entorno del contenedor
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Instalar mariadb y cliente
RUN apk update && \                      
# Actualiza repositorios
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \  
    # Instala MariaDB
    addgroup -S ${DB_USER} && \          
    # Crea grupo del usuario
    adduser -S ${DB_USER} -G ${DB_USER} && \  
    # Crea usuario sin login
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \  
    # Crea directorios necesarios
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \  
    # Asigna permisos
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \  
    # Permisos de lectura/ejecución
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \  
    # Limpieza de archivos temporales
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}  
    # Inicializa la BD

COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh   
# Copia el script de arranque
COPY ./docker/bd/sql/*.sql /entrypointsql/                     
# Copia scripts SQL iniciales
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf                
# Copia configuración personalizada

RUN chown -R ${DB_USER}:${DB_USER} /entrypoint* && chmod 755 /entrypoint.sh && ls -la /entrypoint*
# Ajusta permisos del entrypoint y muestra contenido para depuración

RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh
# Convierte saltos de línea a formato Unix y asegura permisos correctos

#USER ${DB_USER}  # Se podría ejecutar como usuario no root, pero está comentado

# Exponer puerto
EXPOSE ${DB_PORT}   
# Expone el puerto configurado para MariaDB

# Entrypoint y comando por defecto
ENTRYPOINT ["sh", "/entrypoint.sh" ]   
# Script que se ejecuta al iniciar el contenedor
