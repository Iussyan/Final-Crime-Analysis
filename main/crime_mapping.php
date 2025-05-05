<?php
include "../secure/connection.php";
$tables = [];
$res = $conn->query("SHOW TABLES");
while ($row = $res->fetch_array()) {
    $tables[] = $row[0];
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="../secure/apis/leaflet/leaflet.css" crossorigin="" />
    <script src="../secure/apis/leaflet/leaflet.js" crossorigin=""></script>
    <script src="https://unpkg.com/leaflet.heat/dist/leaflet-heat.js"></script>
    <script src="https://unpkg.com/@turf/turf@6.5.0/turf.min.js"></script>
    <title>Crime Mapping</title>
    <link rel="stylesheet" href="../styles/styles.css"> <!-- Link to your CSS file -->
    <style>
        #map-container {
            width: 100%;
            max-width: 1200px;
            margin: 0;
            display: none;
            /* center if needed */
        }

        #map {
            width: 55%;
            aspect-ratio: 3 / 2;
            border: 2px solid #ccc;
            border-radius: 8px;
        }

        .autocomplete-active {
            background-color: #e0f0ff;
        }

        #uploadFormContainer {
            display: none;
            margin-top: 20px;
            padding: 10px;
            border: 1px solid #ccc;
            background: #f9f9f9;
        }

        #address {
            width: 200px;
            padding: 3px;
            font-size: 12px;
        }

        button {
            cursor: pointer;
        }

        .map-button {
            background-color: white;
            border: 1px solid #ccc;
            border-radius: 4px;
            padding: 4px;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.2);
            transition: background-color 0.2s ease, box-shadow 0.2s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }

        .map-button img {
            display: block;
            max-width: 100%;
            max-height: 100%;
        }

        .map-button:hover {
            background-color: #f0f0f0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
        }

        .map-button:active {
            background-color: #e0e0e0;
            box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.3);
        }

        /* Modal backdrop */
        .modal {
            display: none;
            position: fixed;
            z-index: 9999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0, 0, 0, 0.6);
        }

        /* Modal content box */
        .modal-content {
            background-color: #fefefe;
            margin: 10% auto;
            padding: 20px;
            border-radius: 8px;
            width: 70%;
            max-width: 600px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.4);
        }

        /* Close button */
        .close {
            float: right;
            font-size: 24px;
            font-weight: bold;
            cursor: pointer;
        }
    </style>
</head>

<body>
    <nav>
        <h1>CHARM</h1>
        <ul>
            <li><a href="dashboard.php"><img src="../src/icons/home.svg" alt="Home Icon"><span>Dashboard</span></a></li> <!-- Link to the dashboard page -->
            <li><a href="crime_data.php"><img src="../src/icons/crime.svg" alt="Crime Icon"><span>Crime Data</span></a></li> <!-- Data entry functionality -->
            <li><a href="crime_analysis.php"><img src="../src/icons/analytics.svg" alt="Analytics Icon"><span>Crime Analysis</span></a></li> <!-- Analytical tools for crime trends -->
            <li><a href="crime_mapping.php"><span>Crime Mapping</span></a></li> <!-- Visualization of crime locations -->
            <li><a href="manage_users.php"><span>Manage Users</span></a></li> <!-- User management for admin -->
            <li><a href="user_manual.php"><span>User Manual</span></a></li> <!-- Documentation or help guide -->
            <li><a href="contact.php"><span>Contact Us</span></a></li> <!-- Support or contact information -->
            <li><a href="logout.php"><span>Logout</span></a></li> <!-- Logout functionality -->
        </ul>
    </nav>
    <header>
        <h1>Crime Mapping</h1>
    </header>
    <button id="toggleUploadForm">Upload .GeoJSON file</button>

    <div id="uploadFormContainer">
        <h2>Upload GeoJSON to MySQL</h2>
        <form action="../secure/process_file.php" method="post" enctype="multipart/form-data">
            <label>MySQL Host:</label>
            <input type="text" name="host" placeholder="Enter host.." value="localhost" required><br><br>

            <label>Username:</label>
            <input type="text" name="username" placeholder="Enter username.." value="root" required><br><br>

            <label>Password:</label>
            <input type="password" name="password" placeholder="Enter password.."><br><br>

            <label>Database Name:</label>
            <input type="text" name="dbname" placeholder="Enter database.." required><br><br>

            <label>Select Table:</label><br>
            <select name="table" required>
                <option value="">-- Choose Table --</option>
                <?php foreach ($tables as $tbl): ?>
                    <option value="<?= htmlspecialchars($tbl) ?>"><?= htmlspecialchars($tbl) ?></option>
                <?php endforeach; ?>
            </select><br><br>

            <label>GeoJSON File:</label>
            <input type="file" name="geojson" accept=".geojson" required><br><br>

            <button type="submit">Upload and Import</button>
        </form>
    </div>

    <script>
        const toggleBtn = document.getElementById('toggleUploadForm');
        const formContainer = document.getElementById('uploadFormContainer');

        toggleBtn.addEventListener('click', () => {
            const visible = formContainer.style.display === 'block';
            formContainer.style.display = visible ? 'none' : 'block';
            toggleBtn.textContent = visible ? 'Upload .GeoJSON file' : 'Upload .GeoJSON file';
        });
    </script>

    <div id="map">
        <script src="../javascript/map.js"></script>
        <script src="../javascript/crime-layer.js"></script>
        <script src="../javascript/street-layer.js"></script>
        <script src="../javascript/heatmap-layer.js"></script>
        <script src="../javascript/map-controls.js"></script>
        <script src="../javascript/modals.js"></script>
    </div>
    <!-- Modal Container -->
    <div id="incidentModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; overflow:auto; background-color:rgba(0,0,0,0.4);">
        <div class="modal-content" style="background-color:#fff; margin:10% auto; padding:20px; border:1px solid #888; width:80%; max-width:600px; border-radius:8px; position:relative;">
            <span id="closeModalBtn" style="color:#aaa; position:absolute; top:10px; right:15px; font-size:28px; font-weight:bold; cursor:pointer;">&times;</span>
            <h2 id="modalTitle">Incident Data</h2>
            <div id="modalBody">
                <p><strong>Loading incident data...</strong></p>
            </div>
        </div>
    </div>
</body>

</html>