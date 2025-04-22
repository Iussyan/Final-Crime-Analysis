let heatLayer = null; // Declare globally so we can add/remove it later

let clusterInfoLayer = null;

function updateHeatmap() {
  fetch("../secure/get_active_streets.php?ts=" + Date.now())
    .then((res) => res.json())
    .then((data) => {
      const turfPoints = data.features.map((f) => {
        const coords = f.geometry.coordinates;
        const mid = coords[Math.floor(coords.length / 2)];
        return turf.point([mid[0], mid[1]], {
          weight: f.properties.crimeCount || 1,
          street: f.properties.streetName || "Unknown Street",
          category: f.properties.categories || "Uncategorized",
        });
      });

      // DBSCAN ALGORITHM
      // For clusters to appear, we need at least 3 points within a radius of 0.05 degrees (about 5-6 kilometers)
      const pointCollection = turf.featureCollection(turfPoints);
      const clustered = turf.clustersDbscan(pointCollection, 0.2, {
        minPoints: 2,
      });
      const clusteredPoints = clustered.features.filter(
        (pt) => pt.properties.cluster !== undefined
      );

      const clustersMap = {};
      clusteredPoints.forEach((pt) => {
        const clusterId = pt.properties.cluster;
        if (!clustersMap[clusterId]) clustersMap[clusterId] = [];
        clustersMap[clusterId].push(pt);
      });

      const heatPoints = [];
      const markerGroup = L.layerGroup();

      Object.values(clustersMap).forEach((cluster, index) => {
        const avgLng =
          cluster.reduce((sum, pt) => sum + pt.geometry.coordinates[0], 0) /
          cluster.length;
        const avgLat =
          cluster.reduce((sum, pt) => sum + pt.geometry.coordinates[1], 0) /
          cluster.length;
        const totalWeight = cluster.reduce(
          (sum, pt) => sum + (pt.properties.weight || 1),
          0
        );

        // Add to heatmap
        heatPoints.push([avgLat, avgLng, totalWeight]);

        // Collect info for popup
        const uniqueStreets = [
          ...new Set(cluster.map((p) => p.properties.street)),
        ];
        const categories = [
          ...new Set(cluster.map((p) => p.properties.category)),
        ];
        const popupContent = `
                            <strong>Cluster #${index + 1}</strong><br>
                            <strong>Total Crimes:</strong> ${totalWeight}<br>
                            <strong>Streets:</strong> ${uniqueStreets.join(
                              ", "
                            )}<br>
                            <strong>Categories:</strong> ${categories.join(
                              ", "
                            )}`;

        // Create a small circle marker (invisible or faint)
        const marker = L.circleMarker([avgLat, avgLng], {
          radius: 10,
          fillColor: "#000",
          fillOpacity: 0.01,
          stroke: false,
          clusterId: index,
        })
          .bindPopup(popupContent)
          .on("click", function (e) {
            crimeLayer.eachLayer((lyr) => {
              if (uniqueStreets.includes(lyr.feature.properties.streetName)) {
                lyr.setStyle({
                  weight: 5,
                });
                lyr._isActive = true;
              } else {
                lyr.setStyle(defaultStyle);
                lyr._isActive = false;
              }
            });
          });

        markerGroup.addLayer(marker);
      });

      // Remove old layers if any
      if (heatLayer) map.removeLayer(heatLayer);
      if (clusterInfoLayer) map.removeLayer(clusterInfoLayer);

      // Add new heatmap
      heatLayer = L.heatLayer(heatPoints, {
        radius: 35,
        blur: 40,
        minOpacity: 1,
        maxZoom: 20,
        gradient: {
          0.2: "#00ff00",
          0.4: "#ffff00",
          0.6: "#ff8000",
          0.8: "#ff0000",
        },
        // Make it so the heatmap does not change size when zooming in
        zoomOffset: -20,
      }).addTo(map);

      // Add new tooltip layer
      clusterInfoLayer = markerGroup.addTo(map);
    });
}
