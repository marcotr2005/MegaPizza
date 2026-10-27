<?php
require 'config.php';

$productos = $pdo->query('SELECT id_producto, codigo, nombre, categoria, tipo, imagen_url, precio_unico FROM productos WHERE activo = 1 ORDER BY id_producto')->fetchAll();
$precios   = $pdo->query('SELECT id_producto, opcion, precio FROM producto_precios')->fetchAll();

$preciosPorProducto = [];
foreach ($precios as $p) {
    $preciosPorProducto[$p['id_producto']][$p['opcion']] = (float)$p['precio'];
}

// Arma la misma forma que menuData en script.js, para poder
// reemplazar el catálogo hardcodeado por el de la base de datos.
$menu = ['clasicas' => [], 'especiales' => [], 'pastas' => [], 'promociones' => [], 'bebidas' => []];

foreach ($productos as $p) {
    $item = [
        'id'   => $p['codigo'],
        'name' => $p['nombre'],
        'type' => $p['tipo'],
        'img'  => $p['imagen_url'],
    ];
    if ($p['precio_unico'] !== null) {
        $item['price'] = (float)$p['precio_unico'];
    } else {
        $item['prices'] = $preciosPorProducto[$p['id_producto']] ?? [];
    }
    if (isset($menu[$p['categoria']])) {
        $menu[$p['categoria']][] = $item;
    }
}

$cascos = $pdo->query('SELECT codigo, nombre AS label, precio_adicional AS price FROM cascos_relleno')->fetchAll();
foreach ($cascos as &$c) { $c['price'] = (float)$c['price']; $c['key'] = $c['codigo']; unset($c['codigo']); }

$extras = $pdo->query('SELECT codigo, nombre AS label, precio_adicional AS price FROM ingredientes_extra')->fetchAll();
foreach ($extras as &$e) { $e['price'] = (float)$e['price']; $e['key'] = $e['codigo']; unset($e['codigo']); }

echo json_encode([
    'menuData' => $menu,
    'crustOptions' => $cascos,
    'extraIngredients' => $extras,
]);
