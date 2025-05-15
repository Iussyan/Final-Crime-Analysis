<?php
// fetch_chart_data.php
include '../secure/connection.php';

header('Content-Type: application/json');

// Fetch Crime Frequency per Street
$streetSql = "SELECT street, COUNT(*) AS crimeCount FROM incident_data
              JOIN streets ON incident_data.streetId = streets.Id
              GROUP BY street";
$streetResult = $conn->query($streetSql);
$streetData = [];
while ($row = $streetResult->fetch_assoc()) {
    $streetData[] = $row;
}

// Fetch Crime Type Distribution
$crimeTypeSql = "SELECT crimeType, COUNT(*) AS crimeCount FROM crime_data
                 GROUP BY crimeType";
$crimeTypeResult = $conn->query($crimeTypeSql);
$crimeTypeData = [];
while ($row = $crimeTypeResult->fetch_assoc()) {
    $crimeTypeData[] = $row;
}

// Fetch Witness Age Distribution
$ageSql = "SELECT 
            CASE
                WHEN witnessAge BETWEEN 0 AND 18 THEN '0-18'
                WHEN witnessAge BETWEEN 19 AND 35 THEN '19-35'
                WHEN witnessAge BETWEEN 36 AND 50 THEN '36-50'
                WHEN witnessAge BETWEEN 51 AND 65 THEN '51-65'
                ELSE '66+' 
            END AS ageRange,
            COUNT(*) AS count
            FROM incident_data
            GROUP BY ageRange";
$ageResult = $conn->query($ageSql);
$ageData = [];
while ($row = $ageResult->fetch_assoc()) {
    $ageData[] = $row;
}

// Return all data as a JSON response
echo json_encode([
    'streetData' => $streetData,
    'crimeTypeData' => $crimeTypeData,
    'ageData' => $ageData
]);
?>
