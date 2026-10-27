<?php
require 'config.php';

$data = leer_json_body();
$email    = trim($data['email'] ?? '');
$password = $data['password'] ?? '';

$stmt = $pdo->prepare('SELECT * FROM usuarios WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode(['error' => 'Correo o contraseña incorrectos. ¿Necesitas registrarte?']);
    exit;
}

$_SESSION['id_usuario'] = (int)$user['id_usuario'];
$_SESSION['nombre']     = $user['nombre'];
$_SESSION['email']      = $user['email'];

echo json_encode([
    'success' => true,
    'user' => [
        'id' => (int)$user['id_usuario'],
        'name' => $user['nombre'],
        'email' => $user['email'],
        'address' => $user['direccion'],
    ],
]);
