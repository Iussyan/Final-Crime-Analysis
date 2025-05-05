<?php
require_once "connection.php";

header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $input = json_decode(file_get_contents("php://input"), true);

    if (!isset($input["streetIds"]) || !is_array($input["streetIds"])) {
        http_response_code(400);
        echo json_encode(["error" => "Missing or invalid streetIds array"]);
        exit;
    }

    $streetJson = json_encode($input["streetIds"]);

    $stmt = $conn->prepare("CALL getActiveStreetsIncidents(?)");
    $stmt->bind_param("s", $streetJson);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $incidents = [];

        while ($row = $result->fetch_assoc()) {
            $incidents[] = $row;
        }

        echo json_encode(["success" => true, "data" => $incidents]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Database query failed"]);
    }

    $stmt->close();
    $conn->close();
} else {
    http_response_code(405);
    echo json_encode(["error" => "Only POST method allowed"]);
}
?>
