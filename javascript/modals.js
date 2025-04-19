function fetchIncidentDetails(streetId) {
    const modal = document.getElementById("incidentModal");
    const modalBody = document.getElementById("modalBody");
    const modalTitle = document.getElementById("modalTitle");

    // Show the overlay
    let overlay = document.getElementById("modalOverlay");
    if (!overlay) {
        overlay = document.createElement("div");
        overlay.id = "modalOverlay";
        overlay.style.position = "fixed";
        overlay.style.top = "0";
        overlay.style.left = "0";
        overlay.style.width = "100vw";
        overlay.style.height = "100vh";
        overlay.style.backgroundColor = "rgba(0, 0, 0, 0.3)";
        overlay.style.zIndex = "500"; // Below modal
        overlay.style.pointerEvents = "auto";
        document.body.appendChild(overlay);
    } else {
        overlay.style.display = "block";
    }

    // Bring up the modal
    modal.style.display = "block";
    modal.style.zIndex = "1000"; // Above overlay
    modalTitle.textContent = `Incident Data for Street ID: ${streetId}`;
    modalBody.innerHTML = `<p><strong>Loading incident data...</strong></p>`;

    // Disable scroll and background interaction
    document.body.style.overflow = "hidden";
    // Block interaction with the map
    document.getElementById("map").style.pointerEvents = "none";

    // Fetch data
    fetch(`../secure/get_incidents_by_streets.php?streetId=${streetId}`)
        .then(res => res.json())
        .then(data => {
            if (!data.length) {
                modalBody.innerHTML = `<p>No incident records found for this street.</p>`;
                return;
            }

            let table = `<table style="width:100%; border-collapse:collapse;">
            <thead>
            <tr style="background:#f0f0f0;">
            <th>ID</th>
            <th>Address</th>
            <th>Category</th>
            <th>Type</th>
            <th>Description</th>
            <th>Witness</th>
            </tr>
            </thead>
            <tbody>`;

            data.forEach(row => {
                table += `
            <tr>
            <td>${row.IncidentId}</td>
            <td>${row.Address}</td>
            <td>${row.Category}</td>
            <td>${row["Crime Type"]}</td>
            <td>${row["Crime Description"]}</td>
            <td>
            ${row["Witness Name"]} (${row["Witness Age"]}, ${row["Witness Sex"]})<br>
            <small>📞 ${row["Witness Contact"]}</small>
            </td>
            </tr>`;
            });

            table += `</tbody></table>`;
            modalBody.innerHTML = table;
        })
        .catch(err => {
            console.error("Error loading incident data", err);
            modalBody.innerHTML = `<p>Error loading data.</p>`;
        });
}

// Handle modal close
const closeModal = () => {
    const modal = document.getElementById("incidentModal");
    modal.style.display = "none";
    document.body.style.overflow = "auto";
    const overlay = document.getElementById("modalOverlay");
    if (overlay) {
        overlay.style.display = "none";
    }
    document.getElementById("map").style.pointerEvents = "auto";
    document.querySelectorAll('button, a, input, select, textarea').forEach(el => {
        el.disabled = false;
    });
};

// Attach listeners after DOM is ready (safe, since your modal is inline)
document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("closeModalBtn").addEventListener("click", closeModal);

    window.addEventListener('click', (event) => {
        if (event.target.id === "incidentModal") {
            closeModal();
        }
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === "Escape" && document.getElementById("incidentModal").style.display === "block") {
            closeModal();
        }
    });
});