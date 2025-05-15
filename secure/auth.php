<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function requireRole($role) {
    if (!isset($_SESSION['logged_in']) || $_SESSION['role'] !== $role) {
        // Optional: log unauthorized access attempts here
        header("Location: ../process/login.php");
        exit();
    }
}
