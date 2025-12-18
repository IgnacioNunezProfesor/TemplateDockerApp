-- Crea el esquema si no existe, con codificación UTF-8 multilenguaje y colación general
CREATE SCHEMA IF NOT EXISTS `template_docker_app_dev` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Selecciona el esquema recién creado para que las siguientes operaciones se ejecuten dentro de él
USE `template_docker_app_dev`;