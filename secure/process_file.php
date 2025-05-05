<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $host     = $_POST['host'];
    $dbname   = $_POST['dbname'];
    $user     = $_POST['username'];
    $pass     = $_POST['password'];
    $table    = $_POST['table'];

    if (!isset($_FILES['geojson']) || $_FILES['geojson']['error'] !== UPLOAD_ERR_OK) {
        die("Error uploading file.");
    }

    $geojsonContent = file_get_contents($_FILES['geojson']['tmp_name']);
    $data = json_decode($geojsonContent, true);

    if (!$data || !isset($data['features'])) {
        die("Invalid GeoJSON format.");
    }

    $mysqli = new mysqli($host, $user, $pass, $dbname);
    if ($mysqli->connect_error) {
        die("Connection failed: " . $mysqli->connect_error);
    }

    // Prepare insert
    $stmt = $mysqli->prepare("
        INSERT INTO `$table` (Name, Highway, Oneway, OldName, StreetId, Geometry)
        VALUES (?, ?, ?, ?, ?, ST_GeomFromText(?))
    ");

    foreach ($data['features'] as $feature) {
        $props = $feature['properties'];
        $geometry = $feature['geometry'];

        if ($geometry['type'] !== 'LineString') continue;

        $coords = array_map(function ($c) {
            return implode(" ", $c); // lng lat
        }, $geometry['coordinates']);
        $linestring = "LINESTRING(" . implode(", ", $coords) . ")";

        $name = $props['name'] ?? null;
        $highway = $props['highway'] ?? null;
        $oneway = $props['oneway'] ?? null;
        $old_name = $props['old_name'] ?? null;
        $street_id = $props['@id'] ?? null;
        $geom = $linestring;

        $stmt->bind_param("ssssss", $name, $highway, $oneway, $old_name, $street_id, $geom);
        $stmt->execute();
    }

    $stmt->close();
    $mysqli->close();

    echo "Upload and import complete!";
} else {
    echo "Invalid request.";
}
?>
