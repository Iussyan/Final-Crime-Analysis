<?php
include "../secure/connection.php";
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
    // If not logged in, redirect to login.php
    header("Location: login.php");
    exit;  // Ensure no further code is executed
}

$loginSuccess = isset($_SESSION['loginSuccess']) && $_SESSION['loginSuccess'];

$dataAdded = isset($_SESSION['Success']) && $_SESSION['Success'];

$id = $_SESSION['user_id'];
$role = $_SESSION['role'];
$firstName = $_SESSION['firstName'];
$lastName = $_SESSION['lastName'];
$email = $_SESSION['email'];
$contact = $_SESSION['contact'];
$username = $_SESSION['username'];

$recentIncidents = $_SESSION['recentIncidents'] ?? [];
$totalIncidents = $_SESSION['totalIncidents'] ?? 0;

$totalReports = $_SESSION['totalReports'] ?? [];
$totalCrimes = $_SESSION['totalCrimes'] ?? 0;

$mostCommonCategory = $_SESSION['mostCommonCategory'] ?? '';
$totalReport = $_SESSION['totalReport'] ?? 0;

$mostAffectedStreet = $_SESSION['Most Affected Street'] ?? '';
$totalCrime = $_SESSION['Total Crime'] ?? 0;

$streetsTotal = $_SESSION['streetsTotal'] ?? [];

$peakDay = $_SESSION['peakDay'] ?? '';
$peakDayCrimes = $_SESSION['peakDayCrimes'] ?? 0;

$dayCrimeStats = $_SESSION['dayCrimeStats'] ?? [];

$peakHour = $_SESSION['peakHour'] ?? '';
$peakHourCrimes = $_SESSION['peakHourCrimes'] ?? 0;

