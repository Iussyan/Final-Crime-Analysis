<?php
session_start();
include 'connection.php';

$recentIncidents = [];
$totalIncidents = 0;

$totalReports = [];
$totalCrimes = 0;

// Call the stored procedure
if ($conn->multi_query("CALL getRecentIncidents()")) {
    // First result set: Incident data
    if ($result = $conn->store_result()) {
        while ($row = $result->fetch_assoc()) {
            $recentIncidents[] = $row;
        }
        $result->free();
    }

    // Move to the second result set
    if ($conn->more_results()) {
        $conn->next_result(); // move to next result set
        if ($countResult = $conn->store_result()) {
            $row = $countResult->fetch_assoc();
            $totalIncidents = $row['TotalRecentIncidents'];
            $countResult->free();
        }
        $_SESSION['recentIncidents'] = $recentIncidents;
        $_SESSION['totalIncidents'] = $totalIncidents;
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}

$sql = "CALL getPrevalentCrimeCategories()";

if ($conn->multi_query($sql)) {
    // First result: crime category breakdown
    if ($result1 = $conn->store_result()) {
        $categoryStats = [];
        while ($row = $result1->fetch_assoc()) {
            $totalReports[] = $row;
        }
        $result1->free();
    }

    // Move to second result set
    if ($conn->more_results()) {
        $conn->next_result();
        if ($result2 = $conn->store_result()) {
            $totalRow = $result2->fetch_assoc();
            $totalCrimes = $totalRow['Total Crime Reports'];

            $_SESSION['totalReports'] = $totalReports;
            $_SESSION['totalCrimes'] = $totalCrimes;
            $result2->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}

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
    // Optional: Log or handle SQL error
    error_log("Query failed: " . $conn->error);
}

$sql = "CALL getStreetCrimeStats();";

if ($conn->multi_query($sql)) {
    // First result: all street crime totals
    if ($result = $conn->store_result()) {
        echo "<h4>Crime Totals Per Street</h4><ul>";
        while ($row = $result->fetch_assoc()) {
            $streetsTotal[] = $row;
            $_SESSION['streetsTotal'] = $streetsTotal;
        }
        echo "</ul>";
        $result->free();
    }

    // Move to second result set
    if ($conn->more_results()) {
        $conn->next_result();
        if ($result = $conn->store_result()) {
            if ($row = $result->fetch_assoc()) {
                $_SESSION['Most Affected Street'] = $row['Most Affected Street'];
                $_SESSION['Total Crime'] = $row['Total Crimes'];
            }
            $result->free();
        }
        while ($conn->more_results() && $conn->next_result()) {
            if ($extraResult = $conn->store_result()) {
                $extraResult->free();
            }
        }
    }
} else {
    echo "Error: " . $conn->error;
}

$peakDay = '';
$peakDayCrimes = 0;
$peakHour = '';
$peakHourCrimes = 0;

if ($conn->multi_query("CALL getPeakCrimeTime()")) {
    if ($result = $conn->store_result()) {
        $row = $result->fetch_assoc();
        $peakDay = $row['Peak Day'];
        $peakDayCrimes = $row['Total Crimes'];
        $_SESSION['peakDay'] = $peakDay;
        $_SESSION['peakDayCrimes'] = $peakDayCrimes;
        $result->free();
    }
    if ($conn->more_results() && $conn->next_result()) {
        if ($result = $conn->store_result()) {
            $row = $result->fetch_assoc();
            $peakHour = $row['Peak Hour'];
            $peakHourCrimes = $row['Total Crimes'];
            $_SESSION['peakHour'] = $peakHour;
            $_SESSION['peakHourCrimes'] = $peakHourCrimes;
            $result->free();
        }
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}

$dayCrimeStats = [];

if ($conn->multi_query("CALL getCrimeByDayOfWeek();")) {
    if ($result = $conn->store_result()) {
        while ($row = $result->fetch_assoc()) {
            $dayCrimeStats[] = $row;
            $_SESSION['dayCrimeStats'] = $dayCrimeStats;
        }
        $result->free();
    }
    while ($conn->more_results() && $conn->next_result()) {
        if ($extraResult = $conn->store_result()) {
            $extraResult->free();
        }
    }
}

header("Location: ../temp/dashboard.php");
exit();
