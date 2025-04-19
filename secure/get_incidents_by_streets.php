<?php
header('Content-Type: application/json');

$streetId = $_GET['streetId'] ?? null;

if (!$streetId || !is_numeric($streetId)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid or missing streetId"]);
    exit;
}

// Assuming $conn is already defined from an included connection file
require_once 'connection.php'; // only if your $conn is defined elsewhere

$stmt = $conn->prepare("CALL getIncidentReportsByStreetId(?)");

if (!$stmt) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement", "details" => $conn->error]);
    exit;
}

$stmt->bind_param("i", $streetId);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

$stmt->close();
$conn->next_result(); // Important after calling a stored procedure

echo json_encode($data);
