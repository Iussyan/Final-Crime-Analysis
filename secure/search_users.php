<?php
include 'connection.php';
header('Content-Type: application/json');

$conditions = [];
$params = [];

function addCondition($field, $value, $isLike = false) {
    global $conditions, $params;
    if (!empty($value)) {
        if ($isLike) {
            $conditions[] = "$field LIKE ?";
            $params[] = "%" . $value . "%";
        } else {
            $conditions[] = "$field = ?";
            $params[] = $value;
        }
    }
}

// Collect input for user-related fields
addCondition("id", $_GET['id'] ?? '');
addCondition("username", $_GET['username'] ?? '', true);
addCondition("firstName", $_GET['firstName'] ?? '', true);
addCondition("lastName", $_GET['lastName'] ?? '', true);
addCondition("email", $_GET['email'] ?? '', true);
addCondition("contact", $_GET['contact'] ?? '', true);
addCondition("role", $_GET['role'] ?? '', true);

// Final query
$sql = "SELECT * FROM accounts";
if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "SQL error: " . $conn->error]);
    exit;
}

// Bind params dynamically
if (!empty($params)) {
    $types = str_repeat("s", count($params)); // Assuming all fields are strings
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$result = $stmt->get_result();

$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}

echo json_encode($rows);
