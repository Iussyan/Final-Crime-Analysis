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
                    <script>
                        // Add a GeoJSON layer to the map
                        var geojsonData = {
                            "type": "FeatureCollection",
                            "generator": "overpass-turbo",
                            "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL.",
                            "timestamp": "2025-04-16T11:57:45Z",
                            "features": [{
                                    "type": "Feature",
                                    "properties": {
                                        "@id": "relation/271002",
                                        "admin_level": "10",
                                        "boundary": "administrative",
                                        "name": "San Bartolome",
                                        "postal_code": "1116",
                                        "ref": "137404097",
                                        "type": "boundary"
                                    },
                                    "geometry": {
                                        "type": "Polygon",
                                        "coordinates": [
                                            [
                                                [121.0262578, 14.7165558],
                                                [121.0262522, 14.7165584],
                                                [121.0258231, 14.7167559],
                                                [121.0253098, 14.7168501],
                                                [121.0251415, 14.7168735],
                                                [121.0250607, 14.7168291],
                                                [121.0249346, 14.716728],
                                                [121.0246889, 14.7164617],
                                                [121.0245484, 14.7163751],
                                                [121.0244626, 14.7163544],
                                                [121.0243501, 14.7163864],
                                                [121.0240012, 14.7165438],
                                                [121.0238292, 14.7165845],
                                                [121.0235981, 14.7166319],
                                                [121.0234165, 14.7165983],
                                                [121.0233199, 14.7164524],
                                                [121.0232288, 14.7163362],
                                                [121.0231121, 14.7162296],
                                                [121.0226633, 14.7159795],
                                                [121.0222306, 14.7157714],
                                                [121.0221755, 14.7157449],
                                                [121.0220137, 14.7156073],
                                                [121.0219202, 14.7154007],
                                                [121.0218662, 14.7151714],
                                                [121.0217992, 14.7147901],
                                                [121.0217817, 14.7144236],
                                                [121.0217616, 14.7140793],
                                                [121.0217375, 14.7138769],
                                                [121.0216409, 14.7134592],
                                                [121.0214748, 14.7129387],
                                                [121.0213943, 14.7127752],
                                                [121.0212844, 14.7126611],
                                                [121.0210365, 14.7125168],
                                                [121.0207591, 14.7123378],
                                                [121.0203095, 14.7120758],
                                                [121.0200982, 14.7120057],
                                                [121.019994, 14.712009],
                                                [121.0198659, 14.7120799],
                                                [121.0197519, 14.7121595],
                                                [121.0196051, 14.7122711],
                                                [121.0193949, 14.7123653],
                                                [121.0191632, 14.7123912],
                                                [121.0189148, 14.7123876],
                                                [121.0186492, 14.7123497],
                                                [121.0185027, 14.7122529],
                                                [121.0182083, 14.7120395],
                                                [121.0180436, 14.7118786],
                                                [121.0178509, 14.7115213],
                                                [121.0176605, 14.7111685],
                                                [121.0175941, 14.7108606],
                                                [121.0175281, 14.7105281],
                                                [121.0175394, 14.710322],
                                                [121.0176712, 14.7096067],
                                                [121.017741, 14.709215],
                                                [121.0178876, 14.7089756],
                                                [121.0181616, 14.7085435],
                                                [121.0184781, 14.7081626],
                                                [121.0186037, 14.7077371],
                                                [121.0187461, 14.707226],
                                                [121.0187763, 14.7067089],
                                                [121.0186818, 14.7063528],
                                                [121.0185853, 14.7061724],
                                                [121.0185235, 14.7060567],
                                                [121.0183435, 14.7058103],
                                                [121.0179572, 14.7053257],
                                                [121.0177571, 14.705007],
                                                [121.0176421, 14.7046522],
                                                [121.0176202, 14.7044518],
                                                [121.0176894, 14.7041657],
                                                [121.0178415, 14.7038966],
                                                [121.0179046, 14.7037773],
                                                [121.0179575, 14.7036261],
                                                [121.0179622, 14.7035126],
                                                [121.0179256, 14.7034017],
                                                [121.0183128, 14.7035215],
                                                [121.0185081, 14.7036019],
                                                [121.0187187, 14.703518],
                                                [121.0189913, 14.7033725],
                                                [121.0194321, 14.7034971],
                                                [121.0198579, 14.7036248],
                                                [121.0200902, 14.7036547],
                                                [121.0205025, 14.7037499],
                                                [121.020747, 14.7038084],
                                                [121.0210019, 14.7038702],
                                                [121.0213328, 14.7039074],
                                                [121.0221108, 14.7038071],
                                                [121.0222216, 14.7036709],
                                                [121.0224269, 14.7030731],
                                                [121.0226614, 14.7024115],
                                                [121.0235882, 14.7023361],
                                                [121.0244882, 14.7022582],
                                                [121.0250886, 14.7022745],
                                                [121.0260183, 14.702268],
                                                [121.0260003, 14.7021657],
                                                [121.0263227, 14.7017582],
                                                [121.026434, 14.701849],
                                                [121.0265272, 14.7017354],
                                                [121.026972, 14.7011391],
                                                [121.0270976, 14.7006934],
                                                [121.0275992, 14.7005645],
                                                [121.0276272, 14.7003574],
                                                [121.0277396, 14.7002343],
                                                [121.0277865, 14.7002296],
                                                [121.0278093, 14.7002729],
                                                [121.0282816, 14.7002994],
                                                [121.0283223, 14.700203],
                                                [121.0282925, 14.7000479],
                                                [121.0288833, 14.6991261],
                                                [121.0292419, 14.6991672],
                                                [121.0294994, 14.6992585],
                                                [121.0305294, 14.6990012],
                                                [121.0308073, 14.6990593],
                                                [121.0307925, 14.6993818],
                                                [121.0313062, 14.6993467],
                                                [121.031742, 14.6993117],
                                                [121.0321595, 14.6994207],
                                                [121.0323774, 14.6992339],
                                                [121.0325253, 14.6992806],
                                                [121.0325111, 14.6995945],
                                                [121.0325398, 14.699613],
                                                [121.0327372, 14.6997469],
                                                [121.0328767, 14.6998208],
                                                [121.032988, 14.6998506],
                                                [121.0331061, 14.6998306],
                                                [121.0333293, 14.6997813],
                                                [121.0336237, 14.6998247],
                                                [121.0336968, 14.6998694],
                                                [121.033853, 14.6998643],
                                                [121.0339308, 14.6998325],
                                                [121.0344328, 14.69978],
                                                [121.0345356, 14.6996659],
                                                [121.0348171, 14.6998662],
                                                [121.0354332, 14.6995803],
                                                [121.0355857, 14.6994939],
                                                [121.0357553, 14.6991521],
                                                [121.0365931, 14.6993031],
                                                [121.0370751, 14.699396],
                                                [121.0373931, 14.6994582],
                                                [121.0379717, 14.6995824],
                                                [121.0387131, 14.6997286],
                                                [121.0393129, 14.6995139],
                                                [121.0397754, 14.6993584],
                                                [121.0398597, 14.6996087],
                                                [121.0399299, 14.6995906],
                                                [121.0407785, 14.6999041],
                                                [121.0407691, 14.6998886],
                                                [121.0409944, 14.6997939],
                                                [121.0410108, 14.6998224],
                                                [121.0411308, 14.6997855],
                                                [121.0412733, 14.6997679],
                                                [121.0413825, 14.6997748],
                                                [121.0414314, 14.6997848],
                                                [121.0415434, 14.6994038],
                                                [121.0415627, 14.6993029],
                                                [121.0416468, 14.699179],
                                                [121.0416877, 14.6991852],
                                                [121.0417394, 14.6991287],
                                                [121.0418215, 14.6990399],
                                                [121.0418792, 14.6989406],
                                                [121.0419529, 14.6988521],
                                                [121.0421053, 14.6986468],
                                                [121.0422597, 14.6986306],
                                                [121.0422812, 14.6986556],
                                                [121.0424227, 14.6986614],
                                                [121.0424255, 14.6986673],
                                                [121.0424637, 14.6986663],
                                                [121.0424656, 14.6986572],
                                                [121.0426982, 14.6986643],
                                                [121.0427153, 14.6986741],
                                                [121.0427824, 14.6986724],
                                                [121.0427837, 14.6986497],
                                                [121.0431167, 14.6986514],
                                                [121.0431515, 14.6986611],
                                                [121.0433011, 14.698652],
                                                [121.0433514, 14.6986313],
                                                [121.0436138, 14.6986107],
                                                [121.0441829, 14.6991949],
                                                [121.0441051, 14.6995388],
                                                [121.0446816, 14.6997015],
                                                [121.044619, 14.6997946],
                                                [121.0461093, 14.7005706],
                                                [121.0463122, 14.7004619],
                                                [121.0466552, 14.7002382],
                                                [121.0467675, 14.7001516],
                                                [121.046796, 14.7001571],
                                                [121.0469247, 14.7000744],
                                                [121.047023, 14.7000105],
                                                [121.0470488, 14.7000459],
                                                [121.0473673, 14.6998442],
                                                [121.0477819, 14.699577],
                                                [121.0478716, 14.6996619],
                                                [121.04784, 14.6997034],
                                                [121.0481951, 14.7000245],
                                                [121.0482555, 14.7001496],
                                                [121.0482145, 14.7003011],
                                                [121.0482001, 14.700327],
                                                [121.0481512, 14.700509],
                                                [121.0480431, 14.7009135],
                                                [121.0474598, 14.7016375],
                                                [121.0474518, 14.7016682],
                                                [121.0473914, 14.7017527],
                                                [121.047323, 14.7018754],
                                                [121.0473177, 14.7021156],
                                                [121.0473405, 14.7021201],
                                                [121.0473664, 14.7023599],
                                                [121.0477384, 14.7024721],
                                                [121.047897, 14.7023954],
                                                [121.0475163, 14.7032275],
                                                [121.0468517, 14.7033249],
                                                [121.0467778, 14.7040567],
                                                [121.0455003, 14.704594],
                                                [121.0454888, 14.7052707],
                                                [121.0440479, 14.7052824],
                                                [121.0419812, 14.7052453],
                                                [121.0418078, 14.7058151],
                                                [121.0415217, 14.7066561],
                                                [121.0415248, 14.7075016],
                                                [121.0401844, 14.7080705],
                                                [121.0400809, 14.7080861],
                                                [121.0396347, 14.7080226],
                                                [121.0389081, 14.7083563],
                                                [121.0387662, 14.7084187],
                                                [121.0387608, 14.708583],
                                                [121.0384375, 14.7090308],
                                                [121.03848, 14.7091378],
                                                [121.0384845, 14.709263],
                                                [121.0382147, 14.7094565],
                                                [121.0375888, 14.709336],
                                                [121.0372903, 14.7091637],
                                                [121.03699, 14.7091458],
                                                [121.036688, 14.7089056],
                                                [121.0366244, 14.7089794],
                                                [121.0364442, 14.709162],
                                                [121.0363582, 14.7092669],
                                                [121.0362553, 14.7093446],
                                                [121.0350814, 14.7094277],
                                                [121.0345597, 14.7094757],
                                                [121.0339713, 14.7095436],
                                                [121.0338342, 14.709774],
                                                [121.033562, 14.7101886],
                                                [121.0335323, 14.710492],
                                                [121.0331848, 14.7105806],
                                                [121.0328912, 14.7106831],
                                                [121.0325778, 14.7107582],
                                                [121.0323155, 14.710777],
                                                [121.032077, 14.7107634],
                                                [121.0316378, 14.7106994],
                                                [121.0312412, 14.7104529],
                                                [121.0311279, 14.7104447],
                                                [121.030941, 14.710524],
                                                [121.0309143, 14.7105568],
                                                [121.0308952, 14.7106455],
                                                [121.0308448, 14.7108677],
                                                [121.03083, 14.71103],
                                                [121.0308498, 14.7113243],
                                                [121.0308177, 14.7115253],
                                                [121.0304332, 14.7119779],
                                                [121.0302602, 14.7121841],
                                                [121.0302126, 14.7123197],
                                                [121.0301489, 14.7125032],
                                                [121.0301301, 14.7127069],
                                                [121.0301154, 14.7128937],
                                                [121.0300577, 14.7130836],
                                                [121.0298619, 14.7134619],
                                                [121.0294864, 14.7141586],
                                                [121.0293449, 14.7144433],
                                                [121.0293087, 14.7147728],
                                                [121.0291542, 14.7153668],
                                                [121.0290138, 14.7156003],
                                                [121.0287349, 14.7157145],
                                                [121.0283289, 14.7157662],
                                                [121.0281002, 14.7157648],
                                                [121.0279029, 14.7158203],
                                                [121.0270821, 14.7161971],
                                                [121.0266213, 14.7163382],
                                                [121.0262578, 14.7165558]
                                            ]
                                        ]
                                    },
                                    "id": "relation/271002"
                                },
                                {
                                    "type": "Feature",
                                    "properties": {
                                        "@id": "node/251004896",
                                        "@relations": [{
                                            "role": "label",
                                            "rel": 271002,
                                            "reltags": {
                                                "admin_level": "10",
                                                "boundary": "administrative",
                                                "name": "San Bartolome",
                                                "postal_code": "1116",
                                                "ref": "137404097",
                                                "type": "boundary"
                                            }
                                        }]
                                    },
                                    "id": "node/251004896"
                                }
                            ]
                        }

                        // Define the bounds for the map based on the GeoJSON polygon
                        var geojsonBounds = L.geoJSON(geojsonData).getBounds(); // Get bounds of the GeoJSON data

                        // Initialize the map with restricted zoom and bounds
                        var map = L.map('map', {
                            center: [14.7007, 121.0349], // Center the map on the GeoJSON bounds
                            zoom: 18, // Initial zoom level
                            minZoom: 16, // Minimum zoom level
                            maxZoom: 19 // Maximum zoom level
                        });

                        // Set the maximum bounds for the map to fit the GeoJSON polygon
                        map.setMaxBounds(geojsonBounds);

                        // Prevent the user from panning outside the bounds
                        map.on('drag', function() {
                            map.panInsideBounds(bounds, {
                                animate: false
                            });
                        });

                        // Add a tile layer to the map
                        L.tileLayer('https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}.jpg?key=kmDDNhXUXCZxn5Sfpecq', {
                            maxZoom: 19,
                            attribution: '© <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>'
                        }).addTo(map);

                        // Define styles for the street layer
                        const defaultStyle = {
                            color: '#3366ff',
                            weight: 3,
                            opacity: 1
                        };

                        const mouseStyle = {
                            color: '#3366ff',
                            weight: 5,
                            opacity: 1
                        };

                        const highlightStyle = {
                            color: '#ff5733',
                            weight: 4,
                            opacity: 1
                        };

                        const dimmedStyle = {
                            color: '#3366ff',
                            weight: 4,
                            opacity: 0.3
                        };

                        let activeStreet = null; // track currently highlighted layer
                        let activeMultiLine = false;
                        let activeSingleLine = false;
                        const streetIndex = [];

                        const streetLayer = L.geoJSON(null, {
                            style: feature => ({
                                color: feature.properties.name ? "#3366ff" : "#3366ff",
                                dashArray: feature.properties.name ? "none" : "4,4",
                            }),
                            onEachFeature: function(feature, layer) {
                                const props = feature.properties;
                                layer._isActive = false;
                                const displayName = props.name + (props['@id'] ? ` (${props['@id']})` : '');

                                if (props?.name || !props?.name) {
                                    if (!props?.name) {
                                        props.name = 'Unnamed Road / Street';
                                    }
                                    layer.bindPopup(() => `<div style="min-width:200px">
                                    <h4 style="margin-bottom:4px;">${props.name}</h4>
                                    <ul style="list-style:none; padding:0; margin:0; font-size: 1em;">
                                    ${props.highway ? `<li><strong>Type:</strong> ${props.highway}</li>` : ''}
                                    ${props.oneway ? `<li><strong>Oneway:</strong> ${props.oneway}</li>` : ''}
                                    ${props.old_name ? `<li><strong>Old Name:</strong> ${props.old_name}</li>` : ''}
                                    ${props["@id"] ? `<li><strong>ID:</strong> ${props["@id"]}</li>` : ''}
                                    </ul>
                                    </div>`);
                                    streetIndex.push({
                                        name: props.name,
                                        highway: props.highway,
                                        layer: layer
                                    });
                                }

                                // Hover effect
                                layer.on('mouseover', () => {
                                    if (!layer._isActive) {
                                        layer.setStyle(mouseStyle);
                                    }
                                });

                                layer.on('mouseout', () => {
                                    if (!layer._isActive && !activeMultiLine && !activeSingleLine) {
                                        layer.setStyle(defaultStyle);
                                    } else if (!layer._isActive && activeMultiLine || activeSingleLine) {
                                        if (!layer._isActive) layer.setStyle(dimmedStyle);
                                    }
                                });

                                // Click handler
                                layer.on('click', e => {
                                    e.originalEvent.stopPropagation();
                                    streetLayer.eachLayer(layer => layer.setStyle(dimmedStyle));
                                    activeSingleLine = true;

                                    layer.setStyle(highlightStyle);
                                    layer._isActive = true; // 👈 Mark this one active
                                    activeStreet = layer;

                                    map.fitBounds(layer.getBounds());
                                    layer.openPopup();

                                    const props = feature.properties;

                                    // 👇 Update the form fields
                                    document.getElementById('selected-street-name').textContent = props.name || 'Unnamed';
                                    document.getElementById('selected-street-id').textContent = props['@id'] || '';
                                    document.getElementById('selectedStreetName').value = props.name || 'Unnamed';
                                    document.getElementById('selectedStreetId').value = props['@id'] || '';

                                    // Auto-fill address by using the center of the geometry
                                    const center = layer.getBounds().getCenter();
                                    const lat = center.lat;
                                    const lng = center.lng;

                                    // Update hidden lat/lng input
                                    document.getElementById('crimeLocation').value = `${lat},${lng}`;

                                    // Reverse geocode via Nominatim
                                    fetch(`https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}`)
                                        .then(res => res.json())
                                        .then(data => {
                                            if (data.display_name) {
                                                document.getElementById('address').value = data.display_name;
                                            }
                                        })
                                        .catch(err => console.error('Reverse geocoding failed', err));

                                    // Zoom to and open popup
                                    map.fitBounds(layer.getBounds());
                                    layer.openPopup();
                                });
                            }
                        }).addTo(map);

                        // Load the GeoJSON data for streets
                        fetch('../src/san_bartolome_streets1.geojson')
                            .then(res => res.json())
                            .then(data => streetLayer.addData(data));

                        // Function to reset street styles
                        function resetStreetStyles() {
                            streetLayer.eachLayer(layer => {
                                layer._isActive = false;
                                layer.setStyle(defaultStyle);
                            });
                            activeMultiLine = false;
                            activeSingleLine = false;
                            activeStreet = null;
                            document.getElementById('street-info').textContent = '';
                        }

                        // Reset everything when clicking outside a street
                        map.on('click', function() {
                            resetStreetStyles();
                        });

                        const searchToggleControl = L.control({
                            position: 'topleft'
                        });

                        searchToggleControl.onAdd = function() {
                            const buttonContainer = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
                            buttonContainer.style.background = 'white';
                            buttonContainer.style.padding = '4px 4px 0px 4px';

                            const button = document.createElement('img');
                            button.src = '../src/images/search-streets-on.png'; // 🔁 Replace with your icon later
                            button.className = "map-button";
                            button.alt = 'Search Street';
                            button.title = 'Search Street';
                            button.style.cursor = 'pointer';
                            button.style.width = '27px';
                            button.style.height = 'auto';

                            buttonContainer.appendChild(button);

                            button.addEventListener('click', () => {
                                const searchPanel = document.getElementById('street-search-panel');
                                if (searchPanel) {
                                    searchPanel.style.display = (searchPanel.style.display === 'none') ? 'block' : 'none';
                                }
                            });

                            return buttonContainer;
                        };

                        searchToggleControl.addTo(map);

                        // Create a custom search control for streets
                        const streetSearchControl = L.control({
                            position: 'topleft'
                        });

                        streetSearchControl.onAdd = function() {
                            const outer = L.DomUtil.create('div');
                            const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom', outer);
                            outer.id = 'street-search-panel';
                            outer.style.display = 'none'; // initially hidden

                            container.style.width = '10vw';
                            container.style.background = 'white';
                            container.style.margin = "0";
                            container.style.padding = '8px';
                            container.style.boxShadow = '0 2px 6px rgba(0,0,0,0.2)';
                            container.innerHTML = `<input id="search-input" type="text" placeholder="Search street..." style="width: 96%; padding: 3px; font-size: 12px;">
                            <div id="autocomplete-list" style="background:white; border:1px solid #ccc; max-height:100px; overflow-y:auto; font-size:12px; display:none;"></div>
                            <div id="filter-options" style="font-size:12px;margin-top:6px;">
                            <label><input type="checkbox" class="type-checkbox" value="residential"> Residential</label><br>
                            <label><input type="checkbox" class="type-checkbox" value="service"> Service</label><br>
                            <label><input type="checkbox" class="type-checkbox" value="tertiary"> Tertiary</label><br>
                            <label><input type="checkbox" class="type-checkbox" value="unclassified"> Unclassified</label>
                            </div>
                            <button id="search-btn" style="margin-top:6px;width:140px;font-size:12px;display:none;">Search</button>
                            <div id="search-feedback" style="color:red;font-size:13px;margin-top:4px;"></div>`;

                            // Prevent map dragging when interacting with the control
                            L.DomEvent.disableClickPropagation(container);
                            return outer;
                        };

                        streetSearchControl.addTo(map);

                        // Create a simple autocomplete function
                        const input = document.getElementById('search-input');
                        const list = document.getElementById('autocomplete-list');
                        const filter = document.getElementById('type-filter');
                        let validSelection = false;
                        let currentFocus = -1;

                        input.addEventListener('input', function() {
                            const value = this.value.trim().toLowerCase();
                            const selectedTypes = Array.from(document.querySelectorAll('.type-checkbox:checked')).map(cb => cb.value);
                            list.innerHTML = '';
                            currentFocus = -1;
                            validSelection = false;
                            document.getElementById('search-btn').disabled = true;

                            if (!value) {
                                list.style.display = 'none';
                                return;
                            }

                            const nameMap = {};
                            streetIndex.forEach(item => {
                                const name = item.name.split(' (')[0].toLowerCase();
                                if (!nameMap[name]) nameMap[name] = 0;
                                nameMap[name]++;
                            });

                            const suggestions = streetIndex.filter(item =>
                                item.name.toLowerCase().includes(value) &&
                                (selectedTypes.length === 0 || selectedTypes.includes(item.highway))
                            );

                            // Sort suggestions by name
                            const added = new Set();
                            suggestions.forEach(suggestion => {
                                const baseName = suggestion.name.split(' (')[0];
                                if (added.has(baseName)) return;
                                added.add(baseName);

                                const count = nameMap[baseName.toLowerCase()];
                                const displayName = count > 1 ? `${baseName} (+${count - 1} more)` : baseName;

                                const option = document.createElement('div');
                                option.textContent = displayName;
                                option.style.cursor = 'pointer';
                                option.style.padding = '4px';

                                option.addEventListener('click', () => {
                                    input.value = baseName;
                                    validSelection = true;
                                    document.getElementById('search-btn').disabled = false;
                                    list.style.display = 'none';
                                    handleStreetSearch(); // 👈 trigger search immediately
                                    input.style.borderColor = 'green';
                                });

                                list.appendChild(option);
                            });

                            list.style.display = suggestions.length > 0 ? 'block' : 'none';
                            input.style.borderColor = suggestions.length > 0 ? 'green' : 'red';
                        });

                        input.addEventListener("keydown", function(e) {
                            const options = list.getElementsByTagName("div");
                            if (e.key === "ArrowDown") {
                                currentFocus++;
                                addActive(options);
                            } else if (e.key === "ArrowUp") {
                                currentFocus--;
                                addActive(options);
                            } else if (e.key === "Enter") {
                                e.preventDefault();
                                if (currentFocus > -1 && options[currentFocus]) {
                                    options[currentFocus].click();
                                }
                            }
                        });

                        function addActive(options) {
                            if (!options) return;
                            removeActive(options);
                            if (currentFocus >= options.length) currentFocus = 0;
                            if (currentFocus < 0) currentFocus = options.length - 1;
                            options[currentFocus].classList.add("autocomplete-active");
                            options[currentFocus].scrollIntoView({
                                block: "nearest"
                            });
                        }

                        function removeActive(options) {
                            for (let i = 0; i < options.length; i++) {
                                options[i].classList.remove("autocomplete-active");
                            }
                        }

                        function handleStreetSearch() {
                            const query = input.value.trim().toLowerCase();
                            const selectedTypes = Array.from(document.querySelectorAll('.type-checkbox:checked')).map(cb => cb.value);
                            const feedback = document.getElementById('search-feedback');

                            document.getElementById('search-btn').disabled = true;

                            document.getElementById('search-btn').addEventListener('click', () => {
                                if (validSelection) handleStreetSearch();
                            });

                            if (!query) {
                                feedback.textContent = "Please enter a street name.";
                                return;
                            }

                            // Find all matching items
                            const matchedItems = streetIndex.filter(item => {
                                const nameMatch = item.name.toLowerCase().includes(query);
                                const typeMatch = selectedTypes.length === 0 || selectedTypes.includes(item.highway);
                                return nameMatch && typeMatch;
                            });

                            document.querySelectorAll('.type-checkbox').forEach(cb => {
                                cb.addEventListener('change', () => {
                                    input.dispatchEvent(new Event('input')); // Trigger autocomplete filtering
                                });
                            });

                            if (matchedItems.length > 0) {
                                streetLayer.eachLayer(layer => layer.setStyle(dimmedStyle));
                                activeStreet = null; // Reset active street

                                streetLayer.eachLayer(layer => {
                                    layer.setStyle(dimmedStyle);
                                    layer._isActive = false;
                                });

                                const group = L.featureGroup();
                                matchedItems.forEach(item => {
                                    item.layer.setStyle(highlightStyle);
                                    item.layer._isActive = true; // 👈 Mark active
                                    if (item.layer.bringToFront) item.layer.bringToFront();
                                    item.layer.openPopup(); // 👉 Open each popup
                                    group.addLayer(item.layer);
                                });

                                map.fitBounds(group.getBounds().pad(0.2)); // Slightly pad for visual breathing room

                                activeMultiLine = true;
                                activeStreet = group; // Set active street to the group of matched items
                                const props = matchedItems[0].layer.feature.properties;

                                const infoHTML = `<h4>${props.name}</h4>
                                <p><strong>Matched Segments:</strong> ${matchedItems.length}</p>
                                <ul style="list-style:none;padding:0;font-size:13px;">
                                ${matchedItems.map((item, i) => {
                                    const p = item.layer.feature.properties;
                                    return `<li style="margin-bottom:4px;">
                                    Segment ${i + 1}: 
                                    ${p.highway ? `Type: ${p.highway}` : 'N/A'}, 
                                    ${p.oneway ? `Oneway: ${p.oneway}` : ''},
                                    ${p.old_name ? `Old: ${p.old_name}` : ''},
                                    ID: ${p["@id"] || 'N/A'}
                                    </li>`;
                                    }).join('')}
                                </ul>`;

                                document.getElementById('street-info').innerHTML = infoHTML;

                                feedback.textContent = `${matchedItems.length} street(s) found!`;
                            } else {
                                feedback.textContent = "Street not found.";
                                resetStreetStyles();
                            }
                        }

                        // Assume `streetLayer` is already loaded and added to the map
                        var isStreetLayerVisible = true;

                        // Add the custom toggle button control
                        var toggleStreetLayerButton = L.control({
                            position: 'topleft'
                        });

                        toggleStreetLayerButton.onAdd = function() {
                            var div = L.DomUtil.create('div', 'toggle-street-layer-button');
                            div.innerHTML = `<button id="toggle-street-layer" title="Toggle Street Layer" class="map-button">
                            <img src="../src/images/streets-on.png" alt="Toggle Street Layer" style="width:20px;height:20px;">
                            </button>`;
                            return div;
                        };

                        toggleStreetLayerButton.addTo(map);

                        // Button click logic to show/hide `streetLayer` and swap icon
                        document.addEventListener('DOMContentLoaded', function() {
                            document.getElementById('toggle-street-layer').addEventListener('click', function() {
                                var buttonIcon = document.querySelector('#toggle-street-layer img');
                                if (isStreetLayerVisible) {
                                    map.removeLayer(streetLayer);
                                    buttonIcon.src = '../src/images/streets-off.png';
                                } else {
                                    streetLayer.addTo(map);
                                    buttonIcon.src = '../src/images/streets-on.png';
                                }
                                isStreetLayerVisible = !isStreetLayerVisible;
                            });
                        });

                        var geojsonLayer = L.geoJSON(geojsonData, {
                            style: {
                                color: 'blue',
                                /* Gray */
                                fillColor: '#ffffff',
                                /* Lighter shade of gray */
                                fillOpacity: 0
                            }
                        }).addTo(map);

                        // Create a button to toggle the GeoJSON layer visibility with alternating icons
                        var toggleGeoJSONButton = L.control({
                            position: 'topleft'
                        });

                        toggleGeoJSONButton.onAdd = function() {
                            var div = L.DomUtil.create('div', 'toggle-geojson-button');
                            div.innerHTML = '<button id="toggle-geojson" title="Toggle Boundary" class="map-button"><img src="../src/images/toggle-on-icon.png" alt="Toggle Boundary" style="width:20px;height:20px;"></button>';
                            return div;
                        };

                        toggleGeoJSONButton.addTo(map);

                        // Add event listener to the GeoJSON toggle button with alternating icons
                        var isGeoJSONVisible = true;
                        document.getElementById('toggle-geojson').addEventListener('click', function() {
                            var buttonIcon = document.querySelector('#toggle-geojson img');
                            if (isGeoJSONVisible) {
                                map.removeLayer(geojsonLayer);
                                buttonIcon.src = '../src/images/toggle-off-icon.png'; // Change to "off" icon
                            } else {
                                geojsonLayer.addTo(map);
                                buttonIcon.src = '../src/images/toggle-on-icon.png'; // Change to "on" icon
                            }
                            isGeoJSONVisible = !isGeoJSONVisible;
                        });

                        // Create a button to recenter the map
                        var recenterButton = L.control({
                            position: 'topleft'
                        });

                        recenterButton.onAdd = function() {
                            var div = L.DomUtil.create('div', 'recenter-button');
                            div.innerHTML = '<button id="recenter-map" title="Recenter Map" class="map-button"><img src="../src/images/recenter-icon.png" alt="Recenter Map" style="width:20px;height:20px;"></button>';
                            return div;
                        };

                        recenterButton.addTo(map);

                        // Add event listener to the recenter button
                        document.getElementById('recenter-map').addEventListener('click', function() {
                            map.setView([14.7007, 121.0349], 19); // Recenter to San Bartolome Hall
                        });

                        // Add a marker to San Bartolome Hall
                        var marker = L.marker([14.7007, 121.0347], {
                            icon: L.icon({
                                iconUrl: '../src/images/landmark-black.png', // Path to your marker icon
                                iconSize: [30, 30], // Size of the icon
                                iconAnchor: [12, 41], // Point of the icon which will correspond to marker's location
                                popupAnchor: [0, -41] // Point from which the popup should open relative to the iconAnchor
                            })
                        });

                        marker.addTo(map).bindPopup('San Bartolome Barangay Hall').openPopup();

                        // Create a button to toggle the marker visibility with alternating icons
                        var toggleMarkerButton = L.control({
                            position: 'topleft'
                        });

                        toggleMarkerButton.onAdd = function() {
                            var div = L.DomUtil.create('div', 'toggle-marker-button');
                            div.innerHTML = '<button id="toggle-marker" title="Toggle Marker" class="map-button"><img src="../src/images/marker-on-icon.png" alt="Toggle Marker" style="width:20px;height:20px;"></button>';
                            return div;
                        };

                        toggleMarkerButton.addTo(map);

                        // Add event listener to the marker toggle button with alternating icons
                        var isMarkerVisible = true; // Initially, the marker is visible

                        document.getElementById('toggle-marker').addEventListener('click', function() {
                            var buttonIcon = document.querySelector('#toggle-marker img');
                            if (isMarkerVisible) {
                                map.removeLayer(marker);
                                buttonIcon.src = '../src/images/marker-off-icon.png'; // Change to "off" icon
                            } else {
                                marker.addTo(map);
                                buttonIcon.src = '../src/images/marker-on-icon.png'; // Change to "on" icon
                            }
                            isMarkerVisible = !isMarkerVisible;
                        });
                    </script>
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

                    <label for="crime-form">Crime:</label>
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
                    <input type="date" id="date" name="date" required><br>

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