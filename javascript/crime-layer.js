// Define styles for the street layer
const defaultStyle = {
  color: "green",
  weight: 3,
  opacity: 1,
};

const mouseStyle = {
  weight: 5,
  opacity: 1,
};

const highlightStyle = {
  color: "purple",
  weight: 4,
  opacity: 1,
};

const dimmedStyle = {
  color: "green",
  weight: 4,
  opacity: 0.3,
};

let activeStreet = null; // track currently highlighted layer
let activeMultiLine = false;
let activeSingleLine = false;

let activeS = null;
let single = false;

let crimeLayer = null;
let isCrimeLayerVisible = false;

function getColor(crimeCount) {
  if (crimeCount > 2) return "red";
  if (crimeCount > 1) return "orange";
  if (crimeCount > 0) return "yellow";
  return "#3366ff";
}

function toggleCrimeLayer(btnImg = null) {
  if (!btnImg) {
    btnImg = document.querySelector(
      '.leaflet-control img[alt="Toggle Crime Layer"]'
    );
  }

  if (isCrimeLayerVisible) {
    map.removeLayer(crimeLayer);
    btnImg.src = "../src/images/layer-off.png";
    isCrimeLayerVisible = false;
  } else {
    fetch("../secure/get_active_streets.php")
      .then((res) => res.json())
      .then((data) => {
        crimeLayer = L.geoJSON(data, {
          style: (feature) => ({
            color: getColor(feature.properties.crimeCount),
            weight: 3,
          }),
          onEachFeature: function (feature, layer) {
            const props = feature.properties;
            layer._isActive = false;

            // Format popup
            layer.bindPopup(
              () => `<div style="min-width:200px">
                        <h4 style="margin-bottom:4px;">${props.streetName}</h4>
                        <ul style="list-style:none; padding:0; margin:0; font-size: 1em;">
                        <li><strong>ID:</strong> ${props.streetId}</li>
                        <li><strong>Crime Categories:</strong> ${props.categories}</li>
                        <li><strong>Crimes:</strong> ${props.crimes}</li>
                        <li><strong>Total Crimes:</strong> ${props.crimeCount}</li>
                        </ul>
                        </div>`
            );

            // Hover Effects
            layer.on("mouseover", () => {
              if (!layer._isActive)
                layer.setStyle({
                  weight: 5,
                });
            });

            layer.on("mouseout", () => {
              if (
                (!layer._isActive && !single) ||
                !activeSingleLine ||
                !activeSingleLine
              ) {
                layer.setStyle({
                  weight: 3,
                  color: getColor(props.crimeCount),
                  opacity: 1,
                });
              } else if (
                (!layer._isActive && single) ||
                activeSingleLine ||
                activeSingleLine
              ) {
                if (!layer._isActive) {
                  layer.setStyle({
                    opacity: 0.3,
                  });
                }
              }
            });

            // Click to select
            layer.on("click", (e) => {
              e.originalEvent.stopPropagation();

              streetLayer.eachLayer((lyr) => {
                lyr.setStyle(dimmedStyle);
              });

              single = true;
              activeSingleLine = true;
              activeMultiLine = true;

              layer._isActive = true;
              activeS = layer;

              map.fitBounds(layer.getBounds());
              map.currentFocus(activeS);
              layer.openPopup();
            });
          },
        }).addTo(map);

        if (btnImg) btnImg.src = "../src/img/layer-on.png";
        isCrimeLayerVisible = true;
      });
  }
}

function refreshCrimeLayer() {
  // If the layer is currently on the map, remove it before refreshing
  if (crimeLayer && map.hasLayer(crimeLayer)) {
    map.removeLayer(crimeLayer);
  }

  fetch("../secure/get_active_streets.php")
    .then((res) => res.json())
    .then((data) => {
      crimeLayer = L.geoJSON(data, {
        style: (feature) => ({
          color: getColor(feature.properties.crimeCount),
          weight: 3,
        }),
        onEachFeature: function (feature, layer) {
          const props = feature.properties;
          layer._isActive = false;

          layer.bindPopup(
            () => `
                    <div style="min-width:200px">
                    <h4 style="margin-bottom:4px;">${props.streetName}</h4>
                    <ul style="list-style:none; padding:0; margin:0; font-size: 1em;">
                    <li><strong>ID:</strong> ${props.streetId}</li>
                    <li><strong>Crime Categories:</strong> ${props.categories}</li>
                    <li><strong>Crimes:</strong> ${props.crimes}</li>
                    <li><strong>Total Crimes:</strong> ${props.crimeCount}</li>
                    </ul>
                    <button onclick="fetchIncidentDetails(${props.streetId})">View Incident Details</button>
                    </div>`
          );

          layer.on("mouseover", () => {
            if (!layer._isActive)
              layer.setStyle({
                weight: 5,
              });
          });

          layer.on("mouseout", () => {
            if (!layer._isActive && (!single || !activeSingleLine)) {
              layer.setStyle({
                weight: 3,
                color: getColor(props.crimeCount),
                opacity: 1,
              });
            } else if (!layer._isActive && (single || activeSingleLine)) {
              layer.setStyle({
                opacity: 0.3,
              });
            }
          });

          layer.on("click", (e) => {
            e.originalEvent.stopPropagation();

            streetLayer.eachLayer((lyr) => lyr.setStyle(dimmedStyle));

            single = true;
            activeSingleLine = true;
            activeMultiLine = true;

            layer.setStyle({
              weight: 5,
            });
            layer._isActive = true;
            activeS = layer;

            map.fitBounds(layer.getBounds());
            layer.openPopup();
          });
        },
      }).addTo(map);
    })
    .catch((err) => console.error("Failed to refresh crime layer", err));
}

/*
    MODIFY TO ENABLE TOGGLE INSTEAD
*/

// const CrimeLayerControl = L.Control.extend({
//     onAdd: function() {
//         const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control');

//         const btn = L.DomUtil.create('img', '', container);
//         btn.src = '../src/img/layer-off.png';
//         btn.alt = 'Toggle Crime Layer';
//         btn.style.width = '30px';
//         btn.style.height = '30px';
//         btn.style.cursor = 'pointer';
//         btn.title = 'Toggle Crime Layer';

//         L.DomEvent.on(btn, 'click', function(e) {
//             L.DomEvent.stopPropagation(e);
//             toggleCrimeLayer(btn);
//         });

//         return container;
//     },

//     onRemove: function() {
//         // Nothing to clean up
//     }
// });

// map.addControl(new CrimeLayerControl({
//     position: 'topright'
// }));
