<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crime Analysis</title>
    <link rel="stylesheet" href="../styles/styles.css"> <!-- Link to your CSS file -->
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
    <main>
        <h2>Crime Analysis</h2>
        <p>Welcome to the Crime Analysis page. Here, you can analyze crime trends and patterns using the tools provided below.</p>

        <section>
            <h3>Crime Trends</h3>
            <form method="POST" action="analyze_trends.php">
                <label for="start_date">Start Date:</label>
                <input type="date" id="start_date" name="start_date" required>

                <label for="end_date">End Date:</label>
                <input type="date" id="end_date" name="end_date" required>

                <label for="crime-form">Crime</label>
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

                    // On submit, validate that a crime is selected
                    document.getElementById('crime-form').addEventListener('submit', function(e) {
                        if (!crimeSelect.value) {
                            e.preventDefault();
                            crimeError.style.display = 'inline';
                        } else {
                            crimeError.style.display = 'none';
                        }
                    });
                </script>

                <button type="submit">Analyze</button>
            </form>
        </section>

        <section>
            <h3>Crime Statistics</h3>
            <p>Below is a summary of crime statistics:</p>
            <?php
            // Example PHP code to fetch and display crime statistics
            // Replace with actual database queries and logic
            $crime_stats = [
                'Total Crimes' => 1200,
                'Theft' => 450,
                'Assault' => 300,
                'Burglary' => 200,
                'Fraud' => 250
            ];
            ?>
            <table>
                <thead>
                    <tr>
                        <th>Crime Type</th>
                        <th>Count</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($crime_stats as $type => $count): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($type); ?></td>
                            <td><?php echo htmlspecialchars($count); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>
    </main>
</body>

</html>