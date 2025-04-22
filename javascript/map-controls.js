const LegendControl = L.Control.extend({
  options: {
    position: "topright",
  }, // or 'topright', 'topleft', etc.

  onAdd: function (map) {
    const container = L.DomUtil.create("div", "legend-toggle-container");

    // Toggle Button
    const toggleBtn = L.DomUtil.create("button", "", container);
    toggleBtn.innerHTML = "🧭 Hide Legends";
    toggleBtn.style.background = "#fff";
    toggleBtn.style.color = "#333";
    toggleBtn.style.border = "none";
    toggleBtn.style.padding = "6px 10px";
    toggleBtn.style.borderRadius = "6px";
    toggleBtn.style.cursor = "pointer";
    toggleBtn.style.marginBottom = "6px";
    toggleBtn.style.width = "100%";

    // Actual legend box
    const legendDiv = L.DomUtil.create("div", "info legend", container);
    legendDiv.style.background = "white";
    legendDiv.style.padding = "10px 15px";
    legendDiv.style.borderRadius = "8px";
    legendDiv.style.boxShadow = "0 0 8px #000000";
    legendDiv.style.fontSize = "14px";
    legendDiv.style.lineHeight = "1.4em";
    legendDiv.style.marginTop = "5px";

    legendDiv.innerHTML = `<strong style="font-size:16px;">Legends</strong>
        <hr style="margin: 4px 0 8px 0;">
        <div><span style="display:inline-block; width:16px; height:16px; background:#4CAF50; border-radius:3px; margin-right:6px;"></span>Generally Safe</div>
        <div><span style="display:inline-block; width:16px; height:16px; background:#FFEB3B; border-radius:3px; margin-right:6px;"></span>Mostly Safe, Stay Aware</div>
        <div><span style="display:inline-block; width:16px; height:16px; background:#FF9800; border-radius:3px; margin-right:6px;"></span>Caution Advised</div>
        <div><span style="display:inline-block; width:16px; height:16px; background:#F44336; border-radius:3px; margin-right:6px;"></span>Heightened Risk Area</div>
        <div><span style="display:inline-block; width:16px; height:16px; background:#8800c7; border-radius:3px; margin-right:6px;"></span>Selected Street</div>`;

    // Toggle logic
    let visible = true;
    toggleBtn.onclick = () => {
      visible = !visible;
      legendDiv.style.display = visible ? "block" : "none";
      toggleBtn.innerHTML = visible ? "🧭 Hide Legends" : "🧭 Show Legends";
    };

    return container;
  },
});

map.addControl(new LegendControl());

// Reset everything when clicking outside a street
map.on("click", function () {
  resetStreetStyles();
});

const searchToggleControl = L.control({
  position: "topleft",
});

searchToggleControl.onAdd = function () {
  const buttonContainer = L.DomUtil.create(
    "div",
    "leaflet-bar leaflet-control leaflet-control-custom"
  );
  buttonContainer.style.background = "white";
  buttonContainer.style.padding = "4px 4px 0px 4px";

  const button = document.createElement("img");
  button.src = "../src/images/search-streets-on.png"; // 🔁 Replace with your icon later
  button.className = "map-button";
  button.alt = "Search Street";
  button.title = "Search Street";
  button.style.cursor = "pointer";
  button.style.width = "27px";
  button.style.height = "auto";

  buttonContainer.appendChild(button);

  button.addEventListener("click", () => {
    const searchPanel = document.getElementById("street-search-panel");
    if (searchPanel) {
      searchPanel.style.display =
        searchPanel.style.display === "none" ? "block" : "none";
    }
  });

  return buttonContainer;
};

searchToggleControl.addTo(map);

// Create a custom search control for streets
const streetSearchControl = L.control({
  position: "topleft",
});

