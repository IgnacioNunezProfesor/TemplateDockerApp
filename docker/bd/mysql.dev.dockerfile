FROM alpine:latest

# Variables de entorno configurables
ARG DB_PORT=3306
ENV DB_PORT=${DB_PORT}
ENV DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_DATABASE=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS}

# Instalar mariadb y cliente
RUN apk add --no-cache mysql mysql-client bash tzdata \
    && mkdir -p /var/lib/mysql /docker-entrypoint-initdb.d /var/log/mysql \
    && chown -R mysql:mysql /var/lib/mysql \
    && chown -R mysql:mysql /var/log/mysql

# Copiar configuración y scripts de inicialización
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf
COPY ./docker/bd/sql/init.dev.sql /docker-entrypoint-initdb.d/

# Copiar entrypoint personalizado
COPY ./docker/bd/scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Exponer puerto
EXPOSE ${DB_PORT}

# Usuario no root
USER ${DB_USER}

# Entrypoint y comando por defecto
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["mysqld", "--user=${DB_USER}", "--datadir=/var/lib/mysql", "--skip-networking=0"]

