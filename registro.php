<?php
require 'config.php';

$data = leer_json_body();
$nombre    = trim($data['nombre'] ?? '');
$email     = trim($data['email'] ?? '');
$direccion = trim($data['direccion'] ?? '');
$password  = $data['password'] ?? '';

if ($nombre === '' || $email === '' || $direccion === '' || strlen($password) < 6) {
    http_response_code(400);
    echo json_encode(['error' => 'Completa todos los campos. La contraseña debe tener al menos 6 caracteres.']);
    exit;
}

$stmt = $pdo->prepare('SELECT id_usuario FROM usuarios WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['error' => 'Ese correo ya está registrado. Intenta iniciar sesión.']);
    exit;
}

$hash = password_hash($password, PASSWORD_DEFAULT);

$stmt = $pdo->prepare('INSERT INTO usuarios (nombre, email, direccion, password_hash) VALUES (?, ?, ?, ?)');
$stmt->execute([$nombre, $email, $direccion, $hash]);
$id_usuario = (int)$pdo->lastInsertId();

$_SESSION['id_usuario'] = $id_usuario;
$_SESSION['nombre']     = $nombre;
$_SESSION['email']      = $email;

echo json_encode([
    'success' => true,
    'user' => ['id' => $id_usuario, 'name' => $nombre, 'email' => $email, 'address' => $direccion],
]);
