<?php
session_start();
include "../secure/connection.php"; // Include the database connection file 
// Generate CSRF token
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
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
    <title>Encode Data</title>
    <link rel="stylesheet" href="../secure/apis/leaflet/leaflet.css" crossorigin="" />
    <script src="../secure/apis/leaflet/leaflet.js" crossorigin=""></script>
    <link rel="stylesheet" href="../styles/styles.css"> <!-- Optional: Link to a CSS file -->
    <style>
        #importFormContainer {
            display: none;
            margin-top: 20px;
            padding: 10px;
            border: 1px solid #ccc;
        }

        .import-result {
            margin-top: 15px;
            padding: 10px;
            border: 1px solid green;
            background-color: #e7ffe7;
        }

        #map-container {
            width: 100%;
            max-width: 1200px;
            margin: 0;
            display: none;
            /* center if needed */
        }

        #map {
            width: 100%;
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
    </style>
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
        </ul>
    </nav>

    <div>
        <!--
         * Add Crime Data Form
         * This form is hidden by default and is displayed when the user clicks the Add button.
        -->
        <div>
            <button onclick="toggleImportForm()">📂 Import CSV</button>
            <div id="importFormContainer">
                <h3>Import CSV to Database</h3>
                <form action="../secure/import_csv.php" id="importForm" method="POST" enctype="multipart/form-data">
                    <label>Select Table:</label><br>
                    <select name="table_name" required>
                        <option value="">-- Choose Table --</option>
                        <?php foreach ($tables as $tbl): ?>
                            <option value="<?= htmlspecialchars($tbl) ?>"><?= htmlspecialchars($tbl) ?></option>
                        <?php endforeach; ?>
                    </select><br><br>

                    <label>Select CSV File:</label><br>
                    <input type="file" name="csv_file" accept=".csv" required><br><br>

                    <input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">
                    <button type="submit">Upload & Import</button>
                </form>

                <div id="importResult" class="import-result" style="display:none;"></div>
            </div>
            <script>
                function toggleImportForm() {
                    const formContainer = document.getElementById('importFormContainer');
                    formContainer.style.display = formContainer.style.display === 'block' ? 'none' : 'block';
                }
            </script>
            <div id="map-container">
                <div id="map">
                    <script src="../javascript/crime_data/map.js"></script>
                    <script src="../javascript/crime_data/map-controls.js"></script>
                    <script src="../javascript/crime_data/street-layer.js"></script>
                </div>
            </div>
            <button id="addButton">Add Crime Data</button>
            <div id="addForm" style="display: none;">
                <form action="../secure/add_crime_data.php" method="POST">
                    <!-- STREET MAP -->
                    <button type="button" id="toggleMapBtn">Select a Street</button>
                    <!-- Display -->
                    <p><strong>Selected Street:</strong> <span id="selected-street-name">None</span></p>
                    <p><strong>Selected Street's ID:</strong> <span id="selected-street-id">None</span></p>

                    <!-- Hidden input fields for submission -->
                    <input type="hidden" id="selectedStreetName" name="selectedStreetName">
                    <input type="hidden" id="selectedStreetId" name="selectedStreetId">
                    <input type="hidden" id="crimeLocation" name="crimeLocation">

                    <!-- CATEGORY DROPDOWN -->
                    <label for="category">Category:</label>
                    <select id="category" name="category" required>
                        <option value="">-- Select Category --</option>
                        <option value="Violence">Violence</option>
                        <option value="Theft">Theft</option>
                        <option value="Vandalism">Vandalism</option>
                        <option value="Drug Activity">Drug Activity</option>
                        <option value="Traffic">Traffic Offense</option>
                        <option value="Disturbance">Disturbance</option>
                        <option value="Suspicious">Suspicious Activity</option>
                        <option value="Environmental">Environmental Issue</option>
                        <option value="Domestic Dispute">Domestic Disturbance</option>
                    </select>

                    <br><br>

                    <!-- CRIME DROPDOWN (dynamically populated) -->
                    <label for="crime">Crime Type:</label>
                    <select id="crime" name="crime" required disabled>
                        <option value="">-- Select a Crime --</option>
                    </select>
                    <span id="crime-error" style="color:red; display:none;">Please select a valid crime type.</span>
                    <br><br>

                    <script>
                        // Crime types mapped by category
                        const categoryToCrimes = {
                            "Theft": [
                                "Pickpocketing",
                                "Bag Snatching",
                                "Bike Theft",
                                "Car Theft",
                                "Car Break-in",
                                "Tool Theft",
                                "ATM Theft",
                                "Shoplifting",
                                "Home Burglary",
                                "Gas Siphoning"
                            ],
                            "Violence": [
                                "Street Fight",
                                "Mugging",
                                "Assault",
                                "Group Brawl",
                                "Verbal Threats",
                                "Weapon Display",
                                "Domestic Assault",
                                "Sexual Assault",
                                "Robbery with Violence",
                                "Armed Confrontation"
                            ],
                            "Vandalism": [
                                "Graffiti",
                                "Broken Streetlight",
                                "Damaged Road Sign",
                                "Shattered Window",
                                "Fence Damage",
                                "Public Property Damage",
                                "Spray Painting Private Property",
                                "Slashed Tires",
                                "Damaged Bus Stop",
                                "Vandalized Playground Equipment"
                            ],
                            "Drug Activity": [
                                "Public Drug Use",
                                "Drug Transaction",
                                "Drug Paraphernalia Found",
                                "Suspected Drug House",
                                "Needles Found in Public Area",
                                "Odor of Drugs",
                                "Drug Dealing Near School",
                                "Overdose Incident"
                            ],
                            "Traffic": [
                                "Reckless Driving",
                                "Hit and Run",
                                "Illegal Parking",
                                "Blocking Driveway",
                                "Street Racing",
                                "Wrong Way Driving",
                                "Running Red Light",
                                "Speeding in Residential Area",
                                "Driving Without Headlights",
                                "Failure to Yield"
                            ],
                            "Disturbance": [
                                "Noise Complaint",
                                "Public Intoxication",
                                "Loitering",
                                "Street Harassment",
                                "Fireworks in Street",
                                "Unruly Crowd",
                                "Blocking Pedestrian Path",
                                "Disorderly Conduct",
                                "Shouting Matches",
                                "Rowdy Behavior at Night"
                            ],
                            "Suspicious": [
                                "Suspicious Person",
                                "Suspicious Vehicle",
                                "Unattended Package",
                                "Unknown Person Peering into Cars",
                                "Person Hiding Behind Bushes",
                                "Repeated Door Knocking",
                                "Drone Hovering at Night",
                                "Person with Binoculars"
                            ],
                            "Environmental": [
                                "Illegal Dumping",
                                "Littering",
                                "Open Manhole",
                                "Flooded Street",
                                "Downed Power Line",
                                "Dead Animal in Street",
                                "Blocked Storm Drain",
                                "Overflowing Trash Can",
                                "Leaking Fire Hydrant",
                                "Hazardous Waste Found"
                            ],
                            "Domestic Dispute": [
                                "Yelling Heard from House",
                                "Fight in Front Yard",
                                "Ongoing Argument in Street",
                                "Throwing Objects Outside Home",
                                "Loud Screaming Indoors",
                                "Police Called to Residence",
                                "Suspected Child Abuse",
                                "Verbal Abuse in Public"
                            ]
                        };

                        const categorySelect = document.getElementById('category');
                        const crimeSelect = document.getElementById('crime');
                        const crimeError = document.getElementById('crime-error');

                        // When category changes, populate crime types
                        categorySelect.addEventListener('change', function() {
                            const category = this.value;
                            crimeSelect.innerHTML = '<option value="">-- Select a Crime --</option>';

                            if (category && categoryToCrimes[category]) {
                                categoryToCrimes[category].forEach(crime => {
                                    const opt = document.createElement('option');
                                    opt.textContent = crime;
                                    crimeSelect.appendChild(opt);
                                });
                                crimeSelect.disabled = false;
                            } else {
                                crimeSelect.disabled = true;
                            }

                            crimeError.style.display = 'none'; // Hide error when category changes
                        });
                    </script>

                    <script>
                        const toggleBtn = document.getElementById('toggleMapBtn');
                        const mapContainer = document.getElementById('map-container');
                        mapContainer.style.display = 'none'; // Initially hidden

                        toggleBtn.addEventListener('click', function() {
                            const isHidden = mapContainer.style.display === 'none';
                            mapContainer.style.display = isHidden ? 'block' : 'none';
                            toggleBtn.textContent = isHidden ? 'Hide Map' : 'Select a Street';

                            if (isHidden && typeof map !== 'undefined') {
                                setTimeout(() => map.invalidateSize(), 200); // Ensures map renders correctly
                            }
                        });
                    </script>

                    <label for="address">Address:</label>
                    <input type="text" id="address" name="address" required><br>

                    <label for="date">Date:</label>
                    <input type="date" id="date" name="date" max="<?= date('Y-m-d') ?>" required><br>

                    <label for="time">Time:</label>
                    <input type="time" id="time" name="time" required><br>

                    <label for="description">Crime Description:</label>
                    <textarea id="description" name="description" required></textarea><br>

                    <label for="witness_name">Witness' Name:</label>
                    <input type="text" id="witness_name" name="witness_name" required><br>

                    <label for="witness_age">Witness' Age:</label>
                    <input type="number" id="witness_age" name="witness_age" required><br>

                    <label for="witness_sex">Witness' Sex:</label>
                    <select id="witness_sex" name="witness_sex" required>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                    </select><br>

                    <label for="contact_number">(Optional) Contact Number:</label>
                    <input type="text" id="contact_number" name="contact_number"><br>

                    <button type="submit">Submit</button>
                </form>
            </div>

            <script>
                document.getElementById('addButton').addEventListener('click', function() {
                    const form = document.getElementById('addForm');
                    form.style.display = form.style.display === 'none' ? 'block' : 'none';
                });
            </script>
        </div>

        <table border="1">
            <thead>
                <tr>
                    <th colspan="20">Incident Reports</th>
                </tr>
                <tr>
                    <?php
                    // Fetch column names dynamically
                    $query = "SHOW COLUMNS FROM `vw_incident_report`"; // Replace 'crime_data' with your table name
                    $result = mysqli_query($conn, $query);
                    while ($column = mysqli_fetch_assoc($result)) {
                        echo "<th>" . htmlspecialchars($column['Field']) . "</th>";
                    }
                    ?>
                </tr>
            </thead>
            <tbody>
                <?php
                // Fetch rows dynamically
                $query = "SELECT * FROM `vw_incident_report`"; // Replace 'crime_data' with your table name
                $result = mysqli_query($conn, $query);
                while ($row = mysqli_fetch_assoc($result)) {
                    echo "<tr>";
                    foreach ($row as $cell) {
                        echo "<td>" . htmlspecialchars($cell) . "</td>";
                    }
                    echo "</tr>";
                }
                ?>
            </tbody>
        </table>
    </div>
</body>

</html>