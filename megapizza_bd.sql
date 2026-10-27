-- ============================================================
-- BASE DE DATOS: megapizza
-- Proyecto: Implementación de un sitio web de comercio online
--           de una pizzería
-- Motor: MySQL / MariaDB 10.x
-- ============================================================

-- Fuerza que el cliente interprete este archivo como UTF-8, sin importar
-- cómo se importe (línea de comandos, phpMyAdmin, MySQL Workbench, etc.).
-- Sin esto, los acentos y la ñ pueden guardarse mal (p. ej. "Champiñones"
-- se vuelve "Champi??ones").
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS megapizza;
CREATE DATABASE megapizza CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE megapizza;

-- ------------------------------------------------------------
-- Tabla: usuarios
-- ------------------------------------------------------------
CREATE TABLE usuarios (
    id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    direccion       VARCHAR(200) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: metodos_pago
-- ------------------------------------------------------------
CREATE TABLE metodos_pago (
    id_metodo   INT AUTO_INCREMENT PRIMARY KEY,
    codigo      VARCHAR(20) NOT NULL UNIQUE,
    nombre      VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: productos  (pizzas, pastas, bebidas, promociones)
-- ------------------------------------------------------------
CREATE TABLE productos (
    id_producto     INT AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(10)  NOT NULL UNIQUE,  -- coincide con el id usado en script.js (c1, e1, p1, pr1, b1...)
    nombre          VARCHAR(100) NOT NULL,
    categoria       VARCHAR(30)  NOT NULL,   -- clasicas, especiales, pastas, promociones, bebidas
    tipo            VARCHAR(20)  NOT NULL,   -- pizza, pasta, bebida, promo, simple
    imagen_url      VARCHAR(255),
    precio_unico    DECIMAL(6,2) NULL,       -- solo para type=simple/promo (sin tamaños)
    activo          TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: producto_precios  (tamaño/salsa -> precio, N:1 con producto)
-- ------------------------------------------------------------
CREATE TABLE producto_precios (
    id_precio       INT AUTO_INCREMENT PRIMARY KEY,
    id_producto     INT NOT NULL,
    opcion          VARCHAR(30) NOT NULL,   -- Personal, Mediana, Familiar, Extra, Rossini, etc.
    precio          DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_precio_producto FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: cascos_relleno
-- ------------------------------------------------------------
CREATE TABLE cascos_relleno (
    id_casco            INT AUTO_INCREMENT PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,  -- ninguno, queso, ajo (igual que crustOptions en script.js)
    nombre              VARCHAR(60) NOT NULL,
    precio_adicional    DECIMAL(6,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: ingredientes_extra
-- ------------------------------------------------------------
CREATE TABLE ingredientes_extra (
    id_ingrediente      INT AUTO_INCREMENT PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,  -- igual que extraIngredients en script.js
    nombre              VARCHAR(60) NOT NULL,
    precio_adicional    DECIMAL(6,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: pedidos
-- ------------------------------------------------------------
CREATE TABLE pedidos (
    id_pedido       INT AUTO_INCREMENT PRIMARY KEY,
    codigo_pedido   VARCHAR(20) NOT NULL UNIQUE,   -- ej: PED-483920
    id_usuario      INT NOT NULL,
    id_metodo       INT NOT NULL,
    fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total           DECIMAL(8,2) NOT NULL,
    estado          ENUM('recibido','preparacion','camino','entregado') NOT NULL DEFAULT 'recibido',
    CONSTRAINT fk_pedido_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_pedido_metodo FOREIGN KEY (id_metodo)
        REFERENCES metodos_pago(id_metodo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: detalle_pedido (congela el precio y la personalización
-- de cada ítem al momento de la compra)
-- ------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id_detalle          INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido           INT NOT NULL,
    id_producto         INT NOT NULL,
    id_casco            INT NULL,
    opcion_tamano       VARCHAR(30) NOT NULL,
    precio_unitario     DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),
    CONSTRAINT fk_detalle_casco FOREIGN KEY (id_casco)
        REFERENCES cascos_relleno(id_casco)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabla: detalle_extra (relación N:M entre un ítem del pedido
-- y los ingredientes adicionales elegidos)
-- ------------------------------------------------------------
CREATE TABLE detalle_extra (
    id_detalle_extra    INT AUTO_INCREMENT PRIMARY KEY,
    id_detalle          INT NOT NULL,
    id_ingrediente      INT NOT NULL,
    CONSTRAINT fk_extra_detalle FOREIGN KEY (id_detalle)
        REFERENCES detalle_pedido(id_detalle) ON DELETE CASCADE,
    CONSTRAINT fk_extra_ingrediente FOREIGN KEY (id_ingrediente)
        REFERENCES ingredientes_extra(id_ingrediente),
    UNIQUE KEY uq_detalle_ingrediente (id_detalle, id_ingrediente)
) ENGINE=InnoDB;

-- ============================================================
-- DATOS INICIALES (seed) — reflejan el menuData de script.js
-- ============================================================

INSERT INTO metodos_pago (codigo, nombre) VALUES
('yape', 'Yape'), ('plin', 'Plin'), ('tarjeta', 'Tarjeta'), ('efectivo', 'Efectivo');

INSERT INTO cascos_relleno (codigo, nombre, precio_adicional) VALUES
('ninguno', 'Borde clásico', 0.00),
('queso', 'Casco relleno de queso', 4.00),
('ajo', 'Casco relleno de ajo y queso', 5.00);

INSERT INTO ingredientes_extra (codigo, nombre, precio_adicional) VALUES
('queso_extra', 'Extra queso', 3.00),
('champinones', 'Champiñones', 2.00),
('aceitunas', 'Aceitunas', 2.00),
('jamon', 'Jamón', 3.00),
('tocino', 'Tocino', 3.00),
('cebolla', 'Cebolla', 1.50),
('pimiento', 'Pimiento', 1.50);

-- Pizzas clásicas
INSERT INTO productos (codigo, nombre, categoria, tipo, imagen_url) VALUES
('c1','Americana', 'clasicas', 'pizza', 'images/americana.jpg'),
('c2','Pepperoni', 'clasicas', 'pizza', 'images/pepperoni.jpg'),
('c3','Mozzarella', 'clasicas', 'pizza', 'images/mozarella.jpg'),
('c4','Fugazza', 'clasicas', 'pizza', 'images/fugazza.jpg'),
('c5','Hawaiana', 'clasicas', 'pizza', 'images/hawaiana.jpg'),
('c6','Vegetariana', 'clasicas', 'pizza', 'images/vegetariana.jpg');

INSERT INTO producto_precios (id_producto, opcion, precio)
SELECT id_producto, x.opcion, x.precio FROM productos p JOIN (
  SELECT 'c1' codigo,'Personal' opcion,9.00 precio UNION ALL SELECT 'c1','Mediana',18.00 UNION ALL SELECT 'c1','Familiar',22.00 UNION ALL SELECT 'c1','Extra',28.00
  UNION ALL SELECT 'c2','Personal',12.00 UNION ALL SELECT 'c2','Mediana',21.00 UNION ALL SELECT 'c2','Familiar',28.00 UNION ALL SELECT 'c2','Extra',32.00
  UNION ALL SELECT 'c3','Personal',8.00  UNION ALL SELECT 'c3','Mediana',16.00 UNION ALL SELECT 'c3','Familiar',21.00 UNION ALL SELECT 'c3','Extra',26.00
  UNION ALL SELECT 'c4','Personal',8.00  UNION ALL SELECT 'c4','Mediana',17.00 UNION ALL SELECT 'c4','Familiar',20.00 UNION ALL SELECT 'c4','Extra',27.00
  UNION ALL SELECT 'c5','Personal',10.00 UNION ALL SELECT 'c5','Mediana',21.00 UNION ALL SELECT 'c5','Familiar',28.00 UNION ALL SELECT 'c5','Extra',32.00
  UNION ALL SELECT 'c6','Personal',10.00 UNION ALL SELECT 'c6','Mediana',20.00 UNION ALL SELECT 'c6','Familiar',26.00 UNION ALL SELECT 'c6','Extra',30.00
) x ON x.codigo = p.codigo;

-- Pizzas especiales
INSERT INTO productos (codigo, nombre, categoria, tipo, imagen_url) VALUES
('e1','Hawaiana Chicken', 'especiales', 'pizza', 'images/hawaianachicken.jpg'),
('e2','Full Meat', 'especiales', 'pizza', 'images/fullmeat.jpg'),
('e3','Gourmet', 'especiales', 'pizza', 'images/gourmet.jpg'),
('e4','La Favorita', 'especiales', 'pizza', 'images/favorita.jpg'),
('e5','Suprema', 'especiales', 'pizza', 'images/suprema.jpg'),
('e6','Brava', 'especiales', 'pizza', 'images/brava.jpg');

INSERT INTO producto_precios (id_producto, opcion, precio)
SELECT id_producto, x.opcion, x.precio FROM productos p JOIN (
  SELECT 'e1' codigo,'Personal' opcion,12.00 precio UNION ALL SELECT 'e1','Mediana',23.00 UNION ALL SELECT 'e1','Familiar',30.00 UNION ALL SELECT 'e1','Extra',35.00
  UNION ALL SELECT 'e2','Personal',13.00 UNION ALL SELECT 'e2','Mediana',25.00 UNION ALL SELECT 'e2','Familiar',30.00 UNION ALL SELECT 'e2','Extra',36.00
  UNION ALL SELECT 'e3','Personal',12.00 UNION ALL SELECT 'e3','Mediana',23.00 UNION ALL SELECT 'e3','Familiar',28.00 UNION ALL SELECT 'e3','Extra',24.00
  UNION ALL SELECT 'e4','Personal',12.00 UNION ALL SELECT 'e4','Mediana',23.00 UNION ALL SELECT 'e4','Familiar',28.00 UNION ALL SELECT 'e4','Extra',33.00
  UNION ALL SELECT 'e5','Personal',13.00 UNION ALL SELECT 'e5','Mediana',25.00 UNION ALL SELECT 'e5','Familiar',30.00 UNION ALL SELECT 'e5','Extra',36.00
  UNION ALL SELECT 'e6','Personal',12.00 UNION ALL SELECT 'e6','Mediana',23.00 UNION ALL SELECT 'e6','Familiar',30.00 UNION ALL SELECT 'e6','Extra',34.00
) x ON x.codigo = p.codigo;

-- Pastas
INSERT INTO productos (codigo, nombre, categoria, tipo, imagen_url) VALUES
('p1','Lasagna', 'pastas', 'pasta', 'images/lasagna.jpg'),
('p2','Fettuccini', 'pastas', 'pasta', 'images/fettuccini.jpg'),
('p3','Macarrón', 'pastas', 'pasta', 'images/macarron.jpg'),
('p4','Spaghetti', 'pastas', 'pasta', 'images/spaghetti.png');

INSERT INTO producto_precios (id_producto, opcion, precio)
SELECT id_producto, x.opcion, x.precio FROM productos p JOIN (
  SELECT 'p1' codigo,'Rossini' opcion,17.00 precio UNION ALL SELECT 'p1','Alfredo',17.00 UNION ALL SELECT 'p1','Tucocarne',17.00
  UNION ALL SELECT 'p2','Rossini',17.00 UNION ALL SELECT 'p2','Alfredo',17.00 UNION ALL SELECT 'p2','Tucocarne',17.00
  UNION ALL SELECT 'p3','Rossini',17.00 UNION ALL SELECT 'p3','Alfredo',17.00 UNION ALL SELECT 'p3','Tucocarne',17.00
  UNION ALL SELECT 'p4','Rossini',17.00 UNION ALL SELECT 'p4','Alfredo',17.00 UNION ALL SELECT 'p4','Tucocarne',17.00
) x ON x.codigo = p.codigo;

-- Producto simple (sin tamaños) y promociones (precio único)
INSERT INTO productos (codigo, nombre, categoria, tipo, imagen_url, precio_unico) VALUES
('p5','Porción de pan al ajo', 'pastas', 'simple', 'images/panalajo.jpg', 5.00),
('pr1','Promo Familiar', 'promociones', 'promo', 'images/promocion1.jpg', 50.00),
('pr2','Promo Pareja', 'promociones', 'promo', 'images/promocion2.jpg', 55.00),
('pr3','Promo Personal', 'promociones', 'promo', 'images/promocion3.jpg', 30.00),
('pr4','Mega Fiesta', 'promociones', 'promo', 'images/promocion4.jpg', 65.00),
('pr5','Promo Lunch', 'promociones', 'promo', 'images/promocion5.jpg', 30.00),
('pr6','Promo Duo', 'promociones', 'promo', 'images/promocion6.jpg', 33.00),
('pr7','Promo Amigos', 'promociones', 'promo', 'images/promocion7.jpg', 43.00);

-- Bebidas
INSERT INTO productos (codigo, nombre, categoria, tipo, imagen_url) VALUES
('b1','Inca Cola', 'bebidas', 'bebida', 'images/inca1LT.jpg'),
('b2','Coca Cola', 'bebidas', 'bebida', 'images/coca1LT.jpg');

INSERT INTO producto_precios (id_producto, opcion, precio)
SELECT id_producto, x.opcion, x.precio FROM productos p JOIN (
  SELECT 'b1' codigo,'Personal' opcion,4.90 precio UNION ALL SELECT 'b1','1 Litro',8.90 UNION ALL SELECT 'b1','1.5 Litros',11.90
  UNION ALL SELECT 'b2','Personal',4.90 UNION ALL SELECT 'b2','1 Litro',8.90 UNION ALL SELECT 'b2','1.5 Litros',11.90
) x ON x.codigo = p.codigo;

-- ============================================================
-- CONSULTAS DE VALIDACIÓN
-- ============================================================
SELECT 'Tablas creadas:' AS info;
SHOW TABLES;

SELECT 'Total de productos por categoria:' AS info;
SELECT categoria, COUNT(*) AS total FROM productos GROUP BY categoria;

SELECT 'Productos con su rango de precios (con tamaños):' AS info;
SELECT p.codigo, p.nombre, MIN(pp.precio) AS precio_min, MAX(pp.precio) AS precio_max
FROM productos p JOIN producto_precios pp ON pp.id_producto = p.id_producto
GROUP BY p.codigo, p.nombre;

SELECT 'Productos de precio unico (simple/promo):' AS info;
SELECT codigo, nombre, precio_unico FROM productos WHERE precio_unico IS NOT NULL;
