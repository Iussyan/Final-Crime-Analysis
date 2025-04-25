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
                                            <h5 class="m-b-10">Crime Analysis</h5>
                                            <p class="m-b-0">Graphical summaries of crime data</p>
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
                                                <div class="col-lg-6 mb-8">
                                                    <div class="card shadow-sm border-0 transition-hover rounded-4">
                                                        <div class="card-header text-white rounded-top-4">
                                                            <h5 class="mb-0">Crime Growth per Month</h5>
                                                        </div>
                                                        <div class="card-body" style="height: 350px;">
                                                            <canvas id="crimesByMonthChart"></canvas>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-lg-6 mb-4">
                                                    <div class="card shadow-sm border-0 transition-hover rounded-4">
                                                        <div class="card-header text-white rounded-top-4">
                                                            <h5 class="mb-0">Crime Type Breakdown</h5>
                                                        </div>
                                                        <div class="card-body d-flex justify-content-center align-items-center" style="height: 350px;">
                                                            <canvas id="crimeTypeBreakdownChart" style="max-height: 300px;"></canvas>
                                                        </div>
                                                    </div>
                                                </div>

                                                <script>
                                                    const crimeTypeData = <?php echo json_encode($crimeTypeData); ?>;
                                                    const typeLabels = crimeTypeData.map(item => item.crimeType);
                                                    const typeValues = crimeTypeData.map(item => item.total);

                                                    const typeColors = [
                                                        '#e74c3c', '#3498db', '#2ecc71', '#f1c40f', '#9b59b6',
                                                        '#1abc9c', '#e67e22', '#34495e', '#95a5a6', '#d35400'
                                                    ];

                                                    const ctxType = document.getElementById('crimeTypeBreakdownChart').getContext('2d');
                                                    new Chart(ctxType, {
                                                        type: 'doughnut',
                                                        data: {
                                                            labels: typeLabels,
                                                            datasets: [{
                                                                data: typeValues,
                                                                backgroundColor: typeColors,
                                                                borderColor: '#fff',
                                                                borderWidth: 2
                                                            }]
                                                        },
                                                        options: {
                                                            responsive: true,
                                                            maintainAspectRatio: false,
                                                            plugins: {
                                                                legend: {
                                                                    position: 'right',
                                                                    labels: {
                                                                        color: '#333',
                                                                        font: {
                                                                            size: 12,
                                                                            weight: 'bold'
                                                                        }
                                                                    }
                                                                },
                                                                tooltip: {
                                                                    backgroundColor: '#ecf0f1',
                                                                    titleColor: '#000',
                                                                    bodyColor: '#000'
                                                                }
                                                            }
                                                        }
                                                    });
                                                </script>

                                                <script>
                                                    const chartData = <?php echo json_encode($data); ?>;
                                                    const labels = chartData.map(item => item.month);
                                                    const values = chartData.map(item => item.total);

                                                    const ctx = document.getElementById('crimesByMonthChart').getContext('2d');
                                                    new Chart(ctx, {
                                                        type: 'bar',
                                                        data: {
                                                            labels: labels,
                                                            datasets: [{
                                                                label: 'Number of Crimes',
                                                                data: values,
                                                                backgroundColor: 'rgba(231, 76, 60, 0.7)',
                                                                borderColor: 'rgba(192, 57, 43, 1)',
                                                                borderWidth: 1,
                                                                borderRadius: 5,
                                                                barPercentage: 0.7,
                                                                categoryPercentage: 0.6,
                                                            }]
                                                        },
                                                        options: {
                                                            responsive: true,
                                                            maintainAspectRatio: false,
                                                            plugins: {
                                                                legend: {
                                                                    display: true,
                                                                    position: 'bottom',
                                                                    labels: {
                                                                        color: '#333',
                                                                        font: {
                                                                            size: 12,
                                                                            weight: 'bold'
                                                                        }
                                                                    }
                                                                },
                                                                tooltip: {
                                                                    backgroundColor: '#f1c40f',
                                                                    titleColor: '#000',
                                                                    bodyColor: '#000'
                                                                }
                                                            },
                                                            scales: {
                                                                x: {
                                                                    title: {
                                                                        display: true,
                                                                        text: 'Month',
                                                                        color: '#2c3e50',
                                                                        font: {
                                                                            weight: 'bold'
                                                                        }
                                                                    },
                                                                    ticks: {
                                                                        color: '#2c3e50'
                                                                    },
                                                                    grid: {
                                                                        display: false
                                                                    }
                                                                },
                                                                y: {
                                                                    beginAtZero: true,
                                                                    title: {
                                                                        display: true,
                                                                        text: 'Number of Crimes',
                                                                        color: '#2c3e50',
                                                                        font: {
                                                                            weight: 'bold'
                                                                        }
                                                                    },
                                                                    ticks: {
                                                                        color: '#2c3e50',
                                                                        stepSize: 1
                                                                    },
                                                                    grid: {
                                                                        color: '#ecf0f1'
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    });
                                                </script>
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
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Crime Frequency per Street</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="crimesByStreetChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                    <button class="btn btn-outline-danger mb-3" onclick="exportAllChartsToPDF()">Export All Charts to PDF</button>
                                                                </div>

                                                                <!-- Crime Type Distribution -->
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Crime Type Distribution</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="crimeTypeDistributionChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <!-- Witness Age Distribution -->
                                                                <div class="col-lg-4 mb-4">
                                                                    <div class="card shadow-sm border-0 transition-hover bg-c-lite-green rounded-4">
                                                                        <div class="card-header text-white rounded-top-4">
                                                                            <h5 class="mb-0">Witness Age Distribution</h5>
                                                                        </div>
                                                                        <div class="card-body" style="height: 350px;">
                                                                            <canvas id="witnessAgeDistributionChart"></canvas>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                <script>
                                                    // charts.js
                                                    document.addEventListener("DOMContentLoaded", function() {
                                                        // Fetch the chart data from the PHP file
                                                        fetch('fetch_chart_data.php')
                                                            .then(response => response.json())
                                                            .then(data => {
                                                                // Crime Frequency per Street Chart
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
                                                                            backgroundColor: ['rgba(255, 230, 0, 0.7)', 'rgba(219, 113, 52, 0.7)', 'rgba(241, 60, 15, 0.7)', 'rgba(204, 46, 46, 0.7)'],
                                                                            borderColor: 'rgba(46, 204, 113, 1)',
                                                                            borderWidth: 1
                                                                        }]
                                                                    },
                                                                    options: {
                                                                        responsive: true,
                                                                        maintainAspectRatio: false,
                                                                        scales: {
                                                                            x: {
                                                                                display: false
                                                                            },
                                                                            y: {
                                                                                beginAtZero: true,
                                                                                display: false
                                                                            }
                                                                        },
                                                                        plugins: {
                                                                            tooltip: {
                                                                                callbacks: {
                                                                                    label: (tooltipItem) => {
                                                                                        return `Street: ${streetLabels[tooltipItem.index]}`;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                });

                                                                // Crime Type Distribution Chart
                                                                const crimeTypeData = data.crimeTypeData;
                                                                const ctxCrimeType = document.getElementById('crimeTypeDistributionChart').getContext('2d');
                                                                const crimeTypeLabels = crimeTypeData.map(item => item.crimeType);
                                                                const crimeTypeValues = crimeTypeData.map(item => item.crimeCount);

                                                                new Chart(ctxCrimeType, {
                                                                    type: 'pie',
                                                                    data: {
                                                                        labels: crimeTypeLabels,
                                                                        datasets: [{
                                                                            data: crimeTypeValues,
                                                                            backgroundColor: ['rgba(231, 76, 60, 0.7)', 'rgba(52, 152, 219, 0.7)', 'rgba(241, 196, 15, 0.7)', 'rgba(46, 204, 113, 0.7)'],
                                                                            borderColor: ['rgba(231, 76, 60, 1)', 'rgba(52, 152, 219, 1)', 'rgba(241, 196, 15, 1)', 'rgba(46, 204, 113, 1)'],
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
                                                                                    label: function(tooltipItem) {
                                                                                        return tooltipItem.label + ': ' + tooltipItem.raw;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                });

                                                                // Witness Age Distribution Chart
                                                                const ageData = data.ageData;
                                                                const ctxAge = document.getElementById('witnessAgeDistributionChart').getContext('2d');
                                                                const ageLabels = ageData.map(item => item.ageRange);
                                                                const ageValues = ageData.map(item => item.count);

                                                                new Chart(ctxAge, {
                                                                    type: 'bar',
                                                                    data: {
                                                                        labels: ageLabels,
                                                                        datasets: [{
                                                                            label: 'Number of Witnesses',
                                                                            data: ageValues,
                                                                            backgroundColor: 'rgba(155, 89, 182, 0.7)',
                                                                            borderColor: 'rgba(155, 89, 182, 1)',
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
                                                                                    text: 'Number of Witnesses'
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
    <script src="../javascript/map-full-stack.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <!-- At the bottom of your page before </body> -->
    <script>
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'))
        tooltipTriggerList.forEach(function(el) {
            new bootstrap.Tooltip(el)
        });
    </script>

</body>

</html>