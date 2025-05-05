// Define styles for the street layer
const defaultStyle = {
  color: "#3366ff",
  weight: 3,
  opacity: 1,
};

const mouseStyle = {
  color: "#3366ff",
  weight: 5,
  opacity: 1,
};

const highlightStyle = {
  color: "#ff5733",
  weight: 4,
  opacity: 1,
};

const dimmedStyle = {
  color: "#3366ff",
  weight: 4,
  opacity: 0.3,
};

let activeStreet = null; // track currently highlighted layer
let activeMultiLine = false;
let activeSingleLine = false;
const streetIndex = [];

const streetLayer = L.geoJSON(null, {
  style: (feature) => ({
    color: feature.properties.name ? "#3366ff" : "#3366ff",
    dashArray: feature.properties.name ? "none" : "4,4",
  }),
  onEachFeature: function (feature, layer) {
    const props = feature.properties;
    layer._isActive = false;
    const displayName = props.name + (props["@id"] ? ` (${props["@id"]})` : "");

    if (props?.name || !props?.name) {
      if (!props?.name) {
        props.name = "Unnamed Road / Street";
      }
      layer.bindPopup(
        () => `<div style="min-width:200px">
            <h4 style="margin-bottom:4px;">${props.name}</h4>
            <ul style="list-style:none; padding:0; margin:0; font-size: 1em;">
            ${
              props.highway
                ? `<li><strong>Type:</strong> ${props.highway}</li>`
                : ""
            }
            ${
              props.oneway
                ? `<li><strong>Oneway:</strong> ${props.oneway}</li>`
                : ""
            }
            ${
              props.old_name
                ? `<li><strong>Old Name:</strong> ${props.old_name}</li>`
                : ""
            }
            ${
              props["@id"]
                ? `<li><strong>ID:</strong> ${props["@id"]}</li>`
                : ""
            }
            </ul>
            </div>`
      );
      streetIndex.push({
        name: props.name,
        highway: props.highway,
        layer: layer,
      });
    }

    // Hover effect
    layer.on("mouseover", () => {
      if (!layer._isActive) {
        layer.setStyle(mouseStyle);
      }
    });

    layer.on("mouseout", () => {
      if (!layer._isActive && !activeMultiLine && !activeSingleLine) {
        layer.setStyle(defaultStyle);
      } else if ((!layer._isActive && activeMultiLine) || activeSingleLine) {
        if (!layer._isActive) layer.setStyle(dimmedStyle);
      }
    });

    // Click handler
    layer.on("click", (e) => {
      e.originalEvent.stopPropagation();
      streetLayer.eachLayer((layer) => layer.setStyle(dimmedStyle));
      activeSingleLine = true;

      layer.setStyle(highlightStyle);
      layer._isActive = true; // 👈 Mark this one active
      activeStreet = layer;

      map.fitBounds(layer.getBounds());
      layer.openPopup();
      // Zoom to and open popup
      map.fitBounds(layer.getBounds());
      layer.openPopup();
    });
  },
}).addTo(map);

// Load the GeoJSON data for streets
fetch("../src/san_bartolome_streets1.geojson")
  .then((res) => res.json())
  .then((data) => streetLayer.addData(data));

// Function to reset street styles
function resetStreetStyles() {
  streetLayer.eachLayer((layer) => {
    layer._isActive = false;
    layer.setStyle(defaultStyle);
  });
  activeMultiLine = false;
  activeSingleLine = false;
  activeStreet = null;
}

// Reset everything when clicking outside a street
map.on("click", function () {
  resetStreetStyles();
});
