<?php
require 'config.php';

if (isset($_SESSION['id_usuario'])) {
    $stmt = $pdo->prepare('SELECT id_usuario, nombre, email, direccion FROM usuarios WHERE id_usuario = ?');
    $stmt->execute([$_SESSION['id_usuario']]);
    $user = $stmt->fetch();

    if ($user) {
        echo json_encode([
            'logged_in' => true,
            'user' => [
                'id' => (int)$user['id_usuario'],
                'name' => $user['nombre'],
                'email' => $user['email'],
                'address' => $user['direccion'],
            ],
        ]);
        exit;
    }
}

echo json_encode(['logged_in' => false]);
