<?php
session_start();
include "../secure/connection.php"; // Include the database connection file

// 🚀 Handle Import When AJAX Submitted
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        exit("Invalid CSRF token.");
    }

    $table = preg_replace('/[^a-zA-Z0-9_]/', '', $_POST['table_name']);
    $fileTmp = $_FILES['csv_file']['tmp_name'];

    $mime = mime_content_type($fileTmp);
    if (!in_array($mime, ['text/plain', 'text/csv', 'application/vnd.ms-excel'])) {
        exit("Only CSV files are allowed.");
    }

    // Get table columns
    $columns = [];
    $res = $conn->query("SHOW COLUMNS FROM `$table`");
    while ($row = $res->fetch_assoc()) {
        $columns[] = $row['Field'];
    }

    if (($handle = fopen($fileTmp, "r")) !== false) {
        $header = fgetcsv($handle);
        $header = array_map('trim', $header);

        $matchingCols = array_intersect($columns, $header);
        if (count($matchingCols) === 0) {
            exit("CSV columns do not match any fields in `$table`.");
        }

        $placeholders = implode(",", array_fill(0, count($matchingCols), '?'));
        $sql = "INSERT INTO `$table` (" . implode(",", $matchingCols) . ") VALUES ($placeholders)";
        $stmt = $conn->prepare($sql);

        $imported = 0;
        while (($data = fgetcsv($handle)) !== false) {
            $row = array_combine($header, $data);
            $values = [];
            foreach ($matchingCols as $col) {
                $values[] = isset($row[$col]) ? $row[$col] : null;
            }

            $types = str_repeat("s", count($values)); // Assume strings
            $stmt->bind_param($types, ...$values);
            if ($stmt->execute()) $imported++;
        }

        fclose($handle);
        $stmt->close();
        echo "✅ Successfully imported $imported rows into <strong>$table</strong>.";
        echo "<a href='../main/crime_data.php'>Go back</a>";
    } else {
        echo "Failed to open the CSV file.";
    }
    exit;
}
?>