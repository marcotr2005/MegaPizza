<?php
// ============================================================
// config.php — Conexión a la base de datos + configuración
// general del backend de MegaPizza.
//
// IMPORTANTE: si tu MySQL/XAMPP tiene usuario o contraseña
// distintos, cámbialos aquí abajo.
// ============================================================

// Permite que el navegador (index.html) hable con este backend
// aunque no estén en el mismo puerto, y mantiene la sesión (cookies).
header('Access-Control-Allow-Origin: ' . ($_SERVER['HTTP_ORIGIN'] ?? '*'));
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

session_start();

$DB_HOST = 'localhost';
$DB_NAME = 'megapizza';
$DB_USER = 'megapizza_user';
$DB_PASS = 'clave123';          // <-- pon aquí tu contraseña de MySQL si tienes una
$DB_CHARSET = 'utf8mb4';

$dsn = "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=$DB_CHARSET";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $DB_USER, $DB_PASS, $options);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'No se pudo conectar a la base de datos. Verifica que MySQL esté encendido y que importaste megapizza_bd.sql. Detalle: ' . $e->getMessage()]);
    exit;
}

// Lee el body JSON de la petición (POST) como arreglo asociativo.
function leer_json_body(): array {
    $data = json_decode(file_get_contents('php://input'), true);
    return is_array($data) ? $data : [];
}

// Corta la ejecución si no hay una sesión de usuario activa.
function requerir_sesion(): int {
    if (!isset($_SESSION['id_usuario'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Debes iniciar sesión.']);
        exit;
    }
    return (int)$_SESSION['id_usuario'];
}
