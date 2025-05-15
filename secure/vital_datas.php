<?php
session_start();
include 'connection.php';

$recentIncidents = [];
$totalIncidents = 0;
$totalReports = [];
$totalCrimes = 0;
$streetsTotal = [];
$dayCrimeStats = [];
$peakDay = '';
$peakDayCrimes = 0;
$peakHour = '';
$peakHourCrimes = 0;

// Clear previous session data first (optional but clean)
unset(
    $_SESSION['recentIncidents'],
    $_SESSION['totalIncidents'],
    $_SESSION['totalReports'],
    $_SESSION['totalCrimes'],
    $_SESSION['mostCommonCategory'],
    $_SESSION['totalReport'],
    $_SESSION['streetsTotal'],
    $_SESSION['Most Affected Street'],
    $_SESSION['Total Crime'],
    $_SESSION['peakDay'],
    $_SESSION['peakDayCrimes'],
    $_SESSION['peakHour'],
    $_SESSION['peakHourCrimes'],
    $_SESSION['dayCrimeStats']
);

// Fetch Recent Incidents
if ($conn->multi_query("CALL getRecentIncidents()")) {
    if ($result = $conn->store_result()) {
        while ($row = $result->fetch_assoc()) {
            $recentIncidents[] = $row;
        }
        $result->free();
    }
    if ($conn->more_results() && $conn->next_result()) {
        if ($countResult = $conn->store_result()) {
            $row = $countResult->fetch_assoc();
            $totalIncidents = $row['TotalRecentIncidents'];
            $countResult->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}
$_SESSION['recentIncidents'] = $recentIncidents;
$_SESSION['totalIncidents'] = $totalIncidents;

// Fetch Crime Category Breakdown
if ($conn->multi_query("CALL getPrevalentCrimeCategories()")) {
    if ($result1 = $conn->store_result()) {
        while ($row = $result1->fetch_assoc()) {
            $totalReports[] = $row;
        }
        $result1->free();
    }
    if ($conn->more_results() && $conn->next_result()) {
        if ($result2 = $conn->store_result()) {
            $totalRow = $result2->fetch_assoc();
            $totalCrimes = $totalRow['Total Crime Reports'];
            $result2->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}
$_SESSION['totalReports'] = $totalReports;
$_SESSION['totalCrimes'] = $totalCrimes;

// Fetch Most Common Crime Category
$query = "
    SELECT 
        category AS `Most Common Category`,
        COUNT(*) AS `Total Reports`
    FROM crime_data
    GROUP BY category
    ORDER BY `Total Reports` DESC
    LIMIT 1;
";

if ($result = $conn->query($query)) {
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $_SESSION['mostCommonCategory'] = $row['Most Common Category'];
        $_SESSION['totalReport'] = $row['Total Reports'];
    }
    $result->free();
} else {
    error_log("Query failed: " . $conn->error);
}

// Fetch Street Crime Stats
if ($conn->multi_query("CALL getStreetCrimeStats();")) {
    if ($result = $conn->store_result()) {
        while ($row = $result->fetch_assoc()) {
            $streetsTotal[] = $row;
        }
        $result->free();
    }
    if ($conn->more_results() && $conn->next_result()) {
        if ($result = $conn->store_result()) {
            if ($row = $result->fetch_assoc()) {
                $_SESSION['Most Affected Street'] = $row['Most Affected Street'];
                $_SESSION['Total Crime'] = $row['Total Crimes'];
            }
            $result->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}
$_SESSION['streetsTotal'] = $streetsTotal;

// Fetch Peak Crime Times
if ($conn->multi_query("CALL getPeakCrimeTime()")) {
    if ($result = $conn->store_result()) {
        $row = $result->fetch_assoc();
        $peakDay = $row['Peak Day'];
        $peakDayCrimes = $row['Total Crimes'];
        $result->free();
    }
    if ($conn->more_results() && $conn->next_result()) {
        if ($result = $conn->store_result()) {
            $row = $result->fetch_assoc();
            $peakHour = $row['Peak Hour'];
            $peakHourCrimes = $row['Total Crimes'];
            $result->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}
$_SESSION['peakDay'] = $peakDay;
$_SESSION['peakDayCrimes'] = $peakDayCrimes;
$_SESSION['peakHour'] = $peakHour;
$_SESSION['peakHourCrimes'] = $peakHourCrimes;

// Fetch Crime by Day of the Week
if ($conn->multi_query("CALL getCrimeByDayOfWeek();")) {
    if ($result = $conn->store_result()) {
        while ($row = $result->fetch_assoc()) {
            $dayCrimeStats[] = $row;
        }
        $result->free();
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}
$_SESSION['dayCrimeStats'] = $dayCrimeStats;

$conn->close();