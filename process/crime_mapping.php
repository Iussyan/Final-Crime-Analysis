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
    <title>Crime Mapping</title>
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
                                <li class="active">
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
                                <li class=" ">
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
                            <!-- Modal: Incident Details -->
                            <div class="modal fade" id="incidentModal" tabindex="-1" aria-labelledby="incidentModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">

                                        <!-- Modal Header with Blue Gradient -->
                                        <div class="modal-header text-white" style="background: linear-gradient(135deg, #0d6efd, #dbeafe);">
                                            <h5 class="modal-title fw-bold" id="incidentModalLabel">
                                                <i class="bi bi-exclamation-triangle-fill me-2"></i> Incident Reports for Selected Street
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <!-- Modal Body with Dynamic Content -->
                                        <div class="modal-body px-4 py-3" id="incidentModalBodyP">
                                            <div class="text-center text-muted">
                                                <div class="spinner-border text-primary" role="status"></div>
                                                <p class="mt-2">Loading details...</p>
                                            </div>
                                        </div>

                                        <!-- Modal Footer -->
                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <div>
                                                <button class="btn btn-outline-primary me-2" id="exportAllCsvBtnP">
                                                    <i class="bi bi-file-earmark-spreadsheet me-1"></i> Export All CSV
                                                </button>
                                                <button class="btn btn-outline-danger" id="exportAllPdfBtnP">
                                                    <i class="bi bi-file-earmark-pdf me-1"></i> Export All PDF
                                                </button>
                                            </div>
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>

                                    </div>
                                </div>
                            </div>
                            <!-- Modal: Cluster Details -->
                            <div class="modal fade" id="incidentModalC" tabindex="-1" aria-labelledby="incidentModalLabel" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg">
                                    <div class="modal-content shadow-lg rounded-4">

                                        <!-- Modal Header with Blue Gradient -->
                                        <div class="modal-header text-white" style="background: linear-gradient(135deg, #0d6efd, #dbeafe);">
                                            <h5 class="modal-title fw-bold" id="incidentModalLabel">
                                                <i class="bi bi-exclamation-triangle-fill me-2"></i> Incident Reports of this Cluster
                                            </h5>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>

                                        <!-- Modal Body with Dynamic Content -->
                                        <div class="modal-body px-4 py-3" id="incidentModalBodyC">
                                            <div class="text-center text-muted">
                                                <div class="spinner-border text-primary" role="status"></div>
                                                <p class="mt-2">Loading details...</p>
                                            </div>
                                        </div>

                                        <!-- Modal Footer -->
                                        <div class="modal-footer bg-light rounded-bottom-4">
                                            <div class="me-auto">
                                                <button class="btn btn-outline-primary me-2" id="exportCsvBtn">
                                                    <i class="bi bi-filetype-csv me-1"></i> Export as CSV
                                                </button>
                                                <button class="btn btn-outline-danger" id="exportPdfBtn">
                                                    <i class="bi bi-file-earmark-pdf me-1"></i> Export as PDF
                                                </button>
                                            </div>
                                            <button class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                <i class="bi bi-x-circle me-1"></i> Close
                                            </button>
                                        </div>

                                    </div>
                                </div>
                            </div>

                            <div class="page-block">
                                <div class="row align-items-center">
                                    <div class="col-md-8">
                                        <div class="page-header-title">
                                            <h4 class="display-4 font-weight-bold mb-2">
                                                Crime Mapping
                                            </h4>
                                            <p class="lead mb-0">
                                                Easily view crime hotspots and heatmaps across the barangay
                                            </p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                            <li class="breadcrumb-item">
                                                <a href="crime_mapping.php"><i class="ti-map-alt"></i> Crime Maps</a>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="pcoded-inner-content">
                            <!-- Main Body Start -->
                            <div class="main-body">
                                <div class="page-wrapper">
                                    <div class="page-body">
                                        <div class="row">
                                            <div id="map-container" class="container-fluid p-0 position-relative" style="height: 73vh; overflow: hidden;">
                                                <!-- Leaflet Map Placeholder -->
                                                <div id="map" class="w-100 h-100"></div>
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
    <script src="assets/js/pcoded.min.js"></script>
    <script src="assets/js/vertical-layout.min.js "></script>
    <script src="assets/js/jquery.mCustomScrollbar.concat.min.js"></script>
    <!-- Custom js -->
    <script type="text/javascript" src="assets/js/script.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="../secure/apis/leaflet/leaflet.js?v=2" crossorigin=""></script>
    <script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>
    <script src="https://unpkg.com/leaflet-image/leaflet-image.js"></script>
    <script src="https://unpkg.com/@turf/turf@6.5.0/turf.min.js"></script>
    <!-- dom-to-image library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/dom-to-image/2.6.0/dom-to-image.min.js"></script>
    <!-- Script Dependencies -->
    <script src="../javascript/map-full-stack.js?v=3"></script>
    <!-- At the bottom of your page before </body> -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>

    <script>
        document.getElementById("exportCsvBtn").addEventListener("click", () => {
            const incidentCards = document.querySelectorAll("#incidentModalBodyC .card-body");
            let csvContent = "Category,Crime Type,Description,Date,Time,Street\n";

            incidentCards.forEach(card => {
                const titleText = card.querySelector("h6")?.textContent.trim() || "";
                const [category, crimeType] = titleText.split(" - ");

                const descEl = Array.from(card.querySelectorAll("p")).find(p => p.textContent.includes("Description:"));
                const metaEl = Array.from(card.querySelectorAll("p")).find(p => p.textContent.includes("Date:") && p.textContent.includes("Time:") && p.textContent.includes("Street:"));

                const description = descEl?.textContent.replace("Description: ", "").trim() || "";

                let date = "",
                    time = "",
                    street = "";
                if (metaEl) {
                    const metaMatch = metaEl.textContent.match(/Date:\s*(.*?)\s*\|\s*Time:\s*(.*?)\s*\|\s*Street:\s*(.*)/);
                    if (metaMatch) {
                        date = metaMatch[1];
                        time = metaMatch[2];
                        street = metaMatch[3];
                    }
                }

                csvContent += `"${category}","${crimeType}","${description}","${date}","${time}","${street}"\n`;
            });

            const blob = new Blob([csvContent], {
                type: "text/csv;charset=utf-8;"
            });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "cluster_incidents.csv";
            link.click();
        });

        document.getElementById("exportPdfBtn").addEventListener("click", () => {
            const {
                jsPDF
            } = window.jspdf;
            const doc = new jsPDF();
            let y = 10;
            const lineHeight = 6;
            const pageHeight = doc.internal.pageSize.height;

            const incidentCards = document.querySelectorAll("#incidentModalBodyC .card-body");

            if (!incidentCards.length) {
                doc.text("No incidents available.", 10, y);
            } else {
                incidentCards.forEach((card, index) => {
                    const title = card.querySelector("h6")?.textContent.trim() || "No Title";
                    const descEl = Array.from(card.querySelectorAll("p")).find(p => p.textContent.includes("Description:"));
                    const metaEl = Array.from(card.querySelectorAll("p")).find(p => p.textContent.includes("Date:") && p.textContent.includes("Time:"));

                    const desc = descEl?.textContent.trim() || "";
                    const meta = metaEl?.textContent.trim() || "";

                    doc.setFontSize(12);
                    const titleLines = doc.splitTextToSize(`${index + 1}. ${title}`, 180);
                    doc.text(titleLines, 10, y);
                    y += titleLines.length * lineHeight;

                    doc.setFontSize(10);
                    const descLines = doc.splitTextToSize(desc, 180);
                    doc.text(descLines, 12, y);
                    y += descLines.length * lineHeight;

                    const metaLines = doc.splitTextToSize(meta, 180);
                    doc.text(metaLines, 12, y);
                    y += metaLines.length * lineHeight + 4;

                    if (y > pageHeight - 20) {
                        doc.addPage();
                        y = 10;
                    }
                });
            }

            doc.save("cluster_incidents.pdf");
        });

        document.addEventListener("click", (e) => {
            const target = e.target;

            // 🌟 INDIVIDUAL CSV EXPORT
            if (target.classList.contains("export-csv")) {
                const container = target.closest("div.border");
                const lines = container.querySelectorAll("ul li");
                let csv = "ID,Address,Street,Street ID,Category,Crime Type,Description,Witness Name,Age,Sex,Contact\n";
                const values = [];

                lines.forEach(li => {
                    const text = li.textContent.split(": ");
                    values.push(text[1]?.trim() || "");
                });

                // pick only the required columns based on order
                const filtered = [
                    values[0], // ID
                    values[1], // Address
                    values[2], // Street
                    values[3], // Street ID
                    values[4], // Category
                    values[5], // Crime Type
                    values[6], // Description
                    values[7], // Witness Name
                    values[8], // Age
                    values[9], // Sex
                    values[10] // Contact
                ];

                csv += `"${filtered.join('","')}"\n`;

                const blob = new Blob([csv], {
                    type: "text/csv;charset=utf-8;"
                });
                const link = document.createElement("a");
                link.href = URL.createObjectURL(blob);
                link.download = "incident.csv";
                link.click();
            }

            // 🌟 INDIVIDUAL PDF EXPORT (with wrapping)
            if (target.classList.contains("export-pdf")) {
                const {
                    jsPDF
                } = window.jspdf;
                const doc = new jsPDF();
                const container = target.closest("div.border");
                const heading = container.querySelector("h6")?.textContent;
                const lines = container.querySelectorAll("ul li");
                let y = 10;

                doc.setFontSize(14);
                doc.text(heading, 10, y);
                y += 10;
                doc.setFontSize(11);

                lines.forEach(li => {
                    const wrappedText = doc.splitTextToSize(li.textContent, 180); // Wrap at ~180mm width
                    wrappedText.forEach(line => {
                        doc.text(line, 10, y);
                        y += 6;
                        if (y > 270) {
                            doc.addPage();
                            y = 10;
                        }
                    });
                });

                doc.save("incident.pdf");
            }

            // 🌟 EXPORT ALL CSV
            if (target.id === "exportAllCsvBtnP") {
                console.log("Export All CSV Clicked");

                const containers = document.querySelectorAll("#incidentModalBodyP .border");
                let csv = "ID,Address,Street,Street ID,Category,Crime Type,Description,Witness Name,Age,Sex,Contact\n";

                containers.forEach(container => {
                    const lines = container.querySelectorAll("ul li");
                    const values = [];

                    lines.forEach(li => {
                        const text = li.textContent.split(": ");
                        values.push(text[1]?.trim() || "");
                    });

                    const filtered = [
                        values[0], values[1], values[2], values[3],
                        values[4], values[5], values[6], values[7],
                        values[8], values[9], values[10]
                    ];

                    csv += `"${filtered.join('","')}"\n`;
                });

                const blob = new Blob([csv], {
                    type: "text/csv;charset=utf-8;"
                });
                const link = document.createElement("a");
                link.href = URL.createObjectURL(blob);
                link.download = "all_incidents.csv";
                link.click();
            }

            // 🌟 EXPORT ALL PDF
            if (target.id === "exportAllPdfBtnP") {
                console.log("Export All PDF Clicked");

                const {
                    jsPDF
                } = window.jspdf;
                const doc = new jsPDF();
                const containers = document.querySelectorAll("#incidentModalBodyP .border");
                let y = 10;

                if (!containers.length) {
                    doc.text("No incident data available.", 10, y);
                } else {
                    containers.forEach((container, idx) => {
                        const heading = container.querySelector("h6")?.textContent;
                        const lines = container.querySelectorAll("ul li");

                        doc.setFontSize(12);
                        doc.text(`${heading}`, 10, y);
                        y += 6;
                        doc.setFontSize(10);

                        lines.forEach(li => {
                            doc.text(li.textContent, 12, y);
                            y += 5;
                            if (y > 270) {
                                doc.addPage();
                                y = 10;
                            }
                        });

                        y += 5;
                    });
                }

                doc.save("all_incidents.pdf");
            }
        });
    </script>

    <script>
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'))
        tooltipTriggerList.forEach(function(el) {
            new bootstrap.Tooltip(el)
        });
    </script>

</body>

</html>