unset($_SESSION['loginSuccess']);
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <title>Manage Users</title>
    <!-- HTML5 Shim and Respond.js IE10 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 10]>
    <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
    <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
    <!-- Meta -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0, minimal-ui">
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="description" content="CHARM, or Crime Hotspot Analysis Report and Mapping, is a web application that provides a user-friendly interface for analyzing and visualizing crime data." />
    <meta name="keywords" content="responsive, map, analysis, crime, hotspot, report, reporting crime">
    <meta name="author" content="IussDevs" />
    <!-- Favicon icon -->
    <link rel="icon" href="../src/icons/favicon.ico" type="image/x-icon">
    <!-- Google font-->
    <link href="https://fonts.googleapis.com/css?family=Roboto:400,500" rel="stylesheet">
    <!-- Required Fremwork -->
    <link rel="stylesheet" type="text/css" href="assets/css/bootstrap/css/bootstrap.min.css">
    <!-- waves.css -->
    <link rel="stylesheet" href="assets/pages/waves/css/waves.min.css" type="text/css" media="all">
    <!-- themify-icons line icon -->
    <link rel="stylesheet" type="text/css" href="assets/icon/themify-icons/themify-icons.css">
    <!-- Font Awesome -->
    <link rel="stylesheet" type="text/css" href="assets/icon/font-awesome/css/font-awesome.min.css">
    <!-- Style.css -->
    <link rel="stylesheet" href="../secure/apis/leaflet/leaflet.css" crossorigin="" />
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" type="text/css" href="assets/css/jquery.mCustomScrollbar.css">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">

    <!-- Notyf.css -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.css">
    <style>
        .transition-hover {
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .transition-hover:hover {
            transform: scale(1.03);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
        }

        /* Add this to your stylesheet or inside <style> tags */
        @media (min-width: 768px) {
            .custom-modal-width {
                max-width: 95vw;
                /* Use most of the screen */
                width: auto;
            }
        }

        td.wrap-limit {
            max-width: 300px;
            /* Adjust as needed */
            white-space: normal;
            word-break: break-word;
        }

        .fixed-button {
            display: none !important;
        }
    </style>
</head>

<body>
    <!-- Pre-loader start -->
    <div class="theme-loader">
        <div class="loader-track">
            <div class="preloader-wrapper">
                <div class="spinner-layer spinner-blue">
                    <div class="circle-clipper left">
                        <div class="circle"></div>
                    </div>
                    <div class="gap-patch">
                        <div class="circle"></div>
                    </div>
                    <div class="circle-clipper right">
                        <div class="circle"></div>
                    </div>
                </div>
                <div class="spinner-layer spinner-red">
                    <div class="circle-clipper left">
                        <div class="circle"></div>
                    </div>
                    <div class="gap-patch">
                        <div class="circle"></div>
                    </div>
                    <div class="circle-clipper right">
                        <div class="circle"></div>
                    </div>
                </div>

                <div class="spinner-layer spinner-yellow">
                    <div class="circle-clipper left">
                        <div class="circle"></div>
                    </div>
                    <div class="gap-patch">
                        <div class="circle"></div>
                    </div>
                    <div class="circle-clipper right">
                        <div class="circle"></div>
                    </div>
                </div>

                <div class="spinner-layer spinner-green">
                    <div class="circle-clipper left">
                        <div class="circle"></div>
                    </div>
                    <div class="gap-patch">
                        <div class="circle"></div>
                    </div>
                    <div class="circle-clipper right">
                        <div class="circle"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- Pre-loader end -->
    <div id="pcoded" class="pcoded">
        <div class="pcoded-overlay-box"></div>
        <div class="pcoded-container navbar-wrapper">
            <nav class="navbar header-navbar pcoded-header" style="background-color: white;">
                <div class="navbar-wrapper">
                    <div class="navbar-logo">
                        <a class="mobile-menu waves-effect waves-light" id="mobile-collapse" href="#!">
                            <i class="ti-menu" style="color: black;"></i>
                        </a>
                        <a href="dashboard.php">
                            <img class="img-fluid" src="../src/images/logo.png" alt="Theme-Logo" />
                        </a>
                    </div>

                    <div class="navbar-container container-fluid">
                        <ul class="nav-left">
                            <li>
                                <div class="sidebar_toggle"><a href="javascript:void(0)"><i class="ti-menu" style="color: black;"></i></a></div>
                            </li>
                            <li>
                                <a href="#!" onclick="javascript:toggleFullScreen()" class="waves-effect waves-light">
                                    <i class="ti-fullscreen" style="color: black;"></i>
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
            </nav>
            <!-- Logout Confirmation Modal -->
            <div class="modal fade" id="logoutModal" tabindex="-1" aria-labelledby="logoutModalLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">

                        <div class="modal-header">
                            <h5 class="modal-title" id="logoutModalLabel">Confirm Logout</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>

                        <div class="modal-body">
                            Are you sure you want to logout?
                        </div>

                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <a href="../secure/logout.php" class="btn btn-danger">Logout</a>
                        </div>

                    </div>
                </div>
            </div>
            <!-- View Profile Modal -->
            <div class="modal fade" id="viewProfileModal" tabindex="-1" role="dialog" aria-labelledby="viewProfileModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered" role="document">
                    <div class="modal-content rounded shadow">
                        <div class="modal-header border-0 pb-0">
                            <h5 class="modal-title font-weight-bold" id="viewProfileModalLabel">
                                <i class="bi bi-person-circle mr-2"></i> User Profile
                            </h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>

                        <div class="modal-body pt-1">
                            <ul class="list-group list-group-flush">
                                <li class="list-group-item">
                                    <strong>User ID:</strong>
                                    <span class="text-muted float-right" id="profileUserId"><?= "$id" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>Username:</strong>
                                    <span class="text-muted float-right" id="profileUsername"><?= "$username" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>First Name:</strong>
                                    <span class="text-muted float-right" id="profileFirstName"><?= "$firstName" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>Last Name:</strong>
                                    <span class="text-muted float-right" id="profileLastName"><?= "$lastName" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>Email:</strong>
                                    <span class="text-muted float-right" id="profileEmail"><?= "$email" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>Contact:</strong>
                                    <span class="text-muted float-right" id="profileContact"><?= "$contact" ?></span>
                                </li>
                                <li class="list-group-item">
                                    <strong>Role:</strong>
                                    <span class="text-muted float-right" id="profileRole"><?= "$role" ?></span>
                                </li>
                            </ul>
                        </div>

                        <div class="modal-footer border-0 d-flex justify-content-between">
                            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                <i class="bi bi-x-circle mr-1"></i> Close
                            </button>
                            <button type="button" class="btn btn-primary" onclick="window.location.href='edit-profile.php'">
                                <i class="bi bi-pencil-square mr-1"></i> Edit Profile
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <!-- Main Container -->
            <div class="pcoded-main-container">
                <div class="pcoded-wrapper">
                    <nav class="pcoded-navbar">
                        <div class="sidebar_toggle"><a href="#"><i class="icon-close icons"></i></a></div>
                        <div class="pcoded-inner-navbar main-menu">
                            <div class="">
                                <div class="main-menu-header">
                                    <img class="img-80 img-radius" src="../src/images/user.png" alt="User-Profile-Image">
                                    <div class="user-details">
                                        <span id="more-details"><?= "$firstName $lastName" ?><i class="fa fa-caret-down"></i></span>
                                    </div>
                                </div>
                                <div class="main-menu-content">
                                    <ul>
                                        <li class="more-details">
                                            <a href="#" class="waves-effect waves-dark" data-bs-toggle="modal" data-bs-target="#viewProfileModal"><i class="ti-user"></i>View Profile</a>
                                            <a href="#" class="waves-effect waves-dark" data-bs-toggle="modal" data-bs-target="#logoutModal" onclick="event.preventDefault();"><i class="ti-layout-sidebar-left"></i>Logout</a>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                            <div class="pcoded-navigation-label" data-i18n="nav.category.navigation">Home</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class=" ">
                                    <a href="dashboard.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-home"></i><b>D</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.dash.main">Dashboard</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                                <!-- pcoded-hasmenu makes a dropdown menu -->
                            </ul>
                            <div class="pcoded-navigation-label" data-i18n="nav.category.forms">Data Reporting &amp; Analysis</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class=" ">
                                    <a href="crime_reporting.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-shield"></i><b>D</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.dash.main">Crime Reporting</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                                <li class=" ">
                                    <a href="crime_analysis.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-pulse"></i><b>D</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.dash.main">Crime Analysis</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul>

                            <div class="pcoded-navigation-label" data-i18n="nav.category.forms">Streets &amp; Heatmaps</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class="">
                                    <a href="crime_mapping.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-map-alt"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Crime Mapping</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul>

                            <div class="pcoded-navigation-label" data-i18n="nav.category.forms">User Management</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class="active ">
                                    <a href="manage_users.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-user"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Manage Users</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul>

                            <!-- <div class="pcoded-navigation-label" data-i18n="nav.category.forms">Other Utilities</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class=" ">
                                    <a href="user_manual.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-book"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">User Manual</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                                <li class=" ">
                                    <a href="contact_us.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-info-alt"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Contact Us</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul> -->
                        </div>
                    </nav>
                    <div class="pcoded-content">
                        <!-- Page-header start -->
                        <div class="page-header">
                            <div class="page-block">
                                <div class="row align-items-center">
                                    <div class="col-md-8">
                                        <div class="page-header-title">
                                            <h5 class="m-b-10">User Management</h5>
                                            <p class="m-b-0">Manage user accounts and roles in the system.</p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                            <li class="breadcrumb-item">
                                                < href="crime_mapping.php"><i class="ti-user"></i> Manage Users</a>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="container-fluid mt-4 px-4">
                            <!-- Modals -->
                            <!-- Add User Modal -->
                            <div class="modal fade" id="addUserModal" tabindex="-1" aria-labelledby="addUserModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-centered">
                                    <div class="modal-content rounded-4 shadow-lg border-0">
                                        <div class="modal-header bg-primary text-white">
                                            <h5 class="modal-title" id="addUserModalLabel"><i class="bi bi-person-plus-fill me-2"></i> Add New User</h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <div class="modal-body p-4">
                                            <form id="user-form" action="../secure/add_user.php" method="POST">

                                                <div class="row">
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="firstName">First Name</label>
                                                            <input type="text" class="form-control" id="firstName" name="firstName" required>
                                                        </div>
                                                    </div>
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="lastName">Last Name</label>
                                                            <input type="text" class="form-control" id="lastName" name="lastName" required>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-floating mb-3">
                                                    <label for="username">Username</label>
                                                    <input type="text" class="form-control" id="username" name="username" required>
                                                </div>

                                                <div class="form-floating mb-3">
                                                    <label for="password">Password</label>
                                                    <input type="password" class="form-control" id="password" name="password" required>
                                                </div>

                                                <div class="form-floating mb-3">
                                                    <label for="email">Email</label>
                                                    <input type="email" class="form-control" id="email" name="email" required>
                                                </div>

                                                <div class="form-floating mb-3">
                                                    <label for="contact">Contact Number</label>
                                                    <input type="text" class="form-control" id="contact" name="contact" required>
                                                </div>

                                                <div class="form-floating mb-3">
                                                    <label for="role">User Role</label>
                                                    <select class="form-control" id="role" name="role" required>
                                                        <option value="">-- Select Role --</option>
                                                        <option value="admin">Admin</option>
                                                        <option value="user">User</option>
                                                    </select>
                                                </div>

                                                <!-- Modal Footer with Submit -->
                                                <div class="modal-footer d-flex justify-content-between p-3">
                                                    <button type="button" class="btn btn-outline-secondary w-100 me-2" data-bs-dismiss="modal">Close</button>
                                                    <button type="submit" class="btn btn-outline-primary w-100">Add User</button>
                                                </div>

                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Search Users Modal -->
                            <div class="modal fade" id="searchUserModal" tabindex="-1" aria-labelledby="searchUserModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-scrollable">
                                    <div class="modal-content rounded-3 mt-2">
                                        <div class="modal-header bg-success text-white">
                                            <h5 class="modal-title d-flex align-items-center" id="searchUserModalLabel">
                                                <i class="bi bi-search me-2"></i> Search Users
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body">
                                            <form id="searchUserForm" onsubmit="return false;">
                                                <div class="container-fluid">
                                                    <div class="row g-4">
                                                        <!-- User Info -->
                                                        <div class="col-md-4">
                                                            <label for="searchUserId" class="form-label">User ID</label>
                                                            <input type="text" class="form-control" id="searchUserId" name="id" placeholder="Partial or full ID">
                                                        </div>

                                                        <div class="col-md-4">
                                                            <label for="searchUsername" class="form-label">Username</label>
                                                            <input type="text" class="form-control" id="searchUsername" name="username" placeholder="Partial or full username">
                                                        </div>

                                                        <div class="col-md-4">
                                                            <label for="searchRole" class="form-label">Role</label>
                                                            <select class="form-control" id="searchRole" name="role">
                                                                <option value="">Any</option>
                                                                <option value="admin">Admin</option>
                                                                <option value="user">User</option>
                                                            </select>
                                                        </div>

                                                        <!-- Name -->
                                                        <div class="col-md-6">
                                                            <label for="searchFirstName" class="form-label">First Name</label>
                                                            <input type="text" class="form-control" id="searchFirstName" name="firstName" placeholder="Partial or full first name">
                                                        </div>

                                                        <div class="col-md-6">
                                                            <label for="searchLastName" class="form-label">Last Name</label>
                                                            <input type="text" class="form-control" id="searchLastName" name="lastName" placeholder="Partial or full last name">
                                                        </div>

                                                        <!-- Contact Info -->
                                                        <div class="col-md-6">
                                                            <label for="searchEmail" class="form-label">Email</label>
                                                            <input type="text" class="form-control" id="searchEmail" name="email" placeholder="Email address">
                                                        </div>

                                                        <div class="col-md-6">
                                                            <label for="searchContact" class="form-label">Contact Number</label>
                                                            <input type="text" class="form-control" id="searchContact" name="contact" placeholder="Phone number">
                                                        </div>
                                                    </div>
                                                </div>
                                            </form>
                                        </div>

                                        <div class="modal-footer p-3">
                                            <button type="button" class="btn btn-outline-secondary w-100 me-2" data-bs-dismiss="modal">Close</button>
                                            <button type="submit" class="btn btn-outline-success w-100" form="searchUserForm" onclick="applySearch()">Search</button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Edit User Modal -->
                            <div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-scrollable">
                                    <div class="modal-content rounded-3 mt-2">
                                        <div class="modal-header bg-primary text-white">
                                            <h5 class="modal-title d-flex align-items-center" id="editModalLabel">
                                                <i class="bi bi-pencil-square me-2"></i> Edit User
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body">
                                            <form id="editForm" onsubmit="return false;">
                                                <input type="hidden" name="id" id="editUserId">
                                                <div class="container-fluid">
                                                    <div class="row g-4">
                                                        <!-- User Information -->
                                                        <div class="col-md-6">
                                                            <label for="editUsername" class="form-label">Username</label>
                                                            <input type="text" class="form-control" id="editUsername" name="username">
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label for="editFirstName" class="form-label">First Name</label>
                                                            <input type="text" class="form-control" id="editFirstName" name="firstName">
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label for="editLastName" class="form-label">Last Name</label>
                                                            <input type="text" class="form-control" id="editLastName" name="lastName">
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label for="editEmail" class="form-label">Email</label>
                                                            <input type="email" class="form-control" id="editEmail" name="email">
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label for="editContact" class="form-label">Contact</label>
                                                            <input type="text" class="form-control" id="editContact" name="contact">
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label for="editRole" class="form-label">Role</label>
                                                            <select class="form-control" id="editRole" name="role">
                                                                <option value="">Select</option>
                                                                <option value="Admin">Admin</option>
                                                                <option value="User">User</option>
                                                            </select>
                                                        </div>
                                                    </div>
                                                </div>
                                            </form>
                                        </div>

                                        <div class="modal-footer justify-content-between">
                                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle"></i> Cancel
                                            </button>
                                            <button type="submit" form="editForm" class="btn btn-primary" onclick="submitUserEditForm()">
                                                <i class="bi bi-save"></i> Save Changes
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Remove Confirmation Modal -->
                            <div class="modal fade" id="removeModal" tabindex="-1" aria-labelledby="removeModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content rounded-3">
                                        <div class="modal-header bg-danger text-white">
                                            <h5 class="modal-title" id="removeModalLabel"><i class="bi bi-archive me-2"></i> Confirm Delete</h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <div class="modal-body">
                                            Are you sure you want to remove this user?
                                        </div>
                                        <div class="modal-footer justify-content-between">
                                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle"></i> Cancel
                                            </button>
                                            <button type="button" class="btn btn-danger" id="confirmRemoveBtn">
                                                <i class="bi bi-archive"></i> Remove
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Card Container -->
                            <div class="card shadow border-0 rounded">
                                <div class="card-body">
                                    <!-- Table Container -->
                                    <div class="table-responsive shadow-sm rounded bg-white p-3">
                                        <!-- Pagination Controls -->
                                        <nav>
                                            <ul class="pagination justify-content-center" id="pagination"></ul>
                                        </nav>
                                        <!-- Toolbar -->
                                        <div class="d-flex flex-wrap mb-3">
                                            <div class="mr-2 mb-2">
                                                <button class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addUserModal">
                                                    <i class="bi bi-plus-circle mr-1"></i> Add New
                                                </button>
                                            </div>
                                            <div class="mb-2">
                                                <button class="btn btn-outline-success btn-sm" data-bs-toggle="modal" data-bs-target="#searchUserModal">
                                                    <i class="bi bi-search mr-1"></i> Search Users
                                                </button>
                                            </div>
                                        </div>
                                        <table class="table table-card table-hover table-columned table-condensed">
                                            <div class="export-buttons mb-2">
                                                <button id="exportUsersCsv" class="btn btn-outline-warning btn-sm">
                                                    <i class="bi bi-file-earmark-spreadsheet me-1"></i>Export Users to CSV
                                                </button>
                                                <button id="exportUsersPdf" class="btn btn-outline-danger btn-sm">
                                                    <i class="bi bi-file-earmark-pdf me-1"></i>Export Users to PDF
                                                </button>
                                            </div>
                                            <thead class="thead-light">
                                                <tr>
                                                    <th colspan="100%" class="h5 text-primary">👥 User Accounts</th>
                                                </tr>
                                                <tr>
                                                    <th scope="col" class="text-center">Actions</th>
                                                    <?php
                                                    $query = "SHOW COLUMNS FROM `accounts`";
                                                    $result = mysqli_query($conn, $query);
                                                    $columns = [];
                                                    while ($column = mysqli_fetch_assoc($result)) {
                                                        $columns[] = $column['Field'];
                                                        if ($column['Field'] !== 'password') { // Skip password field
                                                            echo "<th scope='col' class='text-nowrap'>" . htmlspecialchars($column['Field']) . "</th>";
                                                        }
                                                    }
                                                    ?>
                                                </tr>
                                            </thead>
                                            <tbody id="dynamicUserTable">
                                                <?php
                                                $query = "SELECT * FROM `accounts`";
                                                $result = mysqli_query($conn, $query);

                                                while ($row = mysqli_fetch_assoc($result)) {
                                                    $userId = $row['id'];
                                                    echo "<tr data-id='$userId'>";

                                                    echo "<td>
                                                    <button class='btn btn-sm btn-outline-info transition-hover w-100 mb-2' onclick='startEdit(this)'>
                                                    <i class='bi bi-pencil-square'></i> Edit
                                                    </button>
                                                    <br>
                                                    <button class='btn btn-sm btn-outline-danger transition-hover w-100' onclick='removeUser(" . json_encode($userId) . ")'>
                                                    <i class='bi bi-trash'></i> Delete
                                                    </button>
                                                    </td>";

                                                    foreach ($columns as $col) {
                                                        if ($col !== 'password') {
                                                            echo "<td class='text-wrap wrap-limit' data-id='$userId' data-field='$col'>" . htmlspecialchars($row[$col]) . "</td>";
                                                        }
                                                    }

                                                    echo "</tr>";
                                                }
                                                ?>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <?php if ($loginSuccess): ?>
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    const notyf = new Notyf({
                        duration: 4000,
                        position: {
                            x: 'center',
                            y: 'top',
                        },
                        types: [{
                            type: 'success',
                            background: '#28a745',
                            icon: {
                                className: 'material-icons',
                                tagName: 'i',
                                text: 'check_circle'
                            }
                        }]
                    });

                    notyf.open({
                        type: 'success',
                        message: 'Welcome back <?= "$role $firstName" ?>! You are now logged in.'
                    });
                });
            </script>
        <?php endif; ?>
        <?php if ($dataAdded): ?>
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    const notyf = new Notyf({
                        duration: 4000,
                        position: {
                            x: 'center',
                            y: 'top',
                        },
                        types: [{
                            type: 'success',
                            background: '#28a745',
                            icon: {
                                className: 'material-icons',
                                tagName: 'i',
                                text: 'check_circle'
                            }
                        }]
                    });

                    notyf.open({
                        type: 'success',
                        message: 'Successfully Added a User!'
                    });
                });
                <?php $_SESSION['Success'] = false; ?>
            </script>
        <?php endif; ?>

        <script>
            const searchModal = document.getElementById('searchUserModal');
            searchModal.addEventListener('hidden.bs.modal', () => {
                document.getElementById('searchUserForm').reset();
            });

            // GLOBAL PAGINATION SETTINGS
            const rowsPerPage = 5;
            let currentPage = 1;

            function applySearch() {
                const formData = new FormData(document.getElementById('searchUserForm'));
                const params = new URLSearchParams(formData).toString();

                fetch(`../secure/search_users.php?${params}`)
                    .then(res => res.json())
                    .then(data => {
                        const table = document.getElementById('dynamicUserTable');
                        table.innerHTML = ''; // Clear table

                        if (data.length === 0) {
                            table.innerHTML = '<tr><td colspan="100%" class="text-center text-muted">No results found.</td></tr>';
                            document.getElementById('pagination').innerHTML = '';
                            return;
                        }

                        <?php
                        $query = "SHOW COLUMNS FROM `accounts`";
                        $result = mysqli_query($conn, $query);
                        $clientCols = [];
                        while ($col = mysqli_fetch_assoc($result)) {
                            $clientCols[] = $col['Field'];
                        }
                        echo "const columns = " . json_encode($clientCols) . ";";
                        ?>

                        data.forEach(row => {
                            const tr = document.createElement('tr');
                            tr.dataset.id = row.id;

                            // Actions: Edit and Delete buttons
                            const actions = document.createElement('td');
                            actions.innerHTML = `
                    <button class="btn btn-sm btn-outline-info w-100 mb-2" onclick="startEdit(this)">
                    <i class="bi bi-pencil-square"></i> Edit
                    </button><br>
                    <button class="btn btn-sm btn-outline-danger w-100" onclick="removeUser(${row.id})">
                    <i class="bi bi-trash"></i> Delete
                    </button>
                    `;
                            tr.appendChild(actions);

                            columns.forEach(col => {
                                if (col !== 'password') { // Never display the password
                                    const td = document.createElement('td');
                                    td.className = 'text-wrap wrap-limit';
                                    td.dataset.id = row.id;
                                    td.dataset.field = col;
                                    td.textContent = row[col] ?? '';
                                    tr.appendChild(td);
                                }
                            });

                            table.appendChild(tr);
                        });

                        currentPage = 1;
                        paginateTable(); // Rerun pagination after sorting
                    })
                    .catch(err => alert(`Search failed: ${err}`));
            }

            function paginateTable() {
                const table = document.getElementById('dynamicUserTable');
                const rows = Array.from(table.querySelectorAll('tr'));
                const pagination = document.getElementById('pagination');
                const totalPages = Math.ceil(rows.length / rowsPerPage);

                function renderTable(page) {
                    const start = (page - 1) * rowsPerPage;
                    const end = start + rowsPerPage;
                    rows.forEach((row, i) => {
                        row.style.display = (i >= start && i < end) ? '' : 'none';
                    });
                }

                function renderPagination() {
                    pagination.innerHTML = '';
                    const createPageItem = (text, page, disabled = false, active = false) => {
                        const li = document.createElement('li');
                        li.className = `page-item ${disabled ? 'disabled' : ''} ${active ? 'active' : ''}`;
                        const a = document.createElement('a');
                        a.className = 'page-link';
                        a.href = '#';
                        a.textContent = text;
                        a.addEventListener('click', e => {
                            e.preventDefault();
                            if (!disabled && currentPage !== page) {
                                currentPage = page;
                                renderTable(currentPage);
                                renderPagination();
                            }
                        });
                        li.appendChild(a);
                        return li;
                    };

                    pagination.appendChild(createPageItem('«', currentPage - 1, currentPage === 1));
                    for (let i = 1; i <= totalPages; i++) {
                        pagination.appendChild(createPageItem(i, i, false, currentPage === i));
                    }
                    pagination.appendChild(createPageItem('»', currentPage + 1, currentPage === totalPages));
                }

                renderTable(currentPage);
                renderPagination();
            }
            // Run pagination once on initial page load
            document.addEventListener('DOMContentLoaded', paginateTable);
        </script>

        <script>
            function submitUserEditForm() {
                const form = document.getElementById('editForm');
                const formData = new FormData(form);

                fetch('../secure/update_user.php', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            $('#editModal').modal('hide'); // Hide the modal
                            location.reload(); // Or update the table dynamically
                        } else {
                            alert('Failed to update user.'); // Customize error message if needed
                        }
                        location.reload();
                    })
                    .catch(error => {
                        console.error('Update error:', error);
                    });
            }

            function startEdit(button) {
                const row = button.closest('tr');
                if (!row) return;

                const userId = row.dataset.id;

                // Populate modal fields from table cells
                row.querySelectorAll('td[data-field]').forEach(td => {
                    const field = td.dataset.field;
                    const value = td.textContent.trim();

                    // Select input/select/textarea inside the modal
                    const input = document.querySelector(`#editModal [name="${field}"]`);
                    if (input) {
                        if (input.tagName === 'SELECT') {
                            // For select fields, select the corresponding option
                            Array.from(input.options).forEach(option => {
                                option.selected = option.value === value;
                            });
                        } else {
                            // For text inputs, set the value
                            input.value = value;
                        }
                    }
                });

                const modalEl = document.getElementById('editModal');
                if (modalEl) {
                    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
                    modal.show();
                }

                // Set the userId in the hidden input for form submission
                const userIdInput = document.querySelector('#editModal [name="id"]');
                if (userIdInput) {
                    userIdInput.value = userId;
                }
            }
        </script>

    </div>

    <!-- EXPORT LOGIC -->
    <!-- Include jsPDF and autoTable Library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.18/jspdf.plugin.autotable.js"></script>


    <script>
        // CSV Export for Incident Reports
        document.getElementById("exportUsersCsv").addEventListener("click", () => {
            const rows = document.querySelectorAll("#dynamicUserTable tr");
            if (!rows.length) return;

            let csvContent = "";

            // Extract headers (excluding first column)
            const headers = Array.from(document.querySelectorAll("thead tr:nth-child(2) th"))
                .slice(1)
                .map(th => `"${th.textContent.trim()}"`)
                .join(",");
            csvContent += headers + "\n";

            // Extract rows (excluding first column)
            rows.forEach(row => {
                const cells = Array.from(row.querySelectorAll("td")).slice(1); // Skip Actions
                const rowData = cells.map(cell => `"${cell.textContent.trim().replace(/\n/g, ' ')}"`).join(",");
                csvContent += rowData + "\n";
            });

            // Create CSV file
            const blob = new Blob([csvContent], {
                type: "text/csv;charset=utf-8;"
            });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "user_accounts.csv";
            link.click();
        });

        // PDF Export for Incident Reports
        document.getElementById("exportUsersPdf").addEventListener("click", () => {
            const {
                jsPDF
            } = window.jspdf;
            const doc = new jsPDF("l", "pt", "a4"); // Landscape orientation for better table fit

            const headers = Array.from(document.querySelectorAll("thead tr:nth-child(2) th"))
                .slice(1) // Skip 'Actions' column
                .map(th => th.textContent.trim());

            const rows = Array.from(document.querySelectorAll("#dynamicUserTable tr")).map(tr =>
                Array.from(tr.querySelectorAll("td"))
                .slice(1) // Skip 'Actions' column
                .map(td => td.textContent.trim().replace(/\s+/g, " "))
            );

            // Use autoTable with optimized layout for many columns (15+)
            doc.autoTable({
                head: [headers],
                body: rows,
                startY: 40,
                margin: {
                    left: 20,
                    right: 20
                },
                theme: 'grid',
                headStyles: {
                    fillColor: [22, 160, 133],
                    textColor: 255,
                    halign: 'center',
                    fontSize: 9,
                    fontStyle: 'bold'
                },
                bodyStyles: {
                    fontSize: 7, // Smaller font for better fit
                    cellPadding: 2, // Slightly reduced padding
                    valign: 'top'
                },
                styles: {
                    overflow: 'linebreak',
                    cellWidth: 'wrap', // Let cells wrap content
                    minCellHeight: 10,
                    halign: 'left'
                },
                columnStyles: {
                    // Assign narrow but equal widths to fit more columns
                    // Adjust width based on column count and available space
                    ...Array.from({
                        length: headers.length
                    }).reduce((cols, _, i) => {
                        cols[i] = {
                            cellWidth: 80
                        }; // ~15 columns at 60px each + margins fits A4 landscape
                        return cols;
                    }, {})
                },
                didDrawPage: function(data) {
                    doc.setFontSize(22);
                    doc.setTextColor(40);
                    doc.text(" User Accounts", data.settings.margin.left, 25);
                }
            });

            doc.save("user_report.pdf");
        });
    </script>
    <!-- Warning Section Starts -->
    <!-- Older IE warning message -->
    <!--[if lt IE 10]>
