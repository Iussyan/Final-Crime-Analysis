<?php
include "connection.php";

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST['login'])) {
    $username = $_POST['user'];
    $password = $_POST['pass'];

    // Get all necessary user data
    $stmt = $conn->prepare("SELECT id, username, password, firstName, lastName, email, contact, role FROM accounts WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result && $result->num_rows === 1) {
        $user_data = $result->fetch_assoc();

        if (password_verify($password, $user_data['password'])) {
            // Login successful
            $_SESSION['user_id'] = $user_data['id'];
            $_SESSION['username'] = $user_data['username'];
            $_SESSION['firstName'] = $user_data['firstName'];
            $_SESSION['lastName'] = $user_data['lastName'];
            $_SESSION['email'] = $user_data['email'];
            $_SESSION['contact'] = $user_data['contact'];
            $_SESSION['role'] = $user_data['role'];

            if ($_SESSION['role'] === 'admin') {
                $_SESSION['admin'] = true;
            }

            $_SESSION['loginSuccess'] = true;
            $_SESSION['logged_in'] = true;
            header("Location: vital_datas.php");
            
            exit();
        }
    }
    // If we reach here, login failed
    $_SESSION["loginFailed"] = true;
    header("Location: ../process/login.php");
    exit();
} else {
    // Invalid request method or missing login
    $_SESSION["loginFailed"] = true;
    header("Location: ../process/login.php");
    exit();
}
