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

include '../secure/auth.php';
requireRole('user');

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
    <title>Contact Us</title>
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
                                <li class="">
                                    <a href="crime_mapping.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-map-alt"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Crime Mapping</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul>

                            <!-- <div class="pcoded-navigation-label" data-i18n="nav.category.forms">User Management</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class=" ">
                                    <a href="manage_users.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-user"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">Manage Users</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                            </ul> -->

                            <div class="pcoded-navigation-label" data-i18n="nav.category.forms">Other Utilities</div>
                            <ul class="pcoded-item pcoded-left-item">
                                <li class="">
                                    <a href="user_manual.php" class="waves-effect waves-dark">
                                        <span class="pcoded-micon"><i class="ti-book"></i><b>FC</b></span>
                                        <span class="pcoded-mtext" data-i18n="nav.form-components.main">User Manual</span>
                                        <span class="pcoded-mcaret"></span>
                                    </a>
                                </li>
                                <li class="active">
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
                                                Contact Us
                                            </h4>
                                            <p class="lead mb-0">
                                                Our team's contact info
                                            </p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                            <li class="breadcrumb-item">
                                                <a href="user_manual.php"><i class="ti-info-alt"></i> Contact Us</a>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="container-fluid mt-4 px-4">
                            <!-- Modals -->

                            <!-- Card Container -->
                            <div class="card shadow border-0 rounded">
                                <div class="card-header">
                                    <h5 class="card-header-text">CONTACT OUR TEAM</h5>
                                </div>
                                <div class="card-block accordion-block color-accordion">
                                    <div class="accordion" role="tablist" id="userManualAccordion" aria-multiselectable="true">

                                        <!-- Login and Dashboard -->
                                        <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingOne">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="false" aria-controls="collapseOne">
                                                        Main Programmer
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseOne" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingOne" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                    <strong>Name: </strong>Julius K. SIlvano Jr. <br>
                                                    <strong>Email Address: </strong> silvano.julius.kadusale@gmail.com <br>
                                                    <strong>Contact Number: </strong> 09944902128 <br>   
                                                    </p>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Crime Reporting -->
                                        <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingTwo">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" aria-expanded="false" aria-controls="collapseOne">
                                                        Our Designers
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseTwo" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingTwo" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                    <strong>Name: </strong>Julie-Ann Baliguat <br>
                                                    <strong>Email Address: </strong> julianbaliguat16@gmail.com <br>
                                                    <strong>Contact Number: </strong> 09077153945 <br><br>
                                                    <strong>Name: </strong>Kristine Camille Gallardo<br>
                                                    <strong>Email Address: </strong> camillegallardo146@gmail.com <br>
                                                    <strong>Contact Number: </strong> 09938957410<br><br>
                                                    <strong>Name: </strong>Rjay C. Lorete <br>
                                                    <strong>Email Address: </strong> lorete.rjay.calizo@gmail.com <br>
                                                    <strong>Contact Number: </strong> 09944902128 <br><br>
                                                    <strong>Name: </strong>Khylle Paano <br>
                                                    <strong>Email Address: </strong> paanokhylleagunday@gmail.com <br>
                                                    <strong>Contact Number: </strong> 09944902128 <br><br>
                                                    <strong>Name: </strong>Robert Miko A. Santos <br>
                                                    <strong>Email Address: </strong> robertmikosantos@gmail.com  <br>
                                                    <strong>Contact Number: </strong> 09944902128 <br><br>
                                                    </p>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Search and Export -->
                                        <!-- <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingThree">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseThree" aria-expanded="false" aria-controls="collapseThree">
                                                        3. Searching and Exporting Crime Records
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseThree" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingThree" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                        The system includes a robust search mechanism allowing users to locate crime reports using flexible keyword queries. Whether partial or vague inputs are used, the system intelligently filters relevant entries. Additionally, all data tables can be exported as CSV or PDF files for offline review, printing, or external reporting needs.
                                                    </p>
                                                </div>
                                            </div>
                                        </div> -->

                                        <!-- Crime Analysis -->
                                        <!-- <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingFour">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseFour" aria-expanded="false" aria-controls="collapseFour">
                                                        4. Visualizing Crime Analysis
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseFour" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingFour" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                        The "Crime Analysis" module provides dynamic, auto-updating charts that offer visual insights into crime trends. These charts include crime growth over time, type distribution, and demographic data. Users can interact with these charts and export them collectively into a formatted PDF report suitable for official documentation.
                                                    </p>
                                                </div>
                                            </div>
                                        </div> -->

                                        <!-- Crime Mapping -->
                                        <!-- <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingFive">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseFive" aria-expanded="false" aria-controls="collapseFive">
                                                        5. Crime Mapping and Incident Reports
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseFive" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingFive" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                        The system’s mapping component visualizes crimes using geospatial data. Incidents are reflected as heatmaps or color-coded street markers. Users can click on streets to view detailed incident lists and have the option to export the results in either PDF or CSV format for further review or public distribution.
                                                    </p>
                                                </div>
                                            </div>
                                        </div> -->

                                        <!-- User Management -->
                                        <!-- <div class="accordion-panel">
                                            <div class="accordion-heading" role="tab" id="headingSix">
                                                <h6 class="card-title accordion-title">
                                                    <a class="accordion-msg waves-effect waves-dark scale_active collapsed" data-toggle="collapse" data-parent="#accordion" href="#collapseSix" aria-expanded="false" aria-controls="collapseSix">
                                                        6. Managing User Accounts
                                                    </a>
                                                </h6>
                                            </div>
                                            <div id="collapseSix" class="panel-collapse in collapse" role="tabpanel" aria-labelledby="headingSix" style="">
                                                <div class="accordion-content accordion-desc">
                                                    <p>
                                                        Administrators have access to comprehensive user management tools. They can add new users by providing essential information such as name, username, password, and contact details. Existing user information can be updated—excluding passwords—and users may be permanently removed from the system when necessary. The interface also supports robust user search and filtering, with export options available to download user lists in CSV or PDF formats.
                                                    </p>
                                                </div>
                                            </div>
                                        </div> -->

                                    </div>
                                </div>
                            </div>
                        </div>
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