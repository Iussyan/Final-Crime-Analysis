<?php
require 'connection.php';

$data = json_decode(file_get_contents("php://input"), true);
$incidentId = $data['id'];
$isUnarchive = isset($data['unarchive']) && $data['unarchive'];

$statusToSet = $isUnarchive ? 'Active' : 'Archived';
$response = ['success' => false];

if ($incidentId) {
    $stmt = $conn->prepare("UPDATE crime_data SET status = ? WHERE incidentid = ?");
    $stmt->bind_param("si", $statusToSet, $incidentId);
    if ($stmt->execute()) {
        $response['success'] = true;
    }
    $stmt->close();
}

echo json_encode($response);
?>
