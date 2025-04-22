<?php
header('Content-Type: application/json');

require_once 'connection.php';

$streetId = $_GET['streetId'] ?? null;

if (!$streetId || !is_numeric($streetId)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid or missing streetId"]);
    exit;
}

$data = [];

if ($stmt = $conn->prepare("CALL getIncidentReportsByStreetId(?)")) {
    $stmt->bind_param("i", $streetId);
    $stmt->execute();

    // Use get_result if available
    if ($result = $stmt->get_result()) {
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        $result->free();
    } else {
        // Fallback to bind_result if get_result fails
        $stmt->store_result();
        if ($stmt->num_rows > 0) {
            $stmt->bind_result(
                $IncidentId,
                $Address,
                $Street,
                $StreetId,
                $Category,
                $CrimeType,
                $CrimeDescription,
                $WitnessName,
                $WitnessAge,
                $WitnessSex,
                $WitnessContact
            );

            while ($stmt->fetch()) {
                $data[] = [
                    'IncidentId' => $IncidentId,
                    'Address' => $Address,
                    'Street' => $Street,
                    'StreetId' => $StreetId,
                    'Category' => $Category,
                    'Crime Type' => $CrimeType,
                    'Crime Description' => $CrimeDescription,
                    'Witness Name' => $WitnessName,
                    'Witness Age' => $WitnessAge,
                    'Witness Sex' => $WitnessSex,
                    'Witness Contact' => $WitnessContact,
                ];
            }
        }
    }

    $stmt->close();
    $conn->next_result(); // Important after stored procedure
}

echo json_encode($data);
