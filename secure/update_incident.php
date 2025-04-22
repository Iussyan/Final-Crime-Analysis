<?php
require 'connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $incidentId = $_POST['Incident_ID'];

    // Data for incident_data
    $date = $_POST['Date'];
    $time = $_POST['Time'];
    $address = $_POST['Address'];
    $witnessName = $_POST['Witness_Name'];
    $witnessAge = $_POST['Witness_Age'];
    $witnessSex = $_POST['Witness_Sex'];
    $contactNumber = $_POST['Contact_Number'];

    // Data for crime_data
    $category = $_POST['Category'];
    $crimeType = $_POST['Crime_Type'];
    $crimeDescription = $_POST['Crime_Description'];
    $status = $_POST['Status'];

    // Assume you get Street_Name and look up streetId
    $streetName = $_POST['Street_Name'];
    $streetStmt = $conn->prepare("SELECT Id FROM streets WHERE Name = ?");
    $streetStmt->bind_param("s", $streetName);
    $streetStmt->execute();
    $streetResult = $streetStmt->get_result();
    $streetId = $streetResult->fetch_assoc()['Id'] ?? null;
    $streetStmt->close();

    if (!$streetId) {
        echo json_encode(['success' => false, 'message' => 'Street not found']);
        exit;
    }

    // Update incident_data
    $incidentStmt = $conn->prepare("UPDATE incident_data SET date = ?, time = ?, address = ?, witnessName = ?, witnessAge = ?, witnessSex = ?, contactNumber = ?, streetId = ? WHERE id = ?");
    $incidentStmt->bind_param("sssssssii", $date, $time, $address, $witnessName, $witnessAge, $witnessSex, $contactNumber, $streetId, $incidentId);
    $incidentSuccess = $incidentStmt->execute();
    $incidentStmt->close();

    // Update crime_data
    $crimeStmt = $conn->prepare("UPDATE crime_data SET category = ?, crimeType = ?, crimeDescription = ?, status = ? WHERE incidentId = ?");
    $crimeStmt->bind_param("ssssi", $category, $crimeType, $crimeDescription, $status, $incidentId);
    $crimeSuccess = $crimeStmt->execute();
    $crimeStmt->close();

    echo json_encode(['success' => $incidentSuccess && $crimeSuccess]);
}
?>
