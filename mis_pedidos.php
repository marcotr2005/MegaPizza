<?php
require 'config.php';
$id_usuario = requerir_sesion();

$stmt = $pdo->prepare('
    SELECT p.id_pedido, p.codigo_pedido, p.fecha, p.total, mp.codigo AS metodo_pago,
           TIMESTAMPDIFF(SECOND, p.fecha, NOW()) AS segundos_transcurridos
    FROM pedidos p
    JOIN metodos_pago mp ON mp.id_metodo = p.id_metodo
    WHERE p.id_usuario = ?
    ORDER BY p.fecha DESC
');
$stmt->execute([$id_usuario]);
$pedidos = $stmt->fetchAll();

$stmtItems = $pdo->prepare('
    SELECT dp.id_detalle, pr.nombre AS nombre_producto, dp.opcion_tamano, dp.precio_unitario, cr.nombre AS casco
    FROM detalle_pedido dp
    JOIN productos pr ON pr.id_producto = dp.id_producto
    LEFT JOIN cascos_relleno cr ON cr.id_casco = dp.id_casco
    WHERE dp.id_pedido = ?
');
$stmtExtras = $pdo->prepare('
    SELECT ie.nombre FROM detalle_extra de
    JOIN ingredientes_extra ie ON ie.id_ingrediente = de.id_ingrediente
    WHERE de.id_detalle = ?
');

// ------------------------------------------------------------
// Tiempos de cada etapa del pedido (función escalón, ecuación (3) del informe).
//
//   MODO_DEMO = true  -> 30 segundos por etapa (ideal para la exposición)
//   MODO_DEMO = false -> tiempos "reales": 1, 4 y 9 minutos (como en el informe)
// ------------------------------------------------------------
const MODO_DEMO = true;

// Segundos que deben pasar desde que se hizo el pedido para entrar a cada etapa
const UMBRALES_SEG = MODO_DEMO ? [0, 30, 60, 90] : [0, 60, 240, 540];

const ETAPAS = [
    ['key' => 'recibido',    'label' => 'Recibido',       'seg' => UMBRALES_SEG[0]],
    ['key' => 'preparacion', 'label' => 'En preparación', 'seg' => UMBRALES_SEG[1]],
    ['key' => 'camino',      'label' => 'En camino',      'seg' => UMBRALES_SEG[2]],
    ['key' => 'entregado',   'label' => 'Entregado',      'seg' => UMBRALES_SEG[3]],
];

// El tiempo transcurrido lo calcula MySQL (NOW() - fecha del pedido), de modo que
// usa el MISMO reloj y la MISMA zona horaria con que se guardó el pedido. Antes se
// usaba time() de PHP, y si PHP y MySQL tenían zonas horarias distintas (común en
// XAMPP), el pedido aparecía como "Entregado" apenas se creaba.
function calcular_etapa(int $segundos): array {
    $segundos = max(0, $segundos);
    $actual = ETAPAS[0];
    foreach (ETAPAS as $etapa) {
        if ($segundos >= $etapa['seg']) $actual = $etapa;
    }
    return $actual;
}

foreach ($pedidos as &$ped) {
    $stmtItems->execute([$ped['id_pedido']]);
    $items = $stmtItems->fetchAll();
    foreach ($items as &$it) {
        $stmtExtras->execute([$it['id_detalle']]);
        $it['extras'] = array_column($stmtExtras->fetchAll(), 'nombre');
        $it['precio_unitario'] = (float)$it['precio_unitario'];
    }
    unset($it);

    $ped['items'] = $items;
    $ped['total'] = (float)$ped['total'];
    $etapa = calcular_etapa((int)$ped['segundos_transcurridos']);
    $ped['segundos_transcurridos'] = max(0, (int)$ped['segundos_transcurridos']);
    $ped['minutos_transcurridos'] = (int)floor(max(0, (int)$ped['segundos_transcurridos']) / 60);
    $ped['estado'] = $etapa['key'];
    $ped['estado_label'] = $etapa['label'];
}
unset($ped);

echo json_encode(['pedidos' => $pedidos]);
