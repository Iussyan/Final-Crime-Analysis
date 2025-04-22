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
    <title>Crime Reporting</title>
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
                                <li class="active ">
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
                                <li class=" ">
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
                                            <h5 class="m-b-10">Crime Reporting</h5>
                                            <p class="m-b-0">Report crime across the barangay by selecting a location and filling out the form</p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                            <li class="breadcrumb-item">
                                                <a href="crime_mapping.php"><i class="ti-shield"></i> Crime Reporting</a>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="container-fluid mt-4 px-4">
                            <!-- Modals -->
                            <!-- Add Crime Data Modal -->
                            <div class="modal fade" id="addCrimeDataModal" tabindex="-1" aria-labelledby="addCrimeDataModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-centered">
                                    <div class="modal-content rounded-4 shadow-lg border-0">
                                        <div class="modal-header bg-primary text-white">
                                            <h5 class="modal-title" id="addCrimeDataModalLabel"><i class="bi bi-plus-circle mr-1"></i> Add New Crime Data</h5>
                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <div class="modal-body p-4">
                                            <form id="crime-form" action="../secure/add_crime_data.php" method="POST">
                                                <!-- Street Map Toggle with Icon -->
                                                <div class="mb-3">
                                                    <button type="button" class="btn btn-outline-info w-100 d-flex align-items-center" id="toggleMapBtn">
                                                        📍 Select a Street
                                                    </button>
                                                    <div id="map-container" class="mb-4" style="display: none; height: 300px; border-radius: 12px; overflow: hidden;">
                                                        <div id="map" style="width: 100%; height: 100%;"></div>
                                                    </div>
                                                    <p class="mt-2"><strong>Selected Street:</strong> <span id="selected-street-name">None</span></p>
                                                    <p><strong>Selected Street's ID:</strong> <span id="selected-street-id">None</span></p>
                                                </div>

                                                <!-- Hidden input fields for submission -->
                                                <input type="hidden" id="selectedStreetName" name="selectedStreetName">
                                                <input type="hidden" id="selectedStreetId" name="selectedStreetId">
                                                <input type="hidden" id="crimeLocation" name="crimeLocation">

                                                <!-- Category Dropdown -->
                                                <div class="form-floating mb-3">
                                                    <label for="category" class="float-label">Crime Category</label>
                                                    <select class="form-control" id="cCategory" name="category" required>
                                                        <option value="">-- Select Category --</option>
                                                        <option value="Violence">Violence</option>
                                                        <option value="Theft">Theft</option>
                                                        <option value="Vandalism">Vandalism</option>
                                                        <option value="Drug Activity">Drug Activity</option>
                                                        <option value="Traffic">Traffic Offense</option>
                                                        <option value="Disturbance">Disturbance</option>
                                                        <option value="Suspicious">Suspicious Activity</option>
                                                        <option value="Environmental">Environmental Issue</option>
                                                        <option value="Domestic Dispute">Domestic Disturbance</option>
                                                    </select>
                                                </div>

                                                <!-- Crime Type Dropdown -->
                                                <div class="form-floating mb-3">
                                                    <label for="crime" class="float-label">Crime Type</label>
                                                    <select class="form-control" id="cCrime" name="crime" required disabled>
                                                        <option value="">-- Select a Crime --</option>
                                                    </select>
                                                    <span id="crime-error" class="text-danger" style="display:none;">Please select a valid crime type.</span>
                                                </div>

                                                <!-- Address -->
                                                <div class="form-floating mb-3">
                                                    <label for="address" class="float-label">Address</label>
                                                    <input type="text" class="form-control" id="address" name="address" required>
                                                </div>

                                                <!-- Date and Time -->
                                                <div class="row">
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="date" class="float-label">Date</label>
                                                            <input type="date" class="form-control" id="date" name="date" max="<?= date('Y-m-d') ?>" required>
                                                        </div>
                                                    </div>
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="time" class="float-label">Time</label>
                                                            <input type="time" class="form-control" id="time" name="time" required>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Crime Description -->
                                                <div class="form-floating mb-3">
                                                    <label for="description" class="float-label">Crime Description</label>
                                                    <textarea class="form-control" id="description" name="description" required></textarea>
                                                </div>

                                                <!-- Witness Information -->
                                                <div class="row">
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="witness_name" class="float-label">Witness' Name</label>
                                                            <input type="text" class="form-control" id="witness_name" name="witness_name" required>
                                                        </div>
                                                    </div>
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="witness_age" class="float-label">Witness' Age</label>
                                                            <input type="number" class="form-control" id="witness_age" name="witness_age" required>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="row">
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="witness_sex" class="float-label">Witness' Sex</label>
                                                            <select class="form-control" id="witness_sex" name="witness_sex" required>
                                                                <option value="Male">Male</option>
                                                                <option value="Female">Female</option>
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="col-md-6 mb-3">
                                                        <div class="form-floating">
                                                            <label for="contact_number" class="float-label">(Optional) Contact Number</label>
                                                            <input type="text" class="form-control" id="contact_number" name="contact_number">
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Modal Footer with Submit -->
                                                <div class="modal-footer d-flex justify-content-between p-3">
                                                    <button type="button" class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Close</button>
                                                    <button type="submit" class="btn btn-outline-primary w-100">Submit</button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Search Modal -->
                            <div class="modal fade" id="searchModal" tabindex="-1" aria-labelledby="searchModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-scrollable">
                                    <div class="modal-content rounded-3 mt-2">
                                        <div class="modal-header bg-success text-white">
                                            <h5 class="modal-title d-flex align-items-center" id="searchModalLabel">
                                                <i class="bi bi-search mr-1"></i> Search Incident Reports
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body">
                                            <form id="searchForm" onsubmit="return false;">
                                                <div class="container-fluid">
                                                    <div class="row g-4">

                                                        <!-- Row 1: Incident Info -->
                                                        <div class="col-md-3">
                                                            <label for="incidentId" class="form-label">Incident ID</label>
                                                            <input type="text" class="form-control" id="incidentId" name="incident_id" placeholder="Partial or full ID">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="category" class="float-label">Crime Category</label>
                                                            <select class="form-control" id="category" name="category">
                                                                <option value="">-- Select Category --</option>
                                                                <option value="Violence">Violence</option>
                                                                <option value="Theft">Theft</option>
                                                                <option value="Vandalism">Vandalism</option>
                                                                <option value="Drug Activity">Drug Activity</option>
                                                                <option value="Traffic">Traffic Offense</option>
                                                                <option value="Disturbance">Disturbance</option>
                                                                <option value="Suspicious">Suspicious Activity</option>
                                                                <option value="Environmental">Environmental Issue</option>
                                                                <option value="Domestic Dispute">Domestic Disturbance</option>
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="crime" class="float-label">Crime Type</label>
                                                            <select class="form-control" id="crime" name="crime_type" disabled>
                                                                <option value="">-- Select a Crime --</option>
                                                            </select>
                                                            <span id="crime-error" class="text-danger" style="display:none;">Please select a valid crime type.</span>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="crimeDesc" class="form-label">Crime Description</label>
                                                            <input type="text" class="form-control" id="crimeDesc" name="crime_description" placeholder="Optional keywords">
                                                        </div>

                                                        <!-- Row 2: Date & Time -->
                                                        <div class="col-md-3">
                                                            <label for="incidentDate" class="form-label" max="<?= date('Y-m-d') ?>">Date</label>
                                                            <input type="date" class="form-control" id="incidentDate" name="date">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="incidentTime" class="form-label">Time</label>
                                                            <input type="time" class="form-control" id="incidentTime" name="time">
                                                        </div>

                                                        <!-- Row 3: Location Info -->
                                                        <div class="col-md-3">
                                                            <label for="address" class="form-label">Address</label>
                                                            <input type="text" class="form-control" id="address" name="address" placeholder="Full or partial address">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="streetName" class="form-label">Street Name</label>
                                                            <input type="text" class="form-control" id="streetName" name="street_name" placeholder="Street only">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="highway" class="form-label">Highway</label>
                                                            <input type="text" class="form-control" id="highway" name="highway">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="oneway" class="form-label">Oneway</label>
                                                            <select class="form-control" id="oneway" name="oneway">
                                                                <option value="">Any</option>
                                                                <option value="Yes">Yes</option>
                                                                <option value="No">No</option>
                                                            </select>
                                                        </div>

                                                        <!-- Row 4: Witness Info -->
                                                        <div class="col-md-3">
                                                            <label for="witnessName" class="form-label">Witness Name</label>
                                                            <input type="text" class="form-control" id="witnessName" name="witness_name" placeholder="Full name or partial">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="witnessAge" class="form-label">Witness Age</label>
                                                            <input type="number" class="form-control" id="witnessAge" name="witness_age" min="0">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="witnessSex" class="form-label">Witness Sex</label>
                                                            <select class="form-control" id="witnessSex" name="witness_sex">
                                                                <option value="">Any</option>
                                                                <option value="Male">Male</option>
                                                                <option value="Female">Female</option>
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="contactNumber" class="form-label">Contact Number</label>
                                                            <input type="text" class="form-control" id="contactNumber" name="contact_number" placeholder="e.g. 09123456789">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editStatus" class="form-label">Status</label>
                                                            <select class="form-control" id="editStatus" name="Status">
                                                                <option value="">Select</option>
                                                                <option value="Active">Active</option>
                                                                <option value="Archived">Archived</option>
                                                            </select>
                                                        </div>

                                                    </div>
                                                </div>
                                            </form>
                                        </div>

                                        <div class="modal-footer justify-content-between">
                                            <button type="reset" form="searchForm" class="btn btn-secondary">
                                                <i class="bi bi-x-circle"></i> Clear All
                                            </button>
                                            <button type="submit" form="searchForm" class="btn btn-success" onclick="applySearch()">
                                                <i class="bi bi-search"></i> Apply Filters
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Edit Modal -->
                            <div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-lg modal-dialog-scrollable">
                                    <div class="modal-content rounded-3 mt-2">
                                        <div class="modal-header bg-primary text-white">
                                            <h5 class="modal-title d-flex align-items-center" id="editModalLabel">
                                                <i class="bi bi-pencil-square me-2"></i> Edit Incident Report
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body">
                                            <form id="editForm" onsubmit="return false;">
                                                <input type="hidden" name="Incident_ID" id="editIncidentId">
                                                <div class="container-fluid">
                                                    <div class="row g-4">

                                                        <!-- Row 1: Incident Info -->
                                                        <div class="col-md-3">
                                                            <label for="editCategory" class="form-label">Crime Category</label>
                                                            <select class="form-control" id="editCategory" name="Category">
                                                                <option value="">-- Select Category --</option>
                                                                <option value="Violence">Violence</option>
                                                                <option value="Theft">Theft</option>
                                                                <option value="Vandalism">Vandalism</option>
                                                                <option value="Drug Activity">Drug Activity</option>
                                                                <option value="Traffic">Traffic Offense</option>
                                                                <option value="Disturbance">Disturbance</option>
                                                                <option value="Suspicious">Suspicious Activity</option>
                                                                <option value="Environmental">Environmental Issue</option>
                                                                <option value="Domestic Dispute">Domestic Disturbance</option>
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editCrime" class="form-label">Crime Type</label>
                                                            <select class="form-control" id="editCrime" name="Crime_Type">
                                                                <option value="">-- Select a Crime --</option>
                                                                <!-- Theft -->
                                                                <option value="Pickpocketing">Pickpocketing</option>
                                                                <option value="Bag Snatching">Bag Snatching</option>
                                                                <option value="Bike Theft">Bike Theft</option>
                                                                <option value="Car Theft">Car Theft</option>
                                                                <option value="Car Break-in">Car Break-in</option>
                                                                <option value="Tool Theft">Tool Theft</option>
                                                                <option value="ATM Theft">ATM Theft</option>
                                                                <option value="Shoplifting">Shoplifting</option>
                                                                <option value="Home Burglary">Home Burglary</option>
                                                                <option value="Gas Siphoning">Gas Siphoning</option>

                                                                <!-- Violence -->
                                                                <option value="Street Fight">Street Fight</option>
                                                                <option value="Mugging">Mugging</option>
                                                                <option value="Assault">Assault</option>
                                                                <option value="Group Brawl">Group Brawl</option>
                                                                <option value="Verbal Threats">Verbal Threats</option>
                                                                <option value="Weapon Display">Weapon Display</option>
                                                                <option value="Domestic Assault">Domestic Assault</option>
                                                                <option value="Sexual Assault">Sexual Assault</option>
                                                                <option value="Robbery with Violence">Robbery with Violence</option>
                                                                <option value="Armed Confrontation">Armed Confrontation</option>

                                                                <!-- Vandalism -->
                                                                <option value="Graffiti">Graffiti</option>
                                                                <option value="Broken Streetlight">Broken Streetlight</option>
                                                                <option value="Damaged Road Sign">Damaged Road Sign</option>
                                                                <option value="Shattered Window">Shattered Window</option>
                                                                <option value="Fence Damage">Fence Damage</option>
                                                                <option value="Public Property Damage">Public Property Damage</option>
                                                                <option value="Spray Painting Private Property">Spray Painting Private Property</option>
                                                                <option value="Slashed Tires">Slashed Tires</option>
                                                                <option value="Damaged Bus Stop">Damaged Bus Stop</option>
                                                                <option value="Vandalized Playground Equipment">Vandalized Playground Equipment</option>

                                                                <!-- Drug Activity -->
                                                                <option value="Public Drug Use">Public Drug Use</option>
                                                                <option value="Drug Transaction">Drug Transaction</option>
                                                                <option value="Drug Paraphernalia Found">Drug Paraphernalia Found</option>
                                                                <option value="Suspected Drug House">Suspected Drug House</option>
                                                                <option value="Needles Found in Public Area">Needles Found in Public Area</option>
                                                                <option value="Odor of Drugs">Odor of Drugs</option>
                                                                <option value="Drug Dealing Near School">Drug Dealing Near School</option>
                                                                <option value="Overdose Incident">Overdose Incident</option>

                                                                <!-- Traffic -->
                                                                <option value="Reckless Driving">Reckless Driving</option>
                                                                <option value="Hit and Run">Hit and Run</option>
                                                                <option value="Illegal Parking">Illegal Parking</option>
                                                                <option value="Blocking Driveway">Blocking Driveway</option>
                                                                <option value="Street Racing">Street Racing</option>
                                                                <option value="Wrong Way Driving">Wrong Way Driving</option>
                                                                <option value="Running Red Light">Running Red Light</option>
                                                                <option value="Speeding in Residential Area">Speeding in Residential Area</option>
                                                                <option value="Driving Without Headlights">Driving Without Headlights</option>
                                                                <option value="Failure to Yield">Failure to Yield</option>

                                                                <!-- Disturbance -->
                                                                <option value="Noise Complaint">Noise Complaint</option>
                                                                <option value="Public Intoxication">Public Intoxication</option>
                                                                <option value="Loitering">Loitering</option>
                                                                <option value="Street Harassment">Street Harassment</option>
                                                                <option value="Fireworks in Street">Fireworks in Street</option>
                                                                <option value="Unruly Crowd">Unruly Crowd</option>
                                                                <option value="Blocking Pedestrian Path">Blocking Pedestrian Path</option>
                                                                <option value="Disorderly Conduct">Disorderly Conduct</option>
                                                                <option value="Shouting Matches">Shouting Matches</option>
                                                                <option value="Rowdy Behavior at Night">Rowdy Behavior at Night</option>

                                                                <!-- Suspicious -->
                                                                <option value="Suspicious Person">Suspicious Person</option>
                                                                <option value="Suspicious Vehicle">Suspicious Vehicle</option>
                                                                <option value="Unattended Package">Unattended Package</option>
                                                                <option value="Unknown Person Peering into Cars">Unknown Person Peering into Cars</option>
                                                                <option value="Person Hiding Behind Bushes">Person Hiding Behind Bushes</option>
                                                                <option value="Repeated Door Knocking">Repeated Door Knocking</option>
                                                                <option value="Drone Hovering at Night">Drone Hovering at Night</option>
                                                                <option value="Person with Binoculars">Person with Binoculars</option>

                                                                <!-- Environmental -->
                                                                <option value="Illegal Dumping">Illegal Dumping</option>
                                                                <option value="Littering">Littering</option>
                                                                <option value="Open Manhole">Open Manhole</option>
                                                                <option value="Flooded Street">Flooded Street</option>
                                                                <option value="Downed Power Line">Downed Power Line</option>
                                                                <option value="Dead Animal in Street">Dead Animal in Street</option>
                                                                <option value="Blocked Storm Drain">Blocked Storm Drain</option>
                                                                <option value="Overflowing Trash Can">Overflowing Trash Can</option>
                                                                <option value="Leaking Fire Hydrant">Leaking Fire Hydrant</option>
                                                                <option value="Hazardous Waste Found">Hazardous Waste Found</option>

                                                                <!-- Domestic Dispute -->
                                                                <option value="Yelling Heard from House">Yelling Heard from House</option>
                                                                <option value="Fight in Front Yard">Fight in Front Yard</option>
                                                                <option value="Ongoing Argument in Street">Ongoing Argument in Street</option>
                                                                <option value="Throwing Objects Outside Home">Throwing Objects Outside Home</option>
                                                                <option value="Loud Screaming Indoors">Loud Screaming Indoors</option>
                                                                <option value="Police Called to Residence">Police Called to Residence</option>
                                                                <option value="Suspected Child Abuse">Suspected Child Abuse</option>
                                                                <option value="Verbal Abuse in Public">Verbal Abuse in Public</option>
                                                                <!-- Dynamically populated -->
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editCrimeDesc" class="form-label">Crime Description</label>
                                                            <textarea type="text" class="form-control" id="editCrimeDesc" name="Crime_Description"></textarea>
                                                        </div>

                                                        <!-- Row 2: Date & Time -->
                                                        <div class="col-md-3">
                                                            <label for="editDate" class="form-label" max="<?= date('Y-m-d') ?>">Date</label>
                                                            <input type="date" class="form-control" id="editDate" name="Date">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editTime" class="form-label">Time</label>
                                                            <input type="time" class="form-control" id="editTime" name="Time">
                                                        </div>

                                                        <!-- Row 3: Location -->
                                                        <div class="col-md-3">
                                                            <label for="editAddress" class="form-label">Address</label>
                                                            <input type="text" class="form-control" id="editAddress" name="Address">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editStreet" class="form-label">Street Name</label>
                                                            <input type="text" class="form-control" id="editStreet" name="Street_Name">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editHighway" class="form-label">Highway</label>
                                                            <input type="text" class="form-control" id="editHighway" name="Highway">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editOneway" class="form-label">Oneway</label>
                                                            <select class="form-control" id="editOneway" name="Oneway">
                                                                <option value="">Select</option>
                                                                <option value="yes">Yes</option>
                                                                <option value="no">No</option>
                                                            </select>
                                                        </div>

                                                        <!-- Row 4: Witness -->
                                                        <div class="col-md-3">
                                                            <label for="editWitnessName" class="form-label">Witness Name</label>
                                                            <input type="text" class="form-control" id="editWitnessName" name="Witness_Name">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editWitnessAge" class="form-label">Witness Age</label>
                                                            <input type="number" class="form-control" id="editWitnessAge" name="Witness_Age" min="0">
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editWitnessSex" class="form-label">Witness Sex</label>
                                                            <select class="form-control" id="editWitnessSex" name="Witness_Sex">
                                                                <option value="">Select</option>
                                                                <option value="Male">Male</option>
                                                                <option value="Female">Female</option>
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3">
                                                            <label for="editContactNumber" class="form-label">Contact Number</label>
                                                            <input type="text" class="form-control" id="editContactNumber" name="Contact_Number">
                                                        </div>

                                                        <div class="col-md-3">
                                                            <label for="editStatus" class="form-label">Status</label>
                                                            <select class="form-control" id="editStatus" name="Status">
                                                                <option value="">Select</option>
                                                                <option value="Active">Active</option>
                                                                <option value="Archived">Archived</option>
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
                                            <button type="submit" form="editForm" class="btn btn-primary" onclick="submitEditForm()">
                                                <i class="bi bi-save"></i> Save Changes
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Archive Confirmation Modal -->
                            <div class="modal fade" id="archiveModal" tabindex="-1" aria-labelledby="archiveModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content rounded-3">
                                        <div class="modal-header bg-danger text-white">
                                            <h5 class="modal-title" id="archiveModalLabel"><i class="bi bi-archive me-2"></i> Confirm Archive</h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <div class="modal-body">
                                            Are you sure you want to archive this incident report?
                                        </div>
                                        <div class="modal-footer justify-content-between">
                                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle"></i> Cancel
                                            </button>
                                            <button type="button" class="btn btn-danger" id="confirmArchiveBtn">
                                                <i class="bi bi-archive"></i> Archive
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
                                                <button class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addCrimeDataModal">
                                                    <i class="bi bi-plus-circle mr-1"></i> Add Crime Report
                                                </button>
                                            </div>
                                            <div class="mb-2">
                                                <button class="btn btn-outline-success btn-sm" data-bs-toggle="modal" data-bs-target="#searchModal">
                                                    <i class="bi bi-search mr-1"></i> Search Database
                                                </button>
                                            </div>
                                        </div>
                                        <table class="table table-card table-hover table-columned table-condensed">
                                            <div class="export-buttons">
                                                <button id="exportCsv" class="btn btn-outline-warning btn-sm"><i class="bi bi-file-earmark-spreadsheet me-1"></i>Export to CSV</button>
                                                <button id="exportPdf" class="btn btn-outline-danger btn-sm"><i class="bi bi-file-earmark-pdf me-1"></i>Export to PDF</button>
                                            </div>
                                            <thead class="thead-light">
                                                <tr>
                                                    <th colspan="100%" class="h5 text-primary">📋 Incident Reports</th>
                                                </tr>
                                                <tr>
                                                    <th scope="col" class="text-center">Actions</th>
                                                    <?php
                                                    $query = "SHOW COLUMNS FROM `vw_incident_report`";
                                                    $result = mysqli_query($conn, $query);
                                                    $columns = [];
                                                    while ($column = mysqli_fetch_assoc($result)) {
                                                        $columns[] = $column['Field'];
                                                        echo "<th scope='col' class='text-nowrap'>" . htmlspecialchars($column['Field']) . "</th>";
                                                    }
                                                    ?>
                                                </tr>
                                            </thead>
                                            <tbody id="dynamicReportTable">
                                                <?php
                                                $query = "SELECT * FROM `vw_incident_report`";
                                                $result = mysqli_query($conn, $query);
                                                while ($row = mysqli_fetch_assoc($result)) {
                                                    $firstKey = array_key_first($row);
                                                    $incidentId = $row[$firstKey];
                                                    echo "<tr data-id='$incidentId' data-status='" . htmlspecialchars(strtolower($row['Status'])) . "'>";  // Add data-status for sorting

                                                    $status = strtolower($row['Status']); // assuming 'status' exists in your table now

                                                    $archiveBtn = $status === 'archived'
                                                        ? "<button class='btn btn-sm btn-outline-success transition-hover mb-2 w-100' onclick='archiveIncident(" . json_encode($incidentId) . ", true)'>
                                                    <i class='bi bi-arrow-counterclockwise'></i> Unarchive
                                                    </button>"
                                                        : "<button class='btn btn-sm btn-outline-danger transition-hover mb-2 w-100' onclick='archiveIncident(" . json_encode($incidentId) . ", false)'>
                                                    <i class='bi bi-archive'></i> Archive
                                                    </button>";

                                                    echo "<td>
                                                    $archiveBtn
                                                    <br>
                                                    <button class='btn btn-sm btn-outline-info transition-hover w-100' onclick='startEdit(this)'>
                                                    <i class='bi bi-pencil-square'></i> Edit
                                                    </button>
                                                    </td>";

                                                    foreach ($columns as $col) {
                                                        echo "<td class='text-wrap wrap-limit' data-id='$incidentId' data-field='$col'>" . htmlspecialchars($row[$col]) . "</td>";
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
                        message: 'Successfully Submitted Crime Report!'
                    });
                });
                <?php $_SESSION['Success'] = false; ?>
            </script>
        <?php endif; ?>

        <script>
            const searchModal = document.getElementById('searchModal');
            searchModal.addEventListener('hidden.bs.modal', () => {
                document.getElementById('searchForm').reset();
            });

            // GLOBAL PAGINATION SETTINGS
            const rowsPerPage = 5;
            let currentPage = 1;

            function applySearch() {
                const formData = new FormData(document.getElementById('searchForm'));
                const params = new URLSearchParams(formData).toString();

                fetch(`../secure/search_incidents.php?${params}`)
                    .then(res => res.json())
                    .then(data => {
                        const table = document.getElementById('dynamicReportTable');
                        table.innerHTML = ''; // Clear table

                        if (data.length === 0) {
                            table.innerHTML = '<tr><td colspan="100%" class="text-center text-muted">No results found.</td></tr>';
                            document.getElementById('pagination').innerHTML = '';
                            return;
                        }

                        <?php
                        $query = "SHOW COLUMNS FROM `vw_incident_report`";
                        $result = mysqli_query($conn, $query);
                        $clientCols = [];
                        while ($col = mysqli_fetch_assoc($result)) {
                            $clientCols[] = $col['Field'];
                        }
                        echo "const columns = " . json_encode($clientCols) . ";";
                        ?>

                        data.forEach(row => {
                            const tr = document.createElement('tr');
                            tr.dataset.id = row.incident_id;

                            // Create a 'status' button based on the value
                            const isArchived = row.Status === 'Archived';
                            const actions = document.createElement('td');
                            actions.innerHTML = `
                            <button class="btn btn-sm ${isArchived ? 'btn-outline-success' : 'btn-outline-danger'} w-100 mb-2"
                            onclick="archiveIncident('${row.incident_id}', ${isArchived})">
                            <i class="bi ${isArchived ? 'bi-arrow-counterclockwise' : 'bi-archive'}"></i>
                            ${isArchived ? 'Unarchive' : 'Archive'}
                            </button><br>
                            <button class="btn btn-sm btn-outline-info w-100" onclick="startEdit(this)">
                            <i class="bi bi-pencil-square"></i> Edit
                            </button>
                            `;
                            tr.appendChild(actions);

                            columns.forEach(col => {
                                const td = document.createElement('td');
                                td.className = 'text-wrap wrap-limit';
                                td.dataset.id = row.incident_id;
                                td.dataset.field = col;
                                td.textContent = row[col] ?? '';
                                tr.appendChild(td);
                            });

                            table.appendChild(tr);
                        });

                        // Sort rows: First by Status, then by Date or Incident ID (if needed)
                        const rows = Array.from(table.querySelectorAll('tr')); // Select all the rows

                        const sortedRows = rows.sort((a, b) => {
                            // Sort by Status (Active first, Archived last)
                            const statusA = a.querySelector('[data-field="Status"]').textContent.trim();
                            const statusB = b.querySelector('[data-field="Status"]').textContent.trim();
                            const statusOrder = statusA === 'Active' ? -1 : 1; // Active comes first

                            // If Status is the same, sort by Date (or another criterion like Incident ID)
                            if (statusA === statusB) {
                                const dateA = new Date(a.querySelector('[data-field="Date"]').textContent);
                                const dateB = new Date(b.querySelector('[data-field="Date"]').textContent);
                                return dateB - dateA; // Sort by date, latest first
                            }

                            return statusOrder;
                        });

                        // Append sorted rows back into the table
                        sortedRows.forEach(row => {
                            table.appendChild(row);
                        });

                        currentPage = 1;
                        paginateTable(); // Rerun pagination after sorting
                    })
                    .catch(err => alert(`Search failed: ${err}`));
            }

            function paginateTable() {
                const table = document.getElementById('dynamicReportTable');
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

            function startEdit(button) {
                const row = button.closest('tr');
                if (!row) return;

                const incidentId = row.dataset.id;

                // Populate modal fields from table cells
                row.querySelectorAll('td[data-field]').forEach(td => {
                    const field = td.dataset.field;
                    const value = td.textContent.trim();

                    // Select input/select/textarea inside the modal
                    const input = document.querySelector(`#editModal [name="${field}"]`);
                    if (input) {
                        if (input.tagName === 'SELECT') {
                            Array.from(input.options).forEach(option => {
                                option.selected = option.value === value;
                            });
                        } else {
                            input.value = value;
                        }
                    }
                });

                // Set hidden incident_id input
                const idInput = document.querySelector('#editModal [name="incident_id"]');
                if (idInput) {
                    idInput.value = incidentId;
                }

                // Show modal (optional if using data-bs-toggle)
                const modalEl = document.getElementById('editModal');
                if (modalEl) {
                    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
                    modal.show();
                }
            }

            // Run pagination once on initial page load
            document.addEventListener('DOMContentLoaded', paginateTable);
        </script>

    </div>

    <!-- EXPORT LOGIC -->
    <!-- Include jsPDF and autoTable Library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.18/jspdf.plugin.autotable.js"></script>


    <script>
        // CSV Export for Incident Reports
        document.getElementById("exportCsv").addEventListener("click", () => {
            const rows = document.querySelectorAll("#dynamicReportTable tr");
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
            link.download = "incident_report.csv";
            link.click();
        });

        // PDF Export for Incident Reports
        document.getElementById("exportPdf").addEventListener("click", () => {
            const {
                jsPDF
            } = window.jspdf;
            const doc = new jsPDF("l", "pt", "a4"); // Landscape orientation for better table fit

            const headers = Array.from(document.querySelectorAll("thead tr:nth-child(2) th"))
                .slice(1) // Skip 'Actions' column
                .map(th => th.textContent.trim());

            const rows = Array.from(document.querySelectorAll("#dynamicReportTable tr")).map(tr =>
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
                            cellWidth: 54
                        }; // ~15 columns at 60px each + margins fits A4 landscape
                        return cols;
                    }, {})
                },
                didDrawPage: function(data) {
                    doc.setFontSize(14);
                    doc.setTextColor(40);
                    doc.text(" Incident Report", data.settings.margin.left, 25);
                }
            });

            doc.save("incident_report.pdf");
        });
    </script>

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
        // Crime types mapped by category
        const categoryToCrimes = {
            "Theft": [
                "Pickpocketing",
                "Bag Snatching",
                "Bike Theft",
                "Car Theft",
                "Car Break-in",
                "Tool Theft",
                "ATM Theft",
                "Shoplifting",
                "Home Burglary",
                "Gas Siphoning"
            ],
            "Violence": [
                "Street Fight",
                "Mugging",
                "Assault",
                "Group Brawl",
                "Verbal Threats",
                "Weapon Display",
                "Domestic Assault",
                "Sexual Assault",
                "Robbery with Violence",
                "Armed Confrontation"
            ],
            "Vandalism": [
                "Graffiti",
                "Broken Streetlight",
                "Damaged Road Sign",
                "Shattered Window",
                "Fence Damage",
                "Public Property Damage",
                "Spray Painting Private Property",
                "Slashed Tires",
                "Damaged Bus Stop",
                "Vandalized Playground Equipment"
            ],
            "Drug Activity": [
                "Public Drug Use",
                "Drug Transaction",
                "Drug Paraphernalia Found",
                "Suspected Drug House",
                "Needles Found in Public Area",
                "Odor of Drugs",
                "Drug Dealing Near School",
                "Overdose Incident"
            ],
            "Traffic": [
                "Reckless Driving",
                "Hit and Run",
                "Illegal Parking",
                "Blocking Driveway",
                "Street Racing",
                "Wrong Way Driving",
                "Running Red Light",
                "Speeding in Residential Area",
                "Driving Without Headlights",
                "Failure to Yield"
            ],
            "Disturbance": [
                "Noise Complaint",
                "Public Intoxication",
                "Loitering",
                "Street Harassment",
                "Fireworks in Street",
                "Unruly Crowd",
                "Blocking Pedestrian Path",
                "Disorderly Conduct",
                "Shouting Matches",
                "Rowdy Behavior at Night"
            ],
            "Suspicious": [
                "Suspicious Person",
                "Suspicious Vehicle",
                "Unattended Package",
                "Unknown Person Peering into Cars",
                "Person Hiding Behind Bushes",
                "Repeated Door Knocking",
                "Drone Hovering at Night",
                "Person with Binoculars"
            ],
            "Environmental": [
                "Illegal Dumping",
                "Littering",
                "Open Manhole",
                "Flooded Street",
                "Downed Power Line",
                "Dead Animal in Street",
                "Blocked Storm Drain",
                "Overflowing Trash Can",
                "Leaking Fire Hydrant",
                "Hazardous Waste Found"
            ],
            "Domestic Dispute": [
                "Yelling Heard from House",
                "Fight in Front Yard",
                "Ongoing Argument in Street",
                "Throwing Objects Outside Home",
                "Loud Screaming Indoors",
                "Police Called to Residence",
                "Suspected Child Abuse",
                "Verbal Abuse in Public"
            ]
        };

        const categorySelecct = document.getElementById('cCategory');
        const categorySelect = document.getElementById('category');

        const editCategory = document.getElementById('editCategory');
        const editCrime = document.getElementById('editCrime');

        const crimeSelecct = document.getElementById('cCrime');
        const crimeSelect = document.getElementById('crime');
        const crimeError = document.getElementById('crime-error');

        // When category changes, populate crime types
        categorySelecct.addEventListener('change', function() {
            const category = this.value;
            crimeSelecct.innerHTML = '<option value="">-- Select a Crime --</option>';

            if (category && categoryToCrimes[category]) {
                categoryToCrimes[category].forEach(crime => {
                    const opt = document.createElement('option');
                    opt.textContent = crime;
                    crimeSelecct.appendChild(opt);
                });
                crimeSelecct.disabled = false;
            } else {
                crimeSelecct.disabled = true;
            }

            crimeError.style.display = 'none'; // Hide error when category changes
        });

        categorySelect.addEventListener('change', function() {
            const category = this.value;
            crimeSelect.innerHTML = '<option value="">-- Select a Crime --</option>';

            if (category && categoryToCrimes[category]) {
                categoryToCrimes[category].forEach(crime => {
                    const opt = document.createElement('option');
                    opt.textContent = crime;
                    crimeSelect.appendChild(opt);
                });
                crimeSelect.disabled = false;
            } else {
                crimeSelect.disabled = true;
            }

            crimeError.style.display = 'none'; // Hide error when category changes
        });

        editCategory.addEventListener('change', function() {
            const category = this.value;
            editCrime.innerHTML = '<option value="">-- Select a Crime --</option>';

            if (category && categoryToCrimes[category]) {
                categoryToCrimes[category].forEach(crime => {
                    const opt = document.createElement('option');
                    opt.textContent = crime;
                    editCrime.appendChild(opt);
                });
                editCrime.disabled = false;
            } else {
                editCrime.disabled = true;
            }

            crimeError.style.display = 'none'; // Hide error when category changes
        });
    </script>

    <script>
        function submitEditForm() {
            // Collect form data
            var formData = new FormData(document.getElementById('editForm'));

            // Send AJAX request to the server
            fetch('../secure/update_incident.php', {
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
        let incidentToArchive = null;
        let isUnarchiving = false;

        function archiveIncident(incidentId, unarchive = false) {
            incidentToArchive = incidentId;
            isUnarchiving = unarchive;

            const modalBody = document.querySelector('#archiveModal .modal-body');
            const modalTitle = document.getElementById('archiveModalLabel');
            const confirmBtn = document.getElementById('confirmArchiveBtn');

            modalTitle.innerHTML = unarchive ? '<i class="bi bi-arrow-counterclockwise me-2"></i> Confirm Unarchive' : '<i class="bi bi-archive me-2"></i> Confirm Archive';
            modalBody.textContent = unarchive ? 'Are you sure you want to unarchive this incident report?' : 'Are you sure you want to archive this incident report?';
            confirmBtn.classList.toggle('btn-danger', !unarchive);
            confirmBtn.classList.toggle('btn-success', unarchive);
            confirmBtn.innerHTML = unarchive ? '<i class="bi bi-arrow-counterclockwise"></i> Unarchive' : '<i class="bi bi-archive"></i> Archive';

            const modal = new bootstrap.Modal(document.getElementById('archiveModal'));
            modal.show();
        }

        document.getElementById('confirmArchiveBtn').addEventListener('click', () => {
            if (incidentToArchive !== null) {
                fetch('../secure/archive_incident.php', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            id: incidentToArchive,
                            unarchive: isUnarchiving
                        })
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (data.success) {
                            const row = document.querySelector(`tr[data-id="${incidentToArchive}"]`);
                            if (row) {
                                const btnCell = row.querySelector('td');
                                btnCell.querySelector('button').outerHTML = isUnarchiving ?
                                    `<button class='btn btn-sm btn-outline-danger transition-hover mb-2 w-100' onclick='archiveIncident(${incidentToArchive}, false)'>
                 <i class='bi bi-archive'></i> Archive
               </button>` :
                                    `<button class='btn btn-sm btn-outline-success transition-hover mb-2 w-100' onclick='archiveIncident(${incidentToArchive}, true)'>
                 <i class='bi bi-arrow-counterclockwise'></i> Unarchive
               </button>`;
                                location.reload();
                            }
                        } else {
                            alert('Action failed. Please try again.');
                        }
                        bootstrap.Modal.getInstance(document.getElementById('archiveModal')).hide();
                        incidentToArchive = null;
                        isUnarchiving = false;
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
            const table = document.getElementById("dynamicReportTable");
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

    <script>
        const toggleBtn = document.getElementById('toggleMapBtn');
        const mapContainer = document.getElementById('map-container');
        mapContainer.style.display = 'none'; // Initially hidden

        toggleBtn.addEventListener('click', function() {
            const isHidden = mapContainer.style.display === 'none';
            mapContainer.style.display = isHidden ? 'block' : 'none';
            toggleBtn.textContent = isHidden ? 'Hide Map' : '📍 Select a Street';

            if (isHidden && typeof map !== 'undefined') {
                setTimeout(() => map.invalidateSize(), 200); // Ensures map renders correctly
            }
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