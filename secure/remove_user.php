<?php
require 'connection.php';

$data = json_decode(file_get_contents("php://input"), true);
$userId = $data['id'];
$response = ['success' => false];

if ($userId) {
    // Prepare the SQL statement to delete the user
    $stmt = $conn->prepare("DELETE FROM accounts WHERE id = ?");
    $stmt->bind_param("i", $userId);

    // Execute the query and check if successful
    if ($stmt->execute()) {
        $response['success'] = true;
    }

    $stmt->close();
}

echo json_encode($response);
?>