<div class="ie-warning">
    <h1>Warning!!</h1>
    <p>You are using an outdated version of Internet Explorer, please upgrade <br/>to any of the following web browsers
        to access this website.</p>
    <div class="iew-container">
        <ul class="iew-download">
            <li>
                <a href="http://www.google.com/chrome/">
                    <img src="assets/images/browser/chrome.png" alt="Chrome">
                    <div>Chrome</div>
                </a>
            </li>
            <li>
                <a href="https://www.mozilla.org/en-US/firefox/new/">
                    <img src="assets/images/browser/firefox.png" alt="Firefox">
                    <div>Firefox</div>
                </a>
            </li>
            <li>
                <a href="http://www.opera.com">
                    <img src="assets/images/browser/opera.png" alt="Opera">
                    <div>Opera</div>
                </a>
            </li>
            <li>
                <a href="https://www.apple.com/safari/">
                    <img src="assets/images/browser/safari.png" alt="Safari">
                    <div>Safari</div>
                </a>
            </li>
            <li>
                <a href="http://windows.microsoft.com/en-us/internet-explorer/download-ie">
                    <img src="assets/images/browser/ie.png" alt="">
                    <div>IE (9 & above)</div>
                </a>
            </li>
        </ul>
    </div>
    <p>Sorry for the inconvenience!</p>
