<?php
session_start();
include "../secure/connection.php";
$loginFailed = isset($_SESSION['loginFailed']) && $_SESSION['loginFailed'];
unset($_SESSION['loginFailed']);
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>

<body>
    <?php if ($loginFailed): ?>
        <div class="alert alert-danger" data-type="danger" data-from="top" data-align="center">Login credentials are incorrect. Try again.</div>
    <?php endif; ?>

    <div>
        <h1>Crime Analysis</h1>
        <form method="POST" action="../secure/validation.php">
            <label for="username">Username:</label>
            <input type="text" id="username" name="user" required><br><br>
            <label for="password">Password:</label>
            <input type="password" id="password" name="pass" required><br><br>
            <button type="submit" name="login">Login</button>
        </form>
    </div>
</body>

</html>