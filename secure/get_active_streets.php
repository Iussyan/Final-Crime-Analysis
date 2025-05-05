<?php
include 'connection.php'; // adjust path as needed

$query = "CALL getAllStreetsWithCrimeCount()";
$result = $conn->query($query);

$features = [];

while ($row = $result->fetch_assoc()) {
    $feature = [
        "type" => "Feature",
        "geometry" => json_decode($row['geojson']),
        "properties" => [
            "streetId" => $row['streetId'],
            "streetName" => $row['streetName'],
            "categories" => $row['categories'],
            "crimes" => $row['crimes'],
            "crimeCount" => (int)$row['crimeCount']
        ]
    ];
    $features[] = $feature;
}

// Return full GeoJSON collection
echo json_encode([
    "type" => "FeatureCollection",
    "features" => $features
]);

$conn->close();
?>