</div>
<![endif]-->
    <!-- Warning Section Ends -->

    <script>
        function submitEditForm() {
            // Collect form data
            var formData = new FormData(document.getElementById('editForm'));

            // Send AJAX request to the server
            fetch('../secure/update_user.php', { // Updated URL for user update
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // If the update is successful, close the modal and refresh the page (or update the table)
                        $('#editModal').modal('hide');
                        location.reload(); // Refresh page or you can use a more targeted update for the table
                    } else {
                        // Handle error
                        alert('Error saving changes.');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                });
        }
    </script>

    <script>
        let userToRemove = null;

        function removeUser(userId) {
            userToRemove = userId;

            const modalBody = document.querySelector('#removeModal .modal-body');
            const modalTitle = document.getElementById('removeModalLabel');
            const confirmBtn = document.getElementById('confirmRemoveBtn');

            modalTitle.innerHTML = '<i class="bi bi-trash me-2"></i> Confirm Remove';
            modalBody.textContent = 'Are you sure you want to remove this user?';
            confirmBtn.classList.add('btn-danger');
            confirmBtn.innerHTML = '<i class="bi bi-trash"></i> Remove';

            const modal = new bootstrap.Modal(document.getElementById('removeModal'));
            modal.show();
        }

        document.getElementById('confirmRemoveBtn').addEventListener('click', () => {
            if (userToRemove !== null) {
                fetch('../secure/remove_user.php', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            id: userToRemove
                        })
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (data.success) {
                            const row = document.querySelector(`tr[data-id="${userToRemove}"]`);
                            if (row) {
                                row.remove(); // Remove the user row from the table
                            }
                        } else {
                            alert('Action failed. Please try again.');
                        }
                        bootstrap.Modal.getInstance(document.getElementById('removeModal')).hide();
                        userToRemove = null;
                    })
                    .catch(err => {
                        console.error(err);
                        alert('Error processing request.');
                    });
            }
        });
    </script>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
            // Fetch the table and its rows
            const table = document.getElementById("dynamicUserTable");
            const rows = Array.from(table.querySelectorAll("tr"));

            // Sort rows: First by Status (Active first, Archived last)
            const sortedRows = rows.sort((a, b) => {
                const statusA = a.getAttribute('data-status');
                const statusB = b.getAttribute('data-status');

                // Active comes first, Archived last
                if (statusA === "active" && statusB !== "active") {
                    return -1; // Active should be placed before Archived
                } else if (statusA !== "active" && statusB === "active") {
                    return 1; // Archived should be placed after Active
                }

                // If both are the same status, you can sort by date or incident_id (or any other field)
                const dateA = new Date(a.querySelector('[data-field="Date"]').textContent);
                const dateB = new Date(b.querySelector('[data-field="Date"]').textContent);
                return dateB - dateA; // Sort by Date in descending order (latest first)
            });

            // Re-append sorted rows back to the table body
            sortedRows.forEach(row => {
                table.appendChild(row);
            });

            // Optional: Rerun pagination if required
            currentPage = 1;
            paginateTable();
        });
    </script>

    <!-- Required Jquery -->
    <script type="text/javascript" src="assets/js/jquery/jquery.min.js"></script>
    <script type="text/javascript" src="assets/js/jquery-ui/jquery-ui.min.js "></script>
    <script type="text/javascript" src="assets/js/popper.js/popper.min.js"></script>
    <script type="text/javascript" src="assets/js/bootstrap/js/bootstrap.min.js "></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <!-- waves js -->
    <script src="assets/pages/waves/js/waves.min.js"></script>
    <!-- jquery slimscroll js -->
    <script type="text/javascript" src="assets/js/jquery-slimscroll/jquery.slimscroll.js "></script>
    <!-- modernizr js -->
    <script type="text/javascript" src="assets/js/SmoothScroll.js"></script>
    <script src="assets/js/jquery.mCustomScrollbar.concat.min.js "></script>
    <script src="assets/js/pcoded.min.js"></script>
    <script src="assets/js/vertical-layout.min.js "></script>
    <script src="assets/js/jquery.mCustomScrollbar.concat.min.js"></script>
    <!-- Custom js -->
    <script type="text/javascript" src="assets/js/script.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="../secure/apis/leaflet/leaflet.js" crossorigin=""></script>
    <script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>
    <script src="https://unpkg.com/@turf/turf@6.5.0/turf.min.js"></script>
    <!-- Script Dependencies -->
    <script src="../javascript/crime_data/map.js"></script>
    <script src="../javascript/crime_data/map-controls.js"></script>
    <script src="../javascript/crime_data/street-layer.js"></script>

    <!-- At the bottom of your page before </body> -->
    <script>
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'))
        tooltipTriggerList.forEach(function(el) {
            new bootstrap.Tooltip(el)
        });
    </script>

</body>

</html>