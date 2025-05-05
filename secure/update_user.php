<?php
require_once 'connection.php';

$response = ['success' => false];

$id = $_POST['id'] ?? null;
$username = $_POST['username'] ?? '';
$firstName = $_POST['firstName'] ?? '';
$lastName = $_POST['lastName'] ?? '';
$email = $_POST['email'] ?? '';
$contact = $_POST['contact'] ?? '';
$role = $_POST['role'] ?? '';

if ($id && $username && $firstName && $lastName && $email && $contact && $role) {
    $stmt = $conn->prepare("UPDATE accounts SET username = ?, firstName = ?, lastName = ?, email = ?, contact = ?, role = ? WHERE id = ?");
    $stmt->bind_param("ssssssi", $username, $firstName, $lastName, $email, $contact, $role, $id);

    if ($stmt->execute()) {
        $response['success'] = true;
    }

    $stmt->close();
}

echo json_encode($response);
$conn->close();