streetSearchControl.onAdd = function () {
  const outer = L.DomUtil.create("div");
  const container = L.DomUtil.create(
    "div",
    "leaflet-bar leaflet-control leaflet-control-custom",
    outer
  );
  outer.id = "street-search-panel";
  outer.style.display = "none"; // initially hidden

  container.style.width = "10vw";
  container.style.background = "white";
  container.style.margin = "0";
  container.style.padding = "8px";
  container.style.boxShadow = "0 2px 6px rgba(0,0,0,0.2)";
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
const input = document.getElementById("search-input");
const list = document.getElementById("autocomplete-list");
const filter = document.getElementById("type-filter");
let validSelection = false;
let currentFocus = -1;

input.addEventListener("input", function () {
  const value = this.value.trim().toLowerCase();
  const selectedTypes = Array.from(
    document.querySelectorAll(".type-checkbox:checked")
  ).map((cb) => cb.value);
  list.innerHTML = "";
  currentFocus = -1;
  validSelection = false;
  document.getElementById("search-btn").disabled = true;

  if (!value) {
    list.style.display = "none";
    return;
  }

  const nameMap = {};
  streetIndex.forEach((item) => {
    const name = item.name.split(" (")[0].toLowerCase();
    if (!nameMap[name]) nameMap[name] = 0;
    nameMap[name]++;
  });

  const suggestions = streetIndex.filter(
    (item) =>
      item.name.toLowerCase().includes(value) &&
      (selectedTypes.length === 0 || selectedTypes.includes(item.highway))
  );

  // Sort suggestions by name
  const added = new Set();
  suggestions.forEach((suggestion) => {
    const baseName = suggestion.name.split(" (")[0];
    if (added.has(baseName)) return;
    added.add(baseName);

    const count = nameMap[baseName.toLowerCase()];
    const displayName =
      count > 1 ? `${baseName} (+${count - 1} more)` : baseName;

    const option = document.createElement("div");
    option.textContent = displayName;
    option.style.cursor = "pointer";
    option.style.padding = "4px";

    option.addEventListener("click", () => {
      input.value = baseName;
      validSelection = true;
      document.getElementById("search-btn").disabled = false;
      list.style.display = "none";
      handleStreetSearch(); // 👈 trigger search immediately
      input.style.borderColor = "green";
    });

    list.appendChild(option);
  });

  list.style.display = suggestions.length > 0 ? "block" : "none";
  input.style.borderColor = suggestions.length > 0 ? "green" : "red";
});

input.addEventListener("keydown", function (e) {
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
    block: "nearest",
  });
}

function removeActive(options) {
  for (let i = 0; i < options.length; i++) {
    options[i].classList.remove("autocomplete-active");
  }
}

