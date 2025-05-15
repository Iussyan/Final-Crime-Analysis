<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
    // If not logged in, redirect to login.php
    header("Location: login.php");
    exit;  // Ensure no further code is executed
}

$loginSuccess = isset($_SESSION['loginSuccess']) && $_SESSION['loginSuccess'];

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
    <title>Dashboard</title>
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
    <link rel="stylesheet" type="text/css" href="assets/css/style.css?v=1.2">
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

        .incident-table {
            min-width: 1200px;
            /* Allow the table to expand */
        }

        .fixed-button {
            display: none !important;
        }

        .page-header {
            background-image: url("../src/images/sb-bg.jpg");
            background-size: cover;
            position: relative;
            border-radius: 0;
            color: #fff;
        }

        .page-header:before {
            content: "";
            color: rgb(0, 0, 0);
            background-color: rgba(0, 0, 0, 0.5);
            width: 100%;
            height: 100%;
            position: absolute;
            top: 0;
            left: 0;
        }

        .page-header .page-block {
            padding: 35px 40px;
        }

        .page-header .page-block .breadcrumb-title {
            float: right;
        }

        .page-header .page-block .breadcrumb-title a {
            font-size: 14px;
            color: #fff;
        }

        .page-header .page-block .breadcrumb-title .breadcrumb-item+.breadcrumb-item::before {
            content: "\f105";
            font-family: FontAwesome;
            padding-right: 5px;
            font-size: 12px;
            color: #fff;
        }

        @media only screen and (max-width: 768px) {
            .page-header .page-block .breadcrumb-title {
                float: left;
                margin-top: 10px;
            }
        }

        .equal-height-card {
            display: flex;
            flex-direction: column;
            min-height: 240px;
            /* adjust as needed */
        }
    </style>
</head>

<body themebg-pattern="theme3">
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
    <div id="pcoded" class="pcoded" fream-type="theme3">
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
                            <button type="button" class="btn btn-primary" onclick="window.location.href='manage_users.php'">
                                <i class="bi bi-pencil-square mr-1"></i> Edit Profile
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <!-- Main Container -->
            <div class="pcoded-main-container">
                <div class="pcoded-wrapper">
                    <nav class="pcoded-navbar" navbar-theme="theme1">
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
                                <li class="active ">
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
                                <li class=" ">
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

                            <div class="pcoded-navigation-label" data-i18n="nav.category.forms">Other Utilities</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class=" ">
                                    <a href="user_manual.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-book"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">User Manual</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                                <li>
                                    <a href="contact_us.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-info-alt"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Contact Us</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </nav>
                    <div class="pcoded-content">
                        <!-- Page-header start -->
                        <div class="page-header">
                            <div class="page-block">
                                <div class="row align-items-center">
                                    <div class="col-md-8">
                                        <div class="page-header-title">
                                            <h4 class="display-4 font-weight-bold mb-2">
                                                C.H.A.R.M.
                                            </h4>
                                            <p class="lead mb-0">
                                                Welcome to Crime Hotspot Analysis Reporting and Mapping System!
                                            </p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="pcoded-inner-content">
                            <!-- Main-body start -->
                            <!-- Modals start-->
                            <div class="modal fade" id="recentIncidentsModal" tabindex="-1" aria-labelledby="recentIncidentsModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">
                                        <div class="modal-header bg-gradient text-white" style="background: linear-gradient(135deg, #5a78ff, #88b4ff);">
                                            <h5 class="modal-title fw-bold" id="recentIncidentsModalLabel">
                                                <i class="bi bi-clock-history me-2"></i> Recent Incidents (Last 15 Days)
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body px-4 py-3">
                                            <?php if (!empty($recentIncidents)): ?>
                                                <div class="mb-3">
                                                    <div class="bg-light rounded-3 p-3 border shadow-sm">
                                                        <h6 class="text-uppercase text-muted">Total Recent Incidents</h6>
                                                        <p class="mb-1 fw-semibold fs-5 text-dark"><?= $totalIncidents ?></p>
                                                    </div>
                                                </div>

                                                <div class="table-responsive mt-3">
                                                    <table class="table table-hover table-borderless align-middle text-start">
                                                        <thead class="table-success">
                                                            <tr>
                                                                <th>ID</th>
                                                                <th>Street</th>
                                                                <th>Date</th>
                                                                <th>Time</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody class="table-light">
                                                            <?php foreach ($recentIncidents as $incident): ?>
                                                                <tr>
                                                                    <td><?= $incident['IncidentId'] ?></td>
                                                                    <td class="text-break"><?= $incident['Street'] ?></td>
                                                                    <td><?= $incident['Date'] ?></td>
                                                                    <td><?= $incident['Time'] ?></td>
                                                                </tr>
                                                            <?php endforeach; ?>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <?php else: ?>
                                                <p class="text-muted">No recent incidents reported.</p>
                                            <?php endif; ?>
                                        </div>

                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="modal fade" id="totalCatsModal" tabindex="-1" aria-labelledby="totalCatsModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">
                                        <div class="modal-header bg-gradient text-white" style="background: linear-gradient(135deg, #ff6f61, #ffb88c);">
                                            <h5 class="modal-title fw-bold" id="totalCatsModalLabel">
                                                <i class="bi bi-pie-chart-fill me-2"></i> Total Number of Crimes per Category
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body px-4 py-3">
                                            <?php if (!empty($totalReports)): ?>
                                                <div class="mb-3">
                                                    <div class="bg-light rounded-3 p-3 border shadow-sm">
                                                        <h6 class="text-uppercase text-muted">Overall Reported Crimes</h6>
                                                        <p class="mb-1 fw-semibold fs-5 text-dark"><?= $totalCrimes ?></p>
                                                    </div>
                                                </div>

                                                <div class="table-responsive mt-3">
                                                    <table class="table table-hover table-borderless align-middle text-start">
                                                        <thead class="table-success">
                                                            <tr>
                                                                <th class="text-uppercase">Crime Category</th>
                                                                <th class="text-uppercase">Total Incidents</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody class="table-light">
                                                            <?php foreach ($totalReports as $cats): ?>
                                                                <tr>
                                                                    <td class="fw-medium"><?= $cats['Crime Category'] ?></td>
                                                                    <td><?= $cats['Total Reports'] ?></td>
                                                                </tr>
                                                            <?php endforeach; ?>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <?php else: ?>
                                                <p class="text-muted">No incidents reported yet.</p>
                                            <?php endif; ?>
                                        </div>

                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="modal fade" id="riskyModal" tabindex="-1" aria-labelledby="riskyModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">
                                        <div class="modal-header bg-gradient text-white" style="background: linear-gradient(135deg, #a56cc1, #d59bf6);">
                                            <h5 class="modal-title fw-bold" id="riskyModalLabel">
                                                <i class="bi bi-exclamation-triangle-fill me-2"></i> Risky Areas with Reported Crimes
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <div class="modal-body px-4 py-3">
                                            <?php if (!empty($streetsTotal)): ?>
                                                <div class="mb-3">
                                                    <div class="row g-3">
                                                        <div class="col-md-6">
                                                            <div class="bg-light rounded-3 p-3 border shadow-sm h-100">
                                                                <h6 class="text-uppercase text-muted">Most Risky Street</h6>
                                                                <p class="mb-1 fw-semibold fs-5 text-dark"><?= $mostAffectedStreet ?></p>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-6">
                                                            <div class="bg-light rounded-3 p-3 border shadow-sm h-100">
                                                                <h6 class="text-uppercase text-muted">Total Crimes in Street</h6>
                                                                <p class="mb-1 fw-semibold fs-5 text-dark"><?= $totalCrime ?></p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="table-responsive mt-3">
                                                    <table class="table table-hover table-borderless align-middle text-start">
                                                        <thead class="table-success">
                                                            <tr>
                                                                <th class="text-uppercase">Street</th>
                                                                <th class="text-uppercase">Total Crimes</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody class="table-light">
                                                            <?php foreach ($streetsTotal as $cats): ?>
                                                                <tr>
                                                                    <td class="fw-medium"><?= $cats['Street'] ?></td>
                                                                    <td><?= $cats['Total Crimes'] ?></td>
                                                                </tr>
                                                            <?php endforeach; ?>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <?php else: ?>
                                                <p class="text-muted">No incidents reported yet.</p>
                                            <?php endif; ?>
                                        </div>

                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="modal fade" id="crimeByDayModal" tabindex="-1" aria-labelledby="crimeByDayModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">
                                        <div class="modal-header bg-gradient text-white" style="background: linear-gradient(135deg, #51e2f5, #9df9ef);">
                                            <h5 class="modal-title fw-bold" id="crimeByDayModalLabel">
                                                <i class="bi bi-calendar-week-fill me-2"></i> Weekly Crime Insight
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                        <div class="modal-body px-4 py-3">
                                            <?php if (!empty($dayCrimeStats)): ?>
                                                <div class="mb-3">
                                                    <div class="row g-3">
                                                        <div class="col-md-6">
                                                            <div class="bg-light rounded-3 p-3 border shadow-sm h-100">
                                                                <h6 class="text-uppercase text-muted">Peak Day</h6>
                                                                <p class="mb-1 fw-semibold fs-5 text-dark"><?= $peakDay ?></p>
                                                                <small class="text-secondary">Total Crimes: <strong><?= $peakDayCrimes ?></strong></small>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-6">
                                                            <div class="bg-light rounded-3 p-3 border shadow-sm h-100">
                                                                <h6 class="text-uppercase text-muted">Peak Hour</h6>
                                                                <p class="mb-1 fw-semibold fs-5 text-dark"><?= "$peakHour:00" ?></p>
                                                                <small class="text-secondary">Total Crimes: <strong><?= $peakHourCrimes ?></strong></small>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="table-responsive mt-3">
                                                    <table class="table table-hover table-borderless align-middle text-start">
                                                        <thead class="table-success">
                                                            <tr>
                                                                <th class="text-uppercase">Day</th>
                                                                <th class="text-uppercase">Total Crimes</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody class="table-light">
                                                            <?php foreach ($dayCrimeStats as $day): ?>
                                                                <tr>
                                                                    <td class="fw-medium"><?= $day['Day'] ?></td>
                                                                    <td><?= $day['Total Crimes'] ?></td>
                                                                </tr>
                                                            <?php endforeach; ?>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <?php else: ?>
                                                <p class="text-muted">No crime data available for days of the week.</p>
                                            <?php endif; ?>
                                        </div>
                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="main-body">
                                <div class="page-wrapper">
                                    <!-- Page-body start -->
                                    <div class="page-body">
                                        <div class="row align-items-stretch">
                                            <!-- task, page, download counter  start -->
                                            <div class="col-xl-3 col-md-6">
                                                <div class="card shadow-sm transition-hover equal-height-card d-flex flex-column text-center" data-bs-toggle="modal" data-bs-target="#recentIncidentsModal" style="cursor: pointer;">
                                                    <div class="card-body d-flex flex-column justify-content-center align-items-center">
                                                        <i class="fa fa-newspaper-o fa-2x text-primary mb-3"></i>
                                                        <h4 class="text-primary">Recent Incidents (last 15 days)</h4>
                                                        <h5 class="text-muted mb-0"><?= $totalIncidents ?></h5>
                                                    </div>
                                                    <div class="card-footer bg-primary text-white mt-auto d-flex justify-content-between align-items-center px-3">
                                                        <p class="mb-0">Click to Expand</p>
                                                        <i class="fa fa-line-chart text-white f-16"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="col-xl-3 col-md-6">
                                                <div class="card shadow-sm transition-hover equal-height-card d-flex flex-column text-center" data-bs-toggle="modal" data-bs-target="#totalCatsModal" style="cursor: pointer;">
                                                    <div class="card-body d-flex flex-column justify-content-center align-items-center">
                                                        <i class="fa fa-file-text-o fa-2x text-c-red mb-3"></i>
                                                        <h4 class="text-c-red">Most Prevalent Crime Category</h4>
                                                        <h5 class="text-muted mb-0"><?= $mostCommonCategory ?></h5>
                                                    </div>
                                                    <div class="card-footer bg-c-red text-white mt-auto d-flex justify-content-between align-items-center px-3">
                                                        <p class="mb-0">Click to Expand</p>
                                                        <i class="fa fa-line-chart text-white f-16"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="col-xl-3 col-md-6">
                                                <div class="card shadow-sm transition-hover equal-height-card d-flex flex-column text-center" data-bs-toggle="modal" data-bs-target="#riskyModal" style="cursor: pointer;">
                                                    <div class="card-body d-flex flex-column justify-content-center align-items-center">
                                                        <i class="fa fa-map-signs fa-2x text-c-purple mb-3"></i>
                                                        <h4 class="text-c-purple">Most Risky Area</h4>
                                                        <h5 class="text-muted mb-0"><?= $mostAffectedStreet ?></h5>
                                                    </div>
                                                    <div class="card-footer bg-c-purple text-white mt-auto d-flex justify-content-between align-items-center px-3">
                                                        <p class="mb-0">Click to Expand</p>
                                                        <i class="fa fa-line-chart text-white f-16"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="col-xl-3 col-md-6">
                                                <div class="card shadow-sm transition-hover equal-height-card d-flex flex-column text-center" data-bs-toggle="modal" data-bs-target="#crimeByDayModal" style="cursor: pointer;">
                                                    <div class="card-body d-flex flex-column justify-content-center align-items-center">
                                                        <i class="fa fa-calendar fa-2x text-c-lite-green mb-3"></i>
                                                        <h4 class="text-c-lite-green">Peak Crime Day &amp; Time</h4>
                                                        <h5 class="text-muted mb-0"><?= $peakDay ?></h5>
                                                    </div>
                                                    <div class="card-footer bg-c-lite-green text-white mt-auto d-flex justify-content-between align-items-center px-3">
                                                        <p class="mb-0">Click to Expand</p>
                                                        <i class="fa fa-line-chart text-white f-16"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- task, page, download counter  end -->
                                            <div class="col-xl-14 col-md-12">
                                                <div class="card shadow-sm transition-hover">
                                                    <div class="card-header">
                                                        <h5>San Bartolome Map Overview</h5>
                                                        <span>You can select streets that you want to see on the map</span>
                                                    </div>
                                                    <div class="card-body p-0">
                                                        <div class="map-container" style="height: 475px;">
                                                            <div id="map" class="w-100 h-100"></div>
                                                        </div>
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
                    </div>
                </div>
            </div>
        </div>
    </div>

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
    <script src="assets/js/pcoded.min.js?v=2"></script>
    <script src="assets/js/vertical-layout.min.js?v=2"></script>
    <script src="assets/js/jquery.mCustomScrollbar.concat.min.js"></script>
    <!-- Custom js -->
    <script type="text/javascript" src="assets/js/script.js?v=2"></script>
    <script src="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="../secure/apis/leaflet/leaflet.js" crossorigin=""></script>
    <script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>
    <script src="https://unpkg.com/@turf/turf@6.5.0/turf.min.js"></script>
    <script src="../javascript/crime_data/map.js?v=2"></script>
    <script src="../javascript/crime_data/map-controls.js?v=2"></script>
    <script src="../javascript/crime_data/dashboard-street-layer.js?v=2"></script>
    <script src="../javascript/heatmap-layer.js?v=2"></script>
</body>

</html>