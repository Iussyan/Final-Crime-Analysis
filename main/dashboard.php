<?php include "../secure/connection.php"; ?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Dashboard</title>
    <link rel="stylesheet" href="../styles/css/bootstrap.min.css">
    <link rel="stylesheet" href="../styles/styles.css">
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
    <nav id="sidebarMenu" class="collapse d-lg-block sidebar collapse bg-white">
        <h1>CHARM</h1>
        <ul>
            <li>
                <span class="logo">CHARM</span>
                <button id="toggle-btn">
                </button>
            </li>
            <li><a href="dashboard.php"><img src="../src/icons/home.svg" alt="Home Icon"><span>Dashboard</span></a></li> <!-- Link to the dashboard page -->
            <li><a href="crime_data.php"><img src="../src/icons/crime.svg" alt="Crime Icon"><span>Crime Data</span></a></li> <!-- Data entry functionality -->
            <li><a href="crime_analysis.php"><img src="../src/icons/analytics.svg" alt="Analytics Icon"><span>Crime Analysis</span></a></li> <!-- Analytical tools for crime trends -->
            <li><a href="crime_mapping.php"><img src="../src/icons/map.svg" alt="Map Icon"><span>Crime Mapping</span></a></li> <!-- Visualization of crime locations -->
            <li><a href="manage_users.php"><img src="../src/icons/groups.svg" alt="Group Icon"><span>Manage Users</span></a></li> <!-- User management for admin -->
            <li>
                <button class="dropdown-btn">
                    <img src="../src/icons/book.svg" alt="Book Icon">
                    <span>Manual</span>
                </button>
                <ul class="sub-menu">
                    <li><a href="user_manual.php"><span>User Manual</span></a></li>
                </ul>
            </li> <!-- Documentation or help guide -->
            <li><a href="contact.php"><img src="../src/icons/contact.svg" alt="Contact Icon"><span>Contact Us</span></a></li> <!-- Support or contact information -->
            <li><a href="logout.php"><img src="../src/icons/logout.svg" alt="Logout Icon"><span>Logout</span></a></li> <!-- Logout functionality -->
        </ul>
    </nav>
    <main>
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
    </main>
    <script src="../styles/js/bootstrap.bundle.min.js"></script>
</body>

</html>