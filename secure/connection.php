<?php
// Start the session if it is not already active
if (session_status() === PHP_SESSION_NONE) {
    session_start();
    // `session_start()` is required to initialize or resume a session, allowing data to be stored and accessed across multiple pages.
}
// Database connection details
$servername = "127.0.0.1";
$username = "root";
$password = "";
$database = "charm_db";

// Enable error reporting for mysqli
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// Create connection
$conn = mysqli_connect($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection to database '{$database}' failed: {$conn->connect_error}");
} else {
    error_log("Database connected successfully."); // Optional: For debugging purposes
}
?>