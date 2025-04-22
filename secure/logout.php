<?php
// logout.php
session_start();
session_unset();  // Remove session variables
session_destroy();  // Destroy the session

// Redirect to login page after logout
header("Location: ../temp/login.php");
exit;
?>
