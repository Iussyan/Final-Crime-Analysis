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

// Collect input
addCondition("incident_id", $_GET['incident_id'] ?? '', true);
addCondition("category", $_GET['category'] ?? '', true);
addCondition("crime_type", $_GET['crime_type'] ?? '', true);
addCondition("crime_description", $_GET['crime_description'] ?? '', true);
addCondition("date", $_GET['date'] ?? '');
addCondition("time", $_GET['time'] ?? '');
addCondition("address", $_GET['address'] ?? '', true);
addCondition("street_name", $_GET['street_name'] ?? '', true);
addCondition("highway", $_GET['highway'] ?? '', true);
addCondition("oneway", $_GET['oneway'] ?? '');
addCondition("witness_name", $_GET['witness_name'] ?? '', true);
addCondition("witness_age", $_GET['witness_age'] ?? '');
addCondition("witness_sex", $_GET['witness_sex'] ?? '');
addCondition("contact_number", $_GET['contact_number'] ?? '', true);
if (!empty($_GET['Status'])) {
    addCondition("Status", $_GET['Status'], true);
}

// Final query
$sql = "SELECT * FROM vw_incident_report";
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
    $types = str_repeat("s", count($params)); // or adjust if using int
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$result = $stmt->get_result();

$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}

echo json_encode($rows);
