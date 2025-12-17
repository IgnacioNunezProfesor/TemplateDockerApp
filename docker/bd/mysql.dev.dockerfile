FROM alpine:latest
# Definimos la imagen base a usar

# Variables de entorno configurables
# La variables ARG se usa cuando se construye la imagen
ARG DB_PORT=${DB_PORT} \  
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_DATADIR=${DB_DATADIR} \
    DB_LOG_DIR=${DB_LOG_DIR}
   #DB_PORT:Define el puerto en el que el servidor de base de datos escuchará.
   #DB_USER:Define el nombre del usuario de la base de datos.
   #DB_PASS:Define la contraseña del usuario de la base de datos.
   #DB_ROOT_PASS:Define la contraseña del usuario root de la base de datos.
   #DB_NAME:Define el nombre de la base de datos a crear.
   #DB_DATADIR:Define el directorio donde se almacenarán los datos de la base de datos.
   #DB_LOG_DIR:Define el directorio donde se almacenarán los archivos de registro de la base de datos.

#Las variables ENV se usan en tiempo de ejecución del contenedor
ENV DB_PORT=${DB_PORT} \
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Instalar mariadb y cliente
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \
    addgroup -S ${DB_USER} && \
    adduser -S ${DB_USER} -G ${DB_USER} && \
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
    #Actualiza los paquetes de alpine
    #Instala mariadb y sus utilidades y el --no-cache evita que se guarden archivos temporales de instalación
    #Crea un usuario y grupo de sistema para ejecutar el servicio de base de datos
    #Crea los directorios para los datos y logs de la base de datos
    #Cambia la propiedad de los directorios al usuario y grupo creado
    #Pone los permisos 755 a los directorios creados
    #Limpia los archivos temporales de instalación
    #Inicia la base de datos mariaDB en el directorio
    

COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh
COPY ./docker/bd/sql/*.sql /entrypointsql/
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf
RUN  chown -R ${DB_USER}:${DB_USER} /entrypoint* && chmod 755 /entrypoint.sh && ls -la /entrypoint*
RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh
#Copia el script desde la ruta local al contenedor
#Copia todos los archivos .sql desde la ruta local al contenedor
#Copia el archivo de configuración al contenedor
#Cambia el propietario de todos los archivos que empiezan por _/entrypoint al usuario y grupo creado
#Convierte el formato de fin de linea de windows a unix


#USER ${DB_USER}
# Exponer puerto
EXPOSE ${DB_PORT}

# Entrypoint y comando por defecto
ENTRYPOINT ["sh", "/entrypoint.sh" ]


