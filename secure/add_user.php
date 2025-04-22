<?php
require_once('connection.php');

$firstName = $_POST['firstName'] ?? null;
$lastName = $_POST['lastName'] ?? null;
$username = $_POST['username'] ?? null;
$email = $_POST['email'] ?? null;
$password = $_POST['password'] ?? null;
$contact = $_POST['contact'] ?? null;
$role = $_POST['role'] ?? 'User';

$errors = [];

$requiredFields = [
    'First Name' => $firstName,
    'Last Name' => $lastName,
    'Username' => $username,
    'Email' => $email,
    'Password' => $password
];

foreach ($requiredFields as $field => $value) {
    if (empty($value)) {
        $errors[] = "$field is required.";
    }
}

if (!empty($errors)) {
    echo "<script>alert('" . implode(', ', $errors) . "');</script>";
    echo "<script>window.history.back();</script>";
    exit;
}

$checkUser = $conn->prepare("SELECT id FROM accounts WHERE username = ? OR email = ?");
$checkUser->bind_param("ss", $username, $email);
$checkUser->execute();
$checkUser->store_result();

if ($checkUser->num_rows > 0) {
    echo "<script>alert('Username or email already exists.');</script>";
    echo "<script>window.history.back();</script>";
    exit;
}
$checkUser->close();

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

$insert = $conn->prepare("INSERT INTO accounts (username, password, firstName, lastName, email, contact, role) VALUES (?, ?, ?, ?, ?, ?, ?)");
$insert->bind_param("sssssss", $username, $hashedPassword, $firstName, $lastName, $email, $contact, $role);

if ($insert->execute()) {
    $_SESSION['Success'] = true;
    header("Location: ../temp/manage_users.php");
    exit;
} else {
    echo "Failed to add user.";
}

$insert->close();
$conn->close();
?>
