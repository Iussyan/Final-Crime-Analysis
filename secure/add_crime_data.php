<?php
require_once('connection.php'); // Your DB config

// Sanitize & Validate Inputs
$selectedStreetName = $_POST['selectedStreetName'] ?? null;
$selectedStreetId = $_POST['selectedStreetId'] ?? null;
$crimeLocation = $_POST['crimeLocation'] ?? null;
$category = $_POST['category'] ?? null;
$crime = $_POST['crime'] ?? null;
$address = $_POST['address'] ?? null;
$date = $_POST['date'] ?? null;
$time = $_POST['time'] ?? null;
$description = $_POST['description'] ?? null;
$witnessName = $_POST['witness_name'] ?? null;
$witnessAge = $_POST['witness_age'] ?? null;
$witnessSex = $_POST['witness_sex'] ?? null;
$contactNumber = $_POST['contact_number'] ?? null;

$errors = [];

// Required field checks
$requiredFields = [
    'Street ID' => $selectedStreetId,
    'Crime' => $crime,
    'Address' => $address,
    'Date' => $date,
    'Time' => $time,
    'Description' => $description,
    'Witness Name' => $witnessName,
    'Witness Age' => $witnessAge,
    'Witness Sex' => $witnessSex
];

foreach ($requiredFields as $fieldName => $fieldValue) {
    if (!$fieldValue) {
        $errors[] = "$fieldName is missing";
    }
}

if (!empty($errors)) {
    echo "<script>alert('" . implode(', ', $errors) . "');</script>";
    echo "<script>window.history.back();</script>";
    exit;
}

// Make sure it's not empty
if (!$selectedStreetId) {
    echo "Street ID not provided.";
    exit;
}

// Query the streets table for internal Id
$getStreet = $conn->prepare("SELECT Id FROM streets WHERE StreetId = ?");
$getStreet->bind_param("s", $selectedStreetId);
$getStreet->execute();
$getStreet->bind_result($streetDbId);

if ($getStreet->fetch()) {
    $getStreet->close();
} else {
    echo "No matching street found.";
    exit;
}

// Insert into incident_data
$insertIncident = $conn->prepare("INSERT INTO incident_data (address, street, streetId, date, time, witnessName, witnessAge, witnessSex, contactNumber) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
$insertIncident->bind_param("ssisssiss", $address, $selectedStreetName, $streetDbId, $date, $time, $witnessName, $witnessAge, $witnessSex, $contactNumber);
$insertIncident->execute();

if ($insertIncident->affected_rows > 0) {
    $incidentId = $insertIncident->insert_id;

    // Insert into crime_data
    $insertCrime = $conn->prepare("INSERT INTO crime_data (incidentId, category, crimeType, crimeDescription) VALUES (?, ?, ?, ?)");
    $insertCrime->bind_param("isss", $incidentId, $category, $crime, $description);
    $insertCrime->execute();

    if ($insertCrime->affected_rows > 0) {
        $_SESSION['Success'] = true;
        header("Location: ../process/crime_reporting.php");
        exit;
    } else {
        echo "Failed to insert into crime_data.";
    }

    $insertCrime->close();
} else {
    echo "Failed to insert incident.";
}

$insertIncident->close();
$conn->close();
?>