<?php
require 'config.php';
$_SESSION = [];
session_destroy();
echo json_encode(['success' => true]);
