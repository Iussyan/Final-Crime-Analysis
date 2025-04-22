const streetIndex = [];

const streetLayer = L.geoJSON(null, {
  style: (feature) => ({
    color: feature.properties.name ? "green" : "green",
    dashArray: feature.properties.name ? "none" : "4,4",
  }),
  onEachFeature: function (feature, lyer) {
    const props = feature.properties;
    lyer._isActive = false;
    const displayName = props.name + (props["@id"] ? ` (${props["@id"]})` : "");

    if (props?.name || !props?.name) {
      if (!props?.name) {
        props.name = "Unnamed Road / Street";
      }
      lyer.bindPopup(
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
                        </ul></div>`
      );
      streetIndex.push({
        name: props.name,
        highway: props.highway,
        layer: lyer,
      });
    }

    // Hover effect
    lyer.on("mouseover", () => {
      if (!lyer._isActive) {
        lyer.setStyle(mouseStyle);
      }
    });

    lyer.on("mouseout", () => {
      if (!lyer._isActive && !activeMultiLine && !activeSingleLine) {
        lyer.setStyle(defaultStyle);
      } else if ((!lyer._isActive && activeMultiLine) || activeSingleLine) {
        if (!lyer._isActive) lyer.setStyle(dimmedStyle);
      }
    });

    // Click handler
    lyer.on("click", (e) => {
      e.originalEvent.stopPropagation();
      streetLayer.eachLayer((lyer) => {
        lyer.setStyle(dimmedStyle);
      });
      activeSingleLine = true;

      lyer.setStyle(highlightStyle);

      lyer._isActive = true; // 👈 Mark this one active
      activeStreet = lyer;

      map.fitBounds(lyer.getBounds());
      lyer.openPopup();

      // Zoom to and open popup
      map.fitBounds(lyer.getBounds());
      lyer.openPopup();
    });
  },
}).addTo(map);

// Load the GeoJSON data for streets
fetch("../src/san_bartolome_streets1.geojson")
  .then((res) => res.json())
  .then((data) => streetLayer.addData(data));

// Function to reset street styles
function resetStreetStyles() {
  streetLayer.eachLayer((lyr) => {
    lyr._isActive = false;
    lyr.setStyle(defaultStyle);
  });

  refreshCrimeLayer();
  updateHeatmap();

  activeMultiLine = false;
  activeSingleLine = false;
  activeStreet = null;
  activeS = null;
  single = false;
}