function handleStreetSearch() {
  const query = input.value.trim().toLowerCase();
  const selectedTypes = Array.from(
    document.querySelectorAll(".type-checkbox:checked")
  ).map((cb) => cb.value);
  const feedback = document.getElementById("search-feedback");

  document.getElementById("search-btn").disabled = true;

  document.getElementById("search-btn").addEventListener("click", () => {
    if (validSelection) handleStreetSearch();
  });

  if (!query) {
    feedback.textContent = "Please enter a street name.";
    return;
  }

  // Find all matching items
  const matchedItems = streetIndex.filter((item) => {
    const nameMatch = item.name.toLowerCase().includes(query);
    const typeMatch =
      selectedTypes.length === 0 || selectedTypes.includes(item.highway);
    return nameMatch && typeMatch;
  });

  document.querySelectorAll(".type-checkbox").forEach((cb) => {
    cb.addEventListener("change", () => {
      input.dispatchEvent(new Event("input")); // Trigger autocomplete filtering
    });
  });

  if (matchedItems.length > 0) {
    streetLayer.eachLayer((layer) => layer.setStyle(dimmedStyle));
    activeStreet = null; // Reset active street

    streetLayer.eachLayer((layer) => {
      layer.setStyle(dimmedStyle);
      layer._isActive = false;
    });

    const group = L.featureGroup();
    matchedItems.forEach((item) => {
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
        ${matchedItems
          .map((item, i) => {
            const p = item.layer.feature.properties;
            return `<li style="margin-bottom:4px;">
        Segment ${i + 1}: 
        ${p.highway ? `Type: ${p.highway}` : "N/A"}, 
        ${p.oneway ? `Oneway: ${p.oneway}` : ""},
        ${p.old_name ? `Old: ${p.old_name}` : ""},
        ID: ${p["@id"] || "N/A"}
        </li>`;
          })
          .join("")}
        </ul>`;

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
  position: "topleft",
});

toggleStreetLayerButton.onAdd = function () {
  var div = L.DomUtil.create("div", "toggle-street-layer-button");
  div.innerHTML = `<button id="toggle-street-layer" title="Toggle Street Layer" class="map-button">
    <img src="../src/images/streets-on.png" alt="Toggle Street Layer" style="width:20px;height:20px;">
    </button>`;
  return div;
};

toggleStreetLayerButton.addTo(map);

// Button click logic to show/hide `streetLayer` and swap icon
document.addEventListener("DOMContentLoaded", function () {
  document
    .getElementById("toggle-street-layer")
    .addEventListener("click", function () {
      var buttonIcon = document.querySelector("#toggle-street-layer img");
      if (isStreetLayerVisible) {
        map.removeLayer(streetLayer);
        buttonIcon.src = "../src/images/streets-off.png";
      } else {
        streetLayer.addTo(map);
        buttonIcon.src = "../src/images/streets-on.png";
      }
      isStreetLayerVisible = !isStreetLayerVisible;
    });
});

var geojsonLayer = L.geoJSON(geojsonData, {
  style: {
    color: "blue",
    /* Gray */
    fillColor: "#ffffff",
    /* Lighter shade of gray */
    fillOpacity: 0,
  },
}).addTo(map);

// Create a button to toggle the GeoJSON layer visibility with alternating icons
var toggleGeoJSONButton = L.control({
  position: "topleft",
});

toggleGeoJSONButton.onAdd = function () {
  var div = L.DomUtil.create("div", "toggle-geojson-button");
  div.innerHTML =
    '<button id="toggle-geojson" title="Toggle Boundary" class="map-button"><img src="../src/images/toggle-on-icon.png" alt="Toggle Boundary" style="width:20px;height:20px;"></button>';
  return div;
};

toggleGeoJSONButton.addTo(map);

// Add event listener to the GeoJSON toggle button with alternating icons
var isGeoJSONVisible = true;
document
  .getElementById("toggle-geojson")
  .addEventListener("click", function () {
    var buttonIcon = document.querySelector("#toggle-geojson img");
    if (isGeoJSONVisible) {
      map.removeLayer(geojsonLayer);
      buttonIcon.src = "../src/images/toggle-off-icon.png"; // Change to "off" icon
    } else {
      geojsonLayer.addTo(map);
      buttonIcon.src = "../src/images/toggle-on-icon.png"; // Change to "on" icon
    }
    isGeoJSONVisible = !isGeoJSONVisible;
  });

// Create a button to recenter the map
var recenterButton = L.control({
  position: "topleft",
});

recenterButton.onAdd = function () {
  var div = L.DomUtil.create("div", "recenter-button");
  div.innerHTML =
    '<button id="recenter-map" title="Recenter Map" class="map-button"><img src="../src/images/recenter-icon.png" alt="Recenter Map" style="width:20px;height:20px;"></button>';
  return div;
};

recenterButton.addTo(map);

// Add event listener to the recenter button
document.getElementById("recenter-map").addEventListener("click", function () {
  map.setView([14.7007, 121.0349], 19); // Recenter to San Bartolome Hall
});

// Add a marker to San Bartolome Hall
const marker = L.marker([14.7007, 121.0347], {
  icon: L.icon({
    iconUrl: "../src/images/landmark-black.png",
    iconSize: [30, 30],
    iconAnchor: [12, 41],
    popupAnchor: [0, -41],
  }),
}).bindPopup("San Bartolome Barangay Hall");

marker.addTo(map).openPopup();

// Create a button to toggle both the marker and the heatmap
const toggleMarkerButton = L.control({
  position: "topleft",
});

toggleMarkerButton.onAdd = function () {
  const div = L.DomUtil.create("div", "toggle-marker-button");
  div.innerHTML = `<button id="toggle-marker" title="Toggle Marker & Heatmap" class="map-button">
    <img src="../src/images/marker-on-icon.png" alt="Toggle Marker" style="width:20px;height:20px;">
    </button>`;
  return div;
};

toggleMarkerButton.addTo(map);

// Add event listener to the marker toggle button with alternating icons
var isMarkerVisible = true; // Initially, the marker is visible

document.getElementById("toggle-marker").addEventListener("click", function () {
  var buttonIcon = document.querySelector("#toggle-marker img");
  if (isMarkerVisible) {
    map.removeLayer(marker);
    buttonIcon.src = "../src/images/marker-off-icon.png"; // Change to "off" icon
  } else {
    marker.addTo(map);
    buttonIcon.src = "../src/images/marker-on-icon.png"; // Change to "on" icon
  }
  isMarkerVisible = !isMarkerVisible;
});

document.addEventListener("DOMContentLoaded", function () {
  const toggleButton = document.getElementById("toggle-marker");
  const iconImg = toggleButton.querySelector("img");

  // Fetch and create the heatmap once
  refreshCrimeLayer();
  updateHeatmap();
});
