<?php
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

$id = $_SESSION['user_id'];
$role = $_SESSION['role'];
$firstName = $_SESSION['firstName'];
$lastName = $_SESSION['lastName'];
$email = $_SESSION['email'];
$contact = $_SESSION['contact'];
$username = $_SESSION['username'];

unset($_SESSION['loginSuccess']);
?>

<?php
include '../secure/connection.php';

// Fetch monthly crime data
$sql = "SELECT 
            DATE_FORMAT(date, '%Y-%m') AS month,
            COUNT(*) AS total
        FROM incident_data
        GROUP BY month
        ORDER BY month";

$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

$query = "SELECT crimeType, COUNT(*) AS total FROM crime_data GROUP BY crimeType";
$result = $conn->query($query);

$crimeTypeData = [];
while ($row = $result->fetch_assoc()) {
    $crimeTypeData[] = $row;
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <title>Crime Analysis</title>
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
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">

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

        #crimeByDateChart {
            width: 100% !important;
            height: 100% !important;
            max-height: 300px;
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
                                <li class="active ">
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
                            <div class="page-block">
                                <div class="row align-items-center">
                                    <div class="col-md-8">
                                        <div class="page-header-title">
                                            <h4 class="display-4 font-weight-bold mb-2">
                                                Crime Analysis
                                            </h4>
                                            <p class="lead mb-0">
                                                Graphical summaries of crime data
                                            </p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <ul class="breadcrumb-title">
                                            <li class="breadcrumb-item">
                                                <a href="dashboard.php"> <i class="fa fa-home"></i> </a>
                                            </li>
                                            <li class="breadcrumb-item">
                                                <a href="crime_analysis.php"><i class="ti-pulse"></i> Crime Analysis</a>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Page-header end -->
                        <div class="pcoded-inner-content">
                            <!-- Main Body Start -->
                            <div class="pcoded-inner-content">
                                <div class="main-body">
                                    <div class="page-wrapper">
                                        <!-- Page-body start -->
                                        <div class="page-body">
                                            <!-- Row start -->
                                            <div class="row">
                                                <!-- Multiple Open Accordion start -->
                                                <div class="col-lg-6 mb-4">
                                                    <div
                                                        class="card shadow-sm border-0 transition-hover rounded-4"
                                                        style="cursor: pointer;"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#monthModal">
                                                        <div class="card-header text-white rounded-top-4">
                                                            <h5 class="mb-0">Crime Growth per Month</h5>
                                                        </div>
                                                        <div class="card-body" style="height: 350px;">
                                                            <canvas id="crimesByMonthChart"></canvas>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="col-lg-6 mb-4">
                                                    <div
                                                        class="card shadow-sm border-0 transition-hover rounded-4"
                                                        style="cursor: pointer;"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#typeModal">
                                                        <div class="card-header text-white rounded-top-4">
                                                            <h5 class="mb-0">Crime Type Breakdown</h5>
                                                        </div>
                                                        <div class="card-body d-flex justify-content-center align-items-center" style="height: 350px;">
                                                            <canvas id="crimeTypeBreakdownChart"></canvas>
                                                        </div>
                                                    </div>
                                                </div>

                                                <script>
                                                    // 2) Fetch JSON from data endpoint
                                                    fetch('../secure/crime_analysis_data.php')
                                                        .then(r => {
                                                            if (!r.ok) throw new Error('Auth error');
                                                            return r.json();
                                                        })
                                                        .then(payload => {
                                                            const monthly = payload.monthly;
                                                            const crimeType = payload.crimeType;

                                                            // Prepare arrays
                                                            const months = monthly.map(o => o.month);
                                                            const totals = monthly.map(o => o.total);

                                                            const types = crimeType.map(o => o.crimeType);
                                                            const counts = crimeType.map(o => o.total);

                                                            // 3) Init Chart.js charts
                                                            const ctx1 = document.getElementById('crimesByMonthChart').getContext('2d');
                                                            new Chart(ctx1, {
                                                                type: 'bar',
                                                                data: {
                                                                    labels: months,
                                                                    datasets: [{
                                                                        label: 'Total Crimes',
                                                                        data: totals
                                                                    }]
                                                                },
                                                                options: {
                                                                    responsive: true,
                                                                    maintainAspectRatio: false
                                                                }
                                                            });

                                                            const ctx2 = document.getElementById('crimeTypeBreakdownChart').getContext('2d');
                                                            new Chart(ctx2, {
                                                                type: 'doughnut',
                                                                data: {
                                                                    labels: types,
                                                                    datasets: [{
                                                                        data: counts
                                                                    }]
                                                                },
                                                                options: {
                                                                    responsive: true,
                                                                    maintainAspectRatio: false
                                                                }
                                                            });
                                                        })
                                                        .catch(console.error);
                                                </script>

                                                <!-- MONTHLY CHART MODAL -->
                                                <div class="modal fade" id="monthModal" tabindex="-1" aria-labelledby="monthModalLabel" aria-hidden="true">
                                                    <div class="modal-dialog modal-xl modal-dialog-centered">
                                                        <div class="modal-content shadow-lg rounded-4">
                                                            <div class="modal-header bg-primary text-white border-0 rounded-top-4">
                                                                <h5 class="modal-title" id="monthModalLabel">
                                                                    <i class="fa fa-bar-chart me-2"></i>
                                                                    Crime Growth per Month
                                                                </h5>
                                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                                            </div>
                                                            <div class="modal-body p-4" id="monthModalBody">
                                                                <p class="text-muted mb-3" id="monthModalDesc">
                                                                    This bar chart shows the total number of reported crimes each month. Hover or tap a bar for details.
                                                                </p>
                                                                <div style="height: 70vh;" id="monthChartContainer">
                                                                    <canvas id="crimesByMonthChartModal"></canvas>
                                                                </div>
                                                                <p class="mt-3 text-secondary" id="monthModalSummary">
                                                                    <strong>Summary:</strong> Over the past year, crime peaked in July and dipped in February, indicating a mid‑summer surge.
                                                                </p>
                                                            </div>
                                                            <div class="modal-footer border-0">
                                                                <!-- Export PDF button -->
                                                                <button id="exportMonthPdfBtn" type="button" class="btn btn-primary">
                                                                    <i class="fa fa-file-pdf-o me-1"></i> Export PDF
                                                                </button>
                                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                                    <i class="fa fa-times me-1"></i> Close
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- TYPE BREAKDOWN MODAL -->
                                                <div class="modal fade" id="typeModal" tabindex="-1" aria-labelledby="typeModalLabel" aria-hidden="true">
                                                    <div class="modal-dialog modal-lg modal-dialog-centered">
                                                        <div class="modal-content shadow-lg rounded-4">
                                                            <div class="modal-header bg-success text-white border-0 rounded-top-4">
                                                                <h5 class="modal-title" id="typeModalLabel">
                                                                    <i class="fa fa-pie-chart me-2"></i>
                                                                    Crime Type Breakdown
                                                                </h5>
                                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                                            </div>

                                                            <!-- ⚠️ FIX: position-relative & overflow hidden -->
                                                            <div class="modal-body p-4 position-relative" id="typeModalBody" style="overflow: hidden;">
                                                                <p class="text-muted mb-3" id="typeModalDesc">
                                                                    Distribution of crime reports by category over the selected time period.
                                                                </p>

                                                                <!-- ⚠️ FIX: pointer-events auto to ensure canvas doesn't block -->
                                                                <div class="ratio ratio-4x3" id="typeChartContainer" style="max-height: 60vh; position: relative; pointer-events: auto;">
                                                                    <canvas id="crimeTypeBreakdownChartModal" style="pointer-events: none;"></canvas>
                                                                </div>

                                                                <p class="mt-3 text-secondary" id="typeModalSummary">
                                                                    <strong>Summary:</strong> Theft accounts for nearly 40% of incidents, followed by vandalism and assault.
                                                                </p>
                                                            </div>

                                                            <div class="modal-footer border-0">
                                                                <!-- Export PDF button -->
                                                                <button id="exportTypePdfBtn" type="button" class="btn btn-success">
                                                                    <i class="fa fa-file-pdf-o me-1"></i> Export PDF
                                                                </button>
                                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                                    <i class="fa fa-times me-1"></i> Close
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Color Open Accordion start -->
                                                <!-- HTML File -->
                                                <div class="col-lg-12">
                                                    <div class="card">
                                                        <div class="card-header">
                                                            <h5 class="card-header-text">Various Summary of Crime-Related Charts</h5>
                                                        </div>
                                                        <div class="card-block">
                                                            <!-- Crime Frequency per Street -->
                                                            <div class="row">
                                                                <!-- Crime Frequency per Street -->
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4"
                                                                        role="button" data-bs-toggle="modal" data-bs-target="#streetModal">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Crime Frequency per Street</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="crimesByStreetChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- Crime Type Distribution -->
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4"
                                                                        role="button" data-bs-toggle="modal" data-bs-target="#typeModal">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Crime Type Distribution</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="crimeTypeDistributionChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- Victim Age Distribution -->
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4"
                                                                        role="button" data-bs-toggle="modal" data-bs-target="#ageModal">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Victim Age Distribution</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="witnessAgeDistributionChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- CRIME FREQUENCY PER STREET MODAL -->
                                                                <div class="modal fade" id="streetModal" tabindex="-1" aria-labelledby="streetModalLabel" aria-hidden="true">
                                                                    <div class="modal-dialog modal-lg modal-dialog-centered">
                                                                        <div class="modal-content shadow-lg rounded-4">
                                                                            <div class="modal-header bg-danger text-white border-0 rounded-top-4">
                                                                                <h5 class="modal-title" id="streetModalLabel">
                                                                                    <i class="fa fa-line-chart me-2"></i>
                                                                                    Crime Frequency by Street
                                                                                </h5>
                                                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                                                            </div>

                                                                            <div class="modal-body p-4 position-relative" id="streetModalBody" style="overflow: hidden;">
                                                                                <p class="text-muted mb-3" id="streetModalDesc">
                                                                                    This chart shows the number of crime reports recorded on different streets.
                                                                                </p>

                                                                                <div class="ratio ratio-4x3" id="streetChartContainer" style="max-height: 60vh; position: relative; pointer-events: auto;">
                                                                                    <canvas id="crimesByStreetChartModal" style="pointer-events: none;"></canvas>
                                                                                </div>

                                                                                <p class="mt-3 text-secondary" id="streetModalSummary">
                                                                                    <strong>Summary:</strong> Some streets show a noticeably higher concentration of incidents, indicating potential hotspots.
                                                                                </p>
                                                                            </div>

                                                                            <div class="modal-footer border-0">
                                                                                <!-- Export PDF button -->
                                                                                <button id="exportStreetPdfBtn" type="button" class="btn btn-danger">
                                                                                    <i class="fa fa-file-pdf-o me-1"></i> Export PDF
                                                                                </button>
                                                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                                                    <i class="fa fa-times me-1"></i> Close
                                                                                </button>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- CRIME TYPE DISTRIBUTION MODAL -->
                                                                <div class="modal fade" id="typeModal" tabindex="-1" aria-labelledby="typeModalLabel" aria-hidden="true">
                                                                    <div class="modal-dialog modal-lg modal-dialog-centered">
                                                                        <div class="modal-content shadow-lg rounded-4">
                                                                            <div class="modal-header bg-success text-white border-0 rounded-top-4">
                                                                                <h5 class="modal-title" id="typeModalLabel">
                                                                                    <i class="fa fa-pie-chart me-2"></i>
                                                                                    Crime Type Breakdown
                                                                                </h5>
                                                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                                                            </div>

                                                                            <div class="modal-body p-4 position-relative" style="overflow: hidden;">
                                                                                <p class="text-muted mb-3">
                                                                                    Distribution of reported crimes by category across the recorded timeframe.
                                                                                </p>

                                                                                <div class="ratio ratio-4x3" style="max-height: 60vh; position: relative; pointer-events: auto;">
                                                                                    <canvas id="crimeTypeBreakdownChartModal" style="pointer-events: none;"></canvas>
                                                                                </div>

                                                                                <p class="mt-3 text-secondary">
                                                                                    <strong>Summary:</strong> This breakdown highlights which categories of crime are most prevalent in the dataset.
                                                                                </p>
                                                                            </div>

                                                                            <div class="modal-footer border-0">
                                                                                <button id="exportTypePdfBtn" type="button" class="btn btn-success">
                                                                                    <i class="fa fa-file-pdf-o me-1"></i> Export PDF
                                                                                </button>
                                                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                                                    <i class="fa fa-times me-1"></i> Close
                                                                                </button>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- VICTIM AGE DISTRIBUTION MODAL -->
                                                                <div class="modal fade" id="ageModal" tabindex="-1" aria-labelledby="ageModalLabel" aria-hidden="true">
                                                                    <div class="modal-dialog modal-lg modal-dialog-centered">
                                                                        <div class="modal-content shadow-lg rounded-4">
                                                                            <div class="modal-header bg-primary text-white border-0 rounded-top-4">
                                                                                <h5 class="modal-title" id="ageModalLabel">
                                                                                    <i class="fa fa-bar-chart me-2"></i>
                                                                                    Victim Age Distribution
                                                                                </h5>
                                                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                                                            </div>

                                                                            <div class="modal-body p-4 position-relative" style="overflow: hidden;">
                                                                                <p class="text-muted mb-3">
                                                                                    Analysis of reported victims categorized by age group over the selected timeframe.
                                                                                </p>

                                                                                <div class="ratio ratio-4x3" style="max-height: 60vh; position: relative; pointer-events: auto;">
                                                                                    <canvas id="victimAgeDistributionChartModal" style="pointer-events: none;"></canvas>
                                                                                </div>

                                                                                <p class="mt-3 text-secondary">
                                                                                    <strong>Summary:</strong> The data shows which age groups are more frequently victimized.
                                                                                </p>
                                                                            </div>

                                                                            <div class="modal-footer border-0">
                                                                                <button id="exportAgePdfBtn" type="button" class="btn btn-primary">
                                                                                    <i class="fa fa-file-pdf-o me-1"></i> Export PDF
                                                                                </button>
                                                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                                                                    <i class="fa fa-times me-1"></i> Close
                                                                                </button>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                <script>
                                                    document.addEventListener("DOMContentLoaded", function() {
                                                        fetch('../secure/crime_analysis_data.php')
                                                            .then(response => response.json())
                                                            .then(data => {
                                                                // ——— 1) Crime Frequency per Street Chart ———
                                                                const streetData = data.streetData;
                                                                const ctxStreet = document.getElementById('crimesByStreetChart').getContext('2d');
                                                                const streetLabels = streetData.map(item => item.street);
                                                                const streetValues = streetData.map(item => item.crimeCount);

                                                                new Chart(ctxStreet, {
                                                                    type: 'line',
                                                                    data: {
                                                                        labels: streetLabels,
                                                                        datasets: [{
                                                                            label: 'Number of Crimes',
                                                                            data: streetValues,
                                                                            backgroundColor: 'rgba(255, 99, 132, 0.6)',
                                                                            borderColor: 'rgba(255, 99, 132, 1)',
                                                                            borderWidth: 1
                                                                        }]
                                                                    },
                                                                    options: {
                                                                        responsive: true,
                                                                        maintainAspectRatio: false,
                                                                        plugins: {
                                                                            title: {
                                                                                display: false,
                                                                                text: 'Crime Frequency by Street',
                                                                                font: {
                                                                                    size: 18
                                                                                }
                                                                            },
                                                                            tooltip: {
                                                                                callbacks: {
                                                                                    label: function(context) {
                                                                                        return `${context.label}: ${context.formattedValue} crimes`;
                                                                                    }
                                                                                }
                                                                            }
                                                                        },
                                                                        scales: {
                                                                            x: {
                                                                                ticks: {
                                                                                    autoSkip: false,
                                                                                    maxRotation: 90
                                                                                },
                                                                                title: {
                                                                                    display: false,
                                                                                    text: 'Street Name'
                                                                                }
                                                                            },
                                                                            y: {
                                                                                beginAtZero: true,
                                                                                title: {
                                                                                    display: true,
                                                                                    text: 'Number of Crimes'
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                });

                                                                // ——— 2) Crime Type Distribution Chart ———
                                                                const crimeTypeData = data.crimeType;
                                                                const ctxCrimeType = document.getElementById('crimeTypeDistributionChart').getContext('2d');
                                                                const crimeTypeLabels = crimeTypeData.map(item => item.crimeType);
                                                                const crimeTypeValues = crimeTypeData.map(item => item.total);

                                                                new Chart(ctxCrimeType, {
                                                                    type: 'pie',
                                                                    data: {
                                                                        labels: crimeTypeLabels,
                                                                        datasets: [{
                                                                            data: crimeTypeValues,
                                                                            backgroundColor: [
                                                                                'rgba(54, 162, 235, 0.7)',
                                                                                'rgba(255, 206, 86, 0.7)',
                                                                                'rgba(75, 192, 192, 0.7)',
                                                                                'rgba(153, 102, 255, 0.7)',
                                                                                'rgba(255, 159, 64, 0.7)'
                                                                            ],
                                                                            borderColor: [
                                                                                'rgba(54, 162, 235, 1)',
                                                                                'rgba(255, 206, 86, 1)',
                                                                                'rgba(75, 192, 192, 1)',
                                                                                'rgba(153, 102, 255, 1)',
                                                                                'rgba(255, 159, 64, 1)'
                                                                            ],
                                                                            borderWidth: 1
                                                                        }]
                                                                    },
                                                                    options: {
                                                                        responsive: true,
                                                                        maintainAspectRatio: false,
                                                                        plugins: {
                                                                            title: {
                                                                                display: false,
                                                                                text: 'Crime Type Distribution',
                                                                                font: {
                                                                                    size: 18
                                                                                }
                                                                            },
                                                                            legend: {
                                                                                position: 'right'
                                                                            },
                                                                            tooltip: {
                                                                                callbacks: {
                                                                                    label: function(tooltipItem) {
                                                                                        return `${tooltipItem.label}: ${tooltipItem.raw}`;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                });

                                                                // ——— 3) Victim Age Distribution Chart ———
                                                                const ageData = data.ageData;
                                                                const ctxAge = document.getElementById('witnessAgeDistributionChart').getContext('2d');
                                                                const ageLabels = ageData.map(item => item.ageRange);
                                                                const ageValues = ageData.map(item => item.count);

                                                                new Chart(ctxAge, {
                                                                    type: 'bar',
                                                                    data: {
                                                                        labels: ageLabels,
                                                                        datasets: [{
                                                                            label: 'Number of Victims',
                                                                            data: ageValues,
                                                                            backgroundColor: 'rgba(255, 159, 64, 0.7)',
                                                                            borderColor: 'rgba(255, 159, 64, 1)',
                                                                            borderWidth: 1
                                                                        }]
                                                                    },
                                                                    options: {
                                                                        responsive: true,
                                                                        maintainAspectRatio: false,
                                                                        plugins: {
                                                                            title: {
                                                                                display: false,
                                                                                text: 'Victim Age Distribution',
                                                                                font: {
                                                                                    size: 18
                                                                                }
                                                                            },
                                                                            tooltip: {
                                                                                callbacks: {
                                                                                    label: function(context) {
                                                                                        return `${context.label}: ${context.formattedValue} victims`;
                                                                                    }
                                                                                }
                                                                            }
                                                                        },
                                                                        scales: {
                                                                            x: {
                                                                                title: {
                                                                                    display: true,
                                                                                    text: 'Age Range'
                                                                                }
                                                                            },
                                                                            y: {
                                                                                beginAtZero: true,
                                                                                title: {
                                                                                    display: true,
                                                                                    text: 'Number of Victims'
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                });
                                                            })
                                                            .catch(error => console.error('Error fetching data:', error));
                                                    });
                                                </script>

                                            </div>
                                        </div>

                                        <!-- Color Open Accordion ends -->
                                        <!-- Row end -->
                                    </div>
                                    <!-- Page-body end -->
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


    <script>
        async function exportAllChartsToPDF() {
            const {
                jsPDF
            } = window.jspdf;
            const pdf = new jsPDF('p', 'mm', 'a4');
            let yPosition = 20;

            const charts = [{
                    id: 'crimesByStreetChart',
                    title: 'Crime Frequency per Street'
                },
                {
                    id: 'crimeTypeDistributionChart',
                    title: 'Crime Type Distribution'
                },
                {
                    id: 'witnessAgeDistributionChart',
                    title: 'Witness Age Distribution'
                },
                {
                    id: 'crimesByMonthChart',
                    title: 'Crime Growth per Month'
                },
                {
                    id: 'crimeTypeBreakdownChart',
                    title: 'Crime Type Breakdown'
                }
            ];

            for (let i = 0; i < charts.length; i++) {
                const canvas = document.getElementById(charts[i].id);
                if (!canvas) continue;

                const imgData = canvas.toDataURL('image/png', 1.0);

                // Add title
                pdf.setFontSize(14);
                pdf.setTextColor(33, 33, 33);
                pdf.text(charts[i].title, 15, yPosition);

                // Add chart image
                pdf.addImage(imgData, 'PNG', 15, yPosition + 5, 180, 90);

                yPosition += 105;

                // Add a new page if it's not the last chart
                if (i < charts.length - 1) {
                    pdf.addPage();
                    yPosition = 20;
                }
            }

            pdf.save("crime_visualization_summary.pdf");
        }
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
    </div>
    <!-- Warning Section Ends -->
    <!-- Required Jquery -->
    <script type="text/javascript" src="assets/js/jquery/jquery.min.js"></script>
    <script type="text/javascript" src="assets/js/jquery-ui/jquery-ui.min.js "></script>
    <script type="text/javascript" src="assets/js/popper.js/popper.min.js"></script>
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
    <!-- Script Dependencies -->
    <!-- html2canvas & jsPDF -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://unpkg.com/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>

    <script>
        // —— 1) Prepare data from PHP —— 
        const monthlyData = <?php echo json_encode($data); ?>;
        const typeData = <?php echo json_encode($crimeTypeData); ?>;

        const monthLabels = monthlyData.map(o => o.month),
            monthTotals = monthlyData.map(o => o.total),
            typeLabels = typeData.map(o => o.crimeType),
            typeTotals = typeData.map(o => o.total);

        let monthChart = null,
            typeChart = null;

        // —— 2) Helper to wire up a modal’s chart —— 
        function wireChartModal(modalId, canvasId, createChartFn) {
            const modalEl = document.getElementById(modalId);

            modalEl.addEventListener('shown.bs.modal', () => {
                const ctx = document.getElementById(canvasId).getContext('2d');
                const chartVar = (modalId === 'monthModal' ? monthChart : typeChart);

                if (chartVar) {
                    chartVar.resize();
                    return;
                }
                const newChart = createChartFn(ctx);
                if (modalId === 'monthModal') monthChart = newChart;
                else typeChart = newChart;
            });

            modalEl.addEventListener('hidden.bs.modal', () => {
                const chartVar = (modalId === 'monthModal' ? monthChart : typeChart);
                if (chartVar) {
                    chartVar.destroy();
                    if (modalId === 'monthModal') monthChart = null;
                    else typeChart = null;
                }
            });
        }

        // —— 3) Wire up your two modals —— 
        wireChartModal('monthModal', 'crimesByMonthChartModal', ctx => new Chart(ctx, {
            type: 'bar',
            data: {
                labels: monthLabels,
                datasets: [{
                    label: 'Total Crimes',
                    data: monthTotals
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        }));

        wireChartModal('typeModal', 'crimeTypeBreakdownChartModal', ctx => new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: typeLabels,
                datasets: [{
                    data: typeTotals
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        }));

        // —— 4) Export‑to‑PDF wiring —— 
        const jsPDFctor = window.jspdf?.jsPDF || window.jsPDF;
        if (!jsPDFctor) {
            console.error('jsPDF not found—did you include its <script>?');
        } else {
            async function exportPDF(modalId, filename) {
                const modal = document.getElementById(modalId);
                const body = modal.querySelector('.modal-body');
                const title = modal.querySelector('.modal-title').innerText;
                const timestamp = new Date().toLocaleString();

                // Snapshot chart area
                const canvas = await html2canvas(body, {
                    scale: 2,
                    useCORS: true
                });
                const img = canvas.toDataURL('image/png');

                // Setup PDF
                const doc = new jsPDFctor({
                    unit: 'pt',
                    format: 'a4',
                    orientation: 'portrait'
                });

                const pageWidth = doc.internal.pageSize.getWidth();
                const margin = 40;
                let cursorY = margin;

                // Header
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(22);
                doc.text("Crime Statistics Report", pageWidth / 2, cursorY, {
                    align: 'center'
                });

                cursorY += 25;

                // Subheading
                doc.setFontSize(14);
                doc.setFont('helvetica', 'normal');
                doc.setTextColor('#555');
                doc.text(title, pageWidth / 2, cursorY, {
                    align: 'center'
                });

                cursorY += 20;
                doc.setFontSize(10);
                doc.text(`Generated: ${timestamp}`, pageWidth / 2, cursorY, {
                    align: 'center'
                });

                cursorY += 30;

                // Chart Image
                const imageProps = doc.getImageProperties(img);
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (imageProps.height * imgWidth) / imageProps.width;

                doc.addImage(img, 'PNG', margin, cursorY, imgWidth, imgHeight);

                // Footer
                cursorY += imgHeight + 30;
                doc.setDrawColor('#ccc');
                doc.setLineWidth(0.5);
                doc.line(margin, cursorY, pageWidth - margin, cursorY);

                cursorY += 15;
                doc.setFontSize(9);
                doc.setTextColor('#999');
                doc.text("© Barangay San Bartolome | Confidential", pageWidth / 2, cursorY, {
                    align: 'center'
                });

                // Save
                doc.save(filename);
            }

            document.getElementById('exportMonthPdfBtn')
                .addEventListener('click', () => exportPDF('monthModal', 'Crime_Growth_per_Month.pdf'));

            document.getElementById('exportTypePdfBtn')
                .addEventListener('click', () => exportPDF('typeModal', 'Crime_Type_Breakdown.pdf'));
        }
    </script>

    <script>
        var streetModalChart, typeModalChart, ageModalChart;

        // Reusable fetch call
        async function fetchCrimeData() {
            const response = await fetch('../secure/crime_analysis_data.php');
            if (!response.ok) throw new Error('Failed to fetch crime data');
            return await response.json();
        }

        // ——— Street Modal Chart ———
        document.getElementById('streetModal').addEventListener('shown.bs.modal', async function() {
            if (streetModalChart) return;

            try {
                const data = await fetchCrimeData();
                const ctx = document.getElementById('crimesByStreetChartModal').getContext('2d');
                const streetLabels = data.streetData.map(item => item.street);
                const streetValues = data.streetData.map(item => item.crimeCount);

                streetModalChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: streetLabels,
                        datasets: [{
                            label: 'Number of Crimes',
                            data: streetValues,
                            backgroundColor: 'rgba(255, 99, 132, 0.6)',
                            borderColor: 'rgba(255, 99, 132, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: false,
                                text: 'Crime Frequency by Street',
                                font: {
                                    size: 18
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        return `${context.label}: ${context.formattedValue} crimes`;
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                ticks: {
                                    autoSkip: false,
                                    maxRotation: 90
                                },
                                title: {
                                    display: false,
                                    text: 'Street Name'
                                }
                            },
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Number of Crimes'
                                }
                            }
                        }
                    }
                });
            } catch (error) {
                console.error('Error loading street chart:', error);
            }
        });

        // ——— Type Modal Chart ———
        document.getElementById('typeModal').addEventListener('shown.bs.modal', async function() {
            if (typeModalChart) return;

            try {
                const data = await fetchCrimeData();
                const ctx = document.getElementById('crimeTypeBreakdownChartModal').getContext('2d');
                const labels = data.crimeType.map(item => item.crimeType);
                const values = data.crimeType.map(item => item.total);

                typeModalChart = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: labels,
                        datasets: [{
                            data: values,
                            backgroundColor: [
                                'rgba(54, 162, 235, 0.7)',
                                'rgba(255, 206, 86, 0.7)',
                                'rgba(75, 192, 192, 0.7)',
                                'rgba(153, 102, 255, 0.7)',
                                'rgba(255, 159, 64, 0.7)'
                            ],
                            borderColor: [
                                'rgba(54, 162, 235, 1)',
                                'rgba(255, 206, 86, 1)',
                                'rgba(75, 192, 192, 1)',
                                'rgba(153, 102, 255, 1)',
                                'rgba(255, 159, 64, 1)'
                            ],
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'top'
                            },
                            tooltip: {
                                callbacks: {
                                    label: (tooltipItem) => `${tooltipItem.label}: ${tooltipItem.raw}`
                                }
                            }
                        }
                    }
                });
            } catch (error) {
                console.error('Error loading crime type chart:', error);
            }
        });

        // ——— Age Modal Chart ———
        document.getElementById('ageModal').addEventListener('shown.bs.modal', async function() {
            if (ageModalChart) return;

            try {
                const data = await fetchCrimeData();
                const ctx = document.getElementById('victimAgeDistributionChartModal').getContext('2d');
                const labels = data.ageData.map(item => item.ageRange);
                const values = data.ageData.map(item => item.count);

                ageModalChart = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: 'Number of Victims',
                            data: values,
                            backgroundColor: 'rgba(255, 159, 64, 0.7)',
                            borderColor: 'rgba(255, 159, 64, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: {
                                title: {
                                    display: true,
                                    text: 'Age Range'
                                }
                            },
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Number of Victims'
                                }
                            }
                        },
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: (tooltipItem) => `${tooltipItem.label}: ${tooltipItem.raw}`
                                }
                            },
                            title: {
                                display: true,
                                text: "Victim's Age Distribution"
                            }
                        }
                    }
                });
            } catch (error) {
                console.error('Error loading victim age chart:', error);
            }
        });

        // ——— PDF Export Utility ———
        async function exportChartToPDF(canvasId, title = 'Chart Report') {
            const {
                jsPDF
            } = window.jspdf;
            const doc = new jsPDF();

            const canvas = document.getElementById(canvasId);
            const imgData = canvas.toDataURL('image/png');

            doc.setFontSize(18);
            doc.text(title, 15, 20);
            doc.addImage(imgData, 'PNG', 15, 30, 180, 100);
            doc.save(`${title.replace(/\s+/g, '_').toLowerCase()}.pdf`);
        }

        // Button Listeners for Export
        document.getElementById('exportStreetPdfBtn')?.addEventListener('click', () => {
            exportChartToPDF('crimeFrequencyChartModal', 'Crime Frequency per Street');
        });

        document.getElementById('exportTypePdfBtn')?.addEventListener('click', () => {
            exportChartToPDF('crimeTypeBreakdownChartModal', 'Crime Type Distribution');
        });

        document.getElementById('exportAgePdfBtn')?.addEventListener('click', () => {
            exportChartToPDF('victimAgeDistributionChartModal', "Victim's Age Distribution");
        });
    </script>

</body>

</html>