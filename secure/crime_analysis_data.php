<?php
// File: crime_analysis_data.php

// 1) Session & authentication
if (session_status() === PHP_SESSION_NONE) session_start();
if (empty($_SESSION['logged_in'])) {
    http_response_code(401);
    echo json_encode(['error' => 'Not authenticated']);
    exit;
}

// 2) Database connection
require_once '../secure/connection.php';
header('Content-Type: application/json');

// Prepare response array
$response = [
    'monthly'       => [],
    'crimeType'     => [],
    'streetData'    => [],
    'ageData'       => []
];

// 3) Monthly Crime Data
$sql = "
    SELECT DATE_FORMAT(`date`, '%Y-%m') AS month, COUNT(*) AS total
    FROM incident_data
    GROUP BY month
    ORDER BY month
";
if ($result = $conn->query($sql)) {
    $response['monthly'] = $result->fetch_all(MYSQLI_ASSOC);
}

// 4) Crime Type Breakdown
$sql2 = "
    SELECT crimeType, COUNT(*) AS total
    FROM crime_data
    GROUP BY crimeType
";
if ($result2 = $conn->query($sql2)) {
    $response['crimeType'] = $result2->fetch_all(MYSQLI_ASSOC);
}

// 5) Crime Frequency per Street
$sql3 = "
    SELECT street, COUNT(*) AS crimeCount
    FROM incident_data
    JOIN streets ON incident_data.streetId = streets.Id
    GROUP BY street
";
if ($result3 = $conn->query($sql3)) {
    $response['streetData'] = $result3->fetch_all(MYSQLI_ASSOC);
}

// 6) Witness Age Distribution
$sql4 = "
    SELECT 
        CASE
            WHEN witnessAge BETWEEN 0 AND 18 THEN '0-18'
            WHEN witnessAge BETWEEN 19 AND 35 THEN '19-35'
            WHEN witnessAge BETWEEN 36 AND 50 THEN '36-50'
            WHEN witnessAge BETWEEN 51 AND 65 THEN '51-65'
            ELSE '66+'
        END AS ageRange,
        COUNT(*) AS count
    FROM incident_data
    GROUP BY ageRange
";
if ($result4 = $conn->query($sql4)) {
    $response['ageData'] = $result4->fetch_all(MYSQLI_ASSOC);
}

// Final JSON output
echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_NUMERIC_CHECK);

// Close DB
$conn->close();
