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
                
                <label for="crime_type">Crime Type:</label>
                <select id="crime_type" name="crime_type">
                    <option value="all">All</option>
                    <option value="theft">Theft</option>
                    <option value="assault">Assault</option>
                    <option value="burglary">Burglary</option>
                    <option value="fraud">Fraud</option>
                </select>
                
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