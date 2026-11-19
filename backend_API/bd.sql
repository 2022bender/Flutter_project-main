CREATE DATABASE IF NOT EXISTS bd_Aplicacion_movil
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bd_Aplicacion_movil;

CREATE TABLE IF NOT EXISTS usuario (
  id_usr INT(11) NOT NULL AUTO_INCREMENT,
  nom_usr VARCHAR(100) NOT NULL,
  mail VARCHAR(150) NOT NULL,
  pass VARCHAR(255) NOT NULL,
  dir_usr VARCHAR(200) DEFAULT NULL,
  tip_usu INT(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_usr),
  UNIQUE KEY uq_usuario_mail (mail)
) 
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS blog (
  id_blog INT(11) NOT NULL AUTO_INCREMENT,
  titulo VARCHAR(150) NOT NULL,
  `desc` TEXT DEFAULT NULL,
  img VARCHAR(500) DEFAULT NULL,
  tags VARCHAR(255) DEFAULT NULL,
  id_usr INT(11) DEFAULT NULL,
  PRIMARY KEY (id_blog),
  KEY idx_blog_id_usr (id_usr),
  CONSTRAINT fk_blog_usuario
    FOREIGN KEY (id_usr) REFERENCES usuario(id_usr)
) 
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS comentarios (
  id_com INT(11) NOT NULL AUTO_INCREMENT,
  comentario TEXT NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estatus INT(11) NOT NULL DEFAULT 1,
  usr_id INT(11) NOT NULL,
  blog_id INT(11) NOT NULL,
  PRIMARY KEY (id_com),
  KEY idx_comentarios_usr_id (usr_id),
  KEY idx_comentarios_blog_id (blog_id),
  CONSTRAINT fk_comentario_usuario
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr),
  CONSTRAINT fk_comentario_blog
    FOREIGN KEY (blog_id) REFERENCES blog(id_blog)
) 
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
