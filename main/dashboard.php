<?php include "../secure/connection.php"; ?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
</head>

<body>
    <nav>
        <h1>CHARM</h1>
        <ul>
            <li><a href="dashboard.php">Dashboard</a></li> <!-- Link to the dashboard page -->
            <li><a href="crime_data.php">Crime Data</a></li> <!-- Data entry functionality -->
            <li><a href="crime_analysis.php">Crime Analysis</a></li> <!-- Analytical tools for crime trends -->
            <li><a href="crime_mapping.php">Crime Mapping</a></li> <!-- Visualization of crime locations -->
            <li><a href="manage_users.php">Manage Users</a></li> <!-- User management for admin -->
            <li><a href="user_manual.php">User Manual</a></li> <!-- Documentation or help guide -->
            <li><a href="contact.php">Contact Us</a></li> <!-- Support or contact information -->
            <li><a href="logout.php">Logout</a></li> <!-- Logout functionality -->
            <li><a href="svg_converter.php">SVG Converter</a></li> <!-- Link to the SVG Converter -->
        </ul>
    </nav>
    <div>
        <div>
            <h1>Dashboard</h1>
        </div>
        <div>
            <h2>Total Crimes</h2>
            <?php
            /*
        $query = "SELECT COUNT(*) as total_crimes FROM crimes";
        $result = $conn->query($query);

        if ($result->num_rows > 0) {
            echo "<table border='1'>";
            echo "<tr><th>Total Crimes</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['total_crimes'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No crime data available.</p>";
        }
        */
            ?>
        </div>

        <div>
            <h2>Crime Hotspot</h2>
            <?php
            /*
        $query = "SELECT location, COUNT(*) as crime_count FROM crimes GROUP BY location ORDER BY crime_count DESC LIMIT 5";
        $result = $conn->query($query);

        if ($result->num_rows > 0) {
            echo "<table border='1'>";
            echo "<tr><th>Location</th><th>Crime Count</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['location'] . "</td><td>" . $row['crime_count'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No crime data available.</p>";
        }
        */
            ?>
        </div>

        <div>
            <h2>Monthly Crime Rate</h2>
            <?php
            /*
        $query = "SELECT MONTHNAME(date) as month, COUNT(*) as crime_count FROM crimes GROUP BY MONTH(date)";
        $result = $conn->query($query);

        if ($result->num_rows > 0) {
            echo "<table border='1'>";
            echo "<tr><th>Month</th><th>Crime Count</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['month'] . "</td><td>" . $row['crime_count'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No crime data available.</p>";
        }
        */
            ?>
        </div>

        <div>
            <h2>Frequent Crimes</h2>
            <?php
            /*
        $query = "SELECT crime_type, COUNT(*) as crime_count FROM crimes GROUP BY crime_type ORDER BY crime_count DESC LIMIT 5";
        $result = $conn->query($query);

        if ($result->num_rows > 0) {
            echo "<table border='1'>";
            echo "<tr><th>Crime Type</th><th>Crime Count</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['crime_type'] . "</td><td>" . $row['crime_count'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No crime data available.</p>";
        }
        */
            ?>
        </div>

        <div>
            <h2>Index & Non-Index Crimes</h2>
            <?php
            /*
        $query = "SELECT crime_type, COUNT(*) as crime_count FROM crimes WHERE crime_type IN ('Index', 'Non-Index') GROUP BY crime_type";
        $result = $conn->query($query);

        if ($result->num_rows > 0) {
            echo "<table border='1'>";
            echo "<tr><th>Crime Type</th><th>Crime Count</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['crime_type'] . "</td><td>" . $row['crime_count'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No crime data available.</p>";
        }
        */
            // comment all of the query and result code blocks. DON'T comment as if you're explaining what they do. Comment the codeblocks themselves, respectively.
            ?>
        </div>
    </div>
</body>

</html>