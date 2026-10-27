<?php
require 'config.php';
$id_usuario = requerir_sesion();

$data = leer_json_body();
$codigo_metodo = $data['metodo_pago'] ?? '';
$items = $data['items'] ?? [];

if ($codigo_metodo === '' || empty($items)) {
    http_response_code(400);
    echo json_encode(['error' => 'Faltan datos del pedido (carrito vacío o método de pago no elegido).']);
    exit;
}

$stmt = $pdo->prepare('SELECT id_metodo FROM metodos_pago WHERE codigo = ?');
$stmt->execute([$codigo_metodo]);
$metodo = $stmt->fetch();
if (!$metodo) {
    http_response_code(400);
    echo json_encode(['error' => 'Método de pago inválido.']);
    exit;
}

// Cada item llega como:
// { producto_codigo, casco_codigo (o null), opcion, precio, extras_codigos: [...] }
$total = 0;
foreach ($items as $it) {
    $total += (float)($it['precio'] ?? 0);
}

$codigo_pedido = 'PED-' . strtoupper(substr(uniqid(), -6));

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('INSERT INTO pedidos (codigo_pedido, id_usuario, id_metodo, total, estado) VALUES (?, ?, ?, ?, "recibido")');
    $stmt->execute([$codigo_pedido, $id_usuario, $metodo['id_metodo'], $total]);
    $id_pedido = $pdo->lastInsertId();

    $stmtProd    = $pdo->prepare('SELECT id_producto FROM productos WHERE codigo = ?');
    $stmtCasco   = $pdo->prepare('SELECT id_casco FROM cascos_relleno WHERE codigo = ?');
    $stmtIng     = $pdo->prepare('SELECT id_ingrediente FROM ingredientes_extra WHERE codigo = ?');
    $stmtDetalle = $pdo->prepare('INSERT INTO detalle_pedido (id_pedido, id_producto, id_casco, opcion_tamano, precio_unitario) VALUES (?, ?, ?, ?, ?)');
    $stmtExtra   = $pdo->prepare('INSERT INTO detalle_extra (id_detalle, id_ingrediente) VALUES (?, ?)');

    foreach ($items as $it) {
        $stmtProd->execute([$it['producto_codigo']]);
        $prod = $stmtProd->fetch();
        if (!$prod) { throw new Exception('Producto no encontrado: ' . $it['producto_codigo']); }

        $id_casco = null;
        if (!empty($it['casco_codigo'])) {
            $stmtCasco->execute([$it['casco_codigo']]);
            $casco = $stmtCasco->fetch();
            $id_casco = $casco ? $casco['id_casco'] : null;
        }

        $stmtDetalle->execute([
            $id_pedido,
            $prod['id_producto'],
            $id_casco,
            $it['opcion'] ?? 'Único',
            $it['precio'] ?? 0,
        ]);
        $id_detalle = $pdo->lastInsertId();

        foreach (($it['extras_codigos'] ?? []) as $codigo_ing) {
            $stmtIng->execute([$codigo_ing]);
            $ing = $stmtIng->fetch();
            if ($ing) {
                $stmtExtra->execute([$id_detalle, $ing['id_ingrediente']]);
            }
        }
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'codigo_pedido' => $codigo_pedido, 'total' => $total]);
} catch (Exception $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => 'No se pudo registrar el pedido: ' . $e->getMessage()]);
}
