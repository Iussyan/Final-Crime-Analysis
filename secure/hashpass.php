<?php
require 'connection.php';

$result = $conn->query("SELECT id, password FROM accounts");

while ($row = $result->fetch_assoc()) {
    $id = $row['id'];
    $plainPassword = $row['password'];

    $hashed = password_hash($plainPassword, PASSWORD_DEFAULT);

    $update = $conn->prepare("UPDATE accounts SET password = ? WHERE id = ?");
    $update->bind_param("si", $hashed, $id);
    $update->execute();
    $update->close();
}

echo "Passwords hashed successfully.";
