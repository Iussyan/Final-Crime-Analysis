<?php
session_start();
require_once('connection.php'); // $conn = new mysqli(...);

// Central error collection
$errors = [];

// 1. COLLECT & SANITIZE INPUTS
$selectedStreetName = trim($_POST['selectedStreetName'] ?? '');
$selectedStreetId   = trim($_POST['selectedStreetId']   ?? '');
$crimeLocation      = trim($_POST['crimeLocation']      ?? '');
$category           = trim($_POST['category']           ?? '');
$crime              = trim($_POST['crime']              ?? '');
$address            = trim($_POST['address']            ?? '');
$date               = trim($_POST['date']               ?? '');
$time               = trim($_POST['time']               ?? '');
$description        = trim($_POST['description']        ?? '');
$witnessName        = trim($_POST['witness_name']       ?? '');
$witnessAge         = trim($_POST['witness_age']        ?? '');
$witnessSex         = trim($_POST['witness_sex']        ?? '');
$contactNumber      = trim($_POST['contact_number']     ?? '');

// 2. REQUIRED-FIELD CHECK
$required = [
    'Street ID'    => $selectedStreetId,
    'Category'     => $category,
    'Crime'        => $crime,
    'Address'      => $address,
    'Date'         => $date,
    'Time'         => $time,
    'Description'  => $description,
    'Witness Name' => $witnessName,
    'Witness Age'  => $witnessAge,
    'Witness Sex'  => $witnessSex,
    // 'Contact No.'  => $contactNumber, = Optional
];

foreach ($required as $label => $value) {
    if ($value === '') {
        $errors[] = "$label is required.";
    }
}

// 3. STRONGER VALIDATION
// Date (YYYY-MM-DD)
if ($date !== '' && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
    $errors[] = "Date must be in YYYY-MM-DD format.";
} elseif ($date !== '') {
    list($y, $m, $d) = explode('-', $date);
    if (!checkdate((int)$m, (int)$d, (int)$y)) {
        $errors[] = "Date is not a valid calendar date.";
    }
}

// Time (HH:MM 24-hour)
if ($time !== '' && !preg_match('/^(?:[01]\d|2[0-3]):[0-5]\d$/', $time)) {
    $errors[] = "Time must be in HH:MM (24-hour) format.";
}

// Witness Age (integer, 0–120)
if ($witnessAge !== '' && filter_var($witnessAge, FILTER_VALIDATE_INT, [
    'options' => ['min_range' => 0, 'max_range' => 120]
]) === false) {
    $errors[] = "Witness Age must be an integer between 0 and 120.";
} else {
    $witnessAge = (int)$witnessAge;
}

// Witness Sex (enum)
$allowedSex = ['Male', 'Female'];
if ($witnessSex !== '' && !in_array($witnessSex, $allowedSex, true)) {
    $errors[] = "Witness Sex must be 'Male' or 'Female'.";
}

// Contact Number (basic phone pattern, e.g. digits, +, -, spaces)
if ($contactNumber !== '' && !preg_match('/^[\d\+\-\s]{7,20}$/', $contactNumber)) {
    $errors[] = "Contact Number contains invalid characters.";
}

// 4. IF ANY ERRORS, HALT & SHOW
if (!empty($errors)) {
    echo "<script>alert('" . implode(', ', $errors) . "');</script>";
    echo "<script>window.history.back();</script>";
    exit;
}

// 5. LOOK UP INTERNAL streetId
$stmt = $conn->prepare("SELECT Id FROM streets WHERE StreetId = ?");
$stmt->bind_param("s", $selectedStreetId);
$stmt->execute();
$stmt->bind_result($streetDbId);
if (!$stmt->fetch()) {
    echo "<p>No matching street found for ID " . htmlspecialchars($selectedStreetId) . ".</p>";
    exit;
}
$stmt->close();

// 6. START TRANSACTION
$conn->begin_transaction();

try {
    // 7. INSERT INTO incident_data
    $insertInc = $conn->prepare(
        "INSERT INTO incident_data
         (address, street, streetId, date, time, witnessName, witnessAge, witnessSex, contactNumber)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    $insertInc->bind_param(
        "ssisssiss",
        $address,
        $selectedStreetName,
        $streetDbId,
        $date,
        $time,
        $witnessName,
        $witnessAge,
        $witnessSex,
        $contactNumber
    );
    $insertInc->execute();

    if ($insertInc->affected_rows !== 1) {
        throw new Exception("Failed to insert incident data.");
    }
    $incidentId = $insertInc->insert_id;
    $insertInc->close();

    // 8. INSERT INTO crime_data
    $insertCr = $conn->prepare("INSERT INTO crime_data
         (incidentId, category, crimeType, crimeDescription)
         VALUES (?, ?, ?, ?)");
    $insertCr->bind_param("isss", $incidentId, $category, $crime, $description);
    $insertCr->execute();
    if ($insertCr->affected_rows !== 1) {
        throw new Exception("Failed to insert crime data.");
    }
    $insertCr->close();

    // 9. COMMIT
    $conn->commit();

    // 10. REDIRECT WITH SUCCESS FLAG
    $_SESSION['Success'] = true;
    // Redirect to vital_datas.php with a returnTo parameter
    $returnTo = urlencode('../process/crime_reporting.php');
    header("Location: ../process/vital_datas.php?returnTo=$returnTo");
    exit;
    
} catch (Exception $ex) {
    $conn->rollback();
    echo "<p>Error: " . htmlspecialchars($ex->getMessage()) . "</p>";
    exit;
}
