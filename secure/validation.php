<?php
// filepath: c:\xampp\htdocs\Crime-Analysis\validation.php
include "connection.php"; // Include the database connection file

// Start the session if it is not already active
if (session_status() === PHP_SESSION_NONE) {
    session_start(); // Start the session to store user data
}  
if (isset($_SERVER["REQUEST_METHOD"]) == "POST") {
    // Check if the form is submitted
    if (isset($_POST['login'])) {
        // Get the username and password from the form
        $username = $_POST['user'];
        $password = $_POST['pass'];

        // Prepare and bind the SQL statement to prevent SQL injection
        $stmt = $conn->prepare("SELECT * FROM accounts WHERE username = ? AND password = ?");
        $stmt->bind_param("ss", $username, $password); // "ss" means both parameters are strings

        // Execute the statement
        $stmt->execute();

        // Store the result
        $result = $stmt->get_result();

        // Check if a user was found
        if ($result->num_rows > 0) {
            // User found, fetch user data
            $user_data = $result->fetch_assoc();
            $_SESSION['admin_logged_in'] = true; // Set session variable to indicate admin is logged in
            $_SESSION['user_id'] = $user_data['id']; // Store user ID in session
            $_SESSION['username'] = $user_data['username']; // Store username in session
            $_SESSION['firstName'] = $user_data['firstName']; // Store user first name in session
            $_SESSION['lastName'] = $user_data['lastName']; // Store user last name in session
            $_SESSION['email'] = $user_data['email']; // Store user email in session
            $_SESSION['contact'] = $user_data['contact']; // Store user contact in session
            $_SESSION['role'] = $user_data['role']; // Store user role in session
            
            // Redirect to the dashboard or home page
            header("Location: ../main/dashboard.php"); // Change this to your desired page
            exit(); // Stop further script execution after redirection
        } else {
            // Invalid credentials, redirect back to login with an error message
            echo "<script>alert('Invalid username or password'); window.location.href='login.php';</script>";
            exit();
        }

    }
} else {
    // If the request method is not POST, redirect to login page
    header("Location: ../main/login.php");
    exit();
}
?>