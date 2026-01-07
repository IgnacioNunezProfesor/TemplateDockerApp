# Crea el esquema (base de datos) si no existe previamente
# Se define el conjunto de caracteres utf8mb4 para soportar caracteres Unicode completos
# Se usa la colación utf8mb4_general_ci para comparaciones de texto sin distinción entre mayúsculas y minúsculas
CREATE SCHEMA IF NOT EXISTS `template_docker_app_dev`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

# Selecciona el esquema creado para que las siguientes operaciones
# se ejecuten dentro de esta base de datos
USE `template_docker_app_dev`;
