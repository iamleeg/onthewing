function getMeanCoordinates(coords) {
    if (coords.length === 0) return [0, 0];
    if (coords.length === 1) return coords[0];

    let x = 0;
    let y = 0;
    let z = 0;

    for (let i = 0; i < coords.length; i++) {
        const lat = coords[i][0] * Math.PI / 180;
        const lng = coords[i][1] * Math.PI / 180;

        x += Math.cos(lat) * Math.cos(lng);
        y += Math.cos(lat) * Math.sin(lng);
        z += Math.sin(lat);
    }

    const total = coords.length;
    x /= total;
    y /= total;
    z /= total;

    const hyp = Math.sqrt(x * x + y * y);
    const meanLng = Math.atan2(y, x) * 180 / Math.PI;
    const meanLat = Math.atan2(z, hyp) * 180 / Math.PI;

    return [meanLat, meanLng];
}

function initObservationMap() {
    const mapElement = document.getElementById('observation-map');
    if (!mapElement) return;

    if (L.Icon && L.Icon.Default) {
        L.Icon.Default.imagePath = '/WebObjects/OnTheWing.woa/0/wr/';
    }

    const markersAttr = mapElement.getAttribute('data-markers');
    if (markersAttr) {
        let markersData = [];
        try {
            markersData = JSON.parse(markersAttr);
        } catch (e) {
            console.error('Failed to parse markers data:', e);
            return;
        }

        if (markersData.length > 0) {
            const coords = markersData.map(m => [m.lat, m.lng]);
            const center = getMeanCoordinates(coords);
            const map = L.map('observation-map').setView(center, 13);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            }).addTo(map);

            const leafletMarkers = [];
            markersData.forEach(markerInfo => {
                const coord = [markerInfo.lat, markerInfo.lng];
                const marker = L.marker(coord).addTo(map);
                if (markerInfo.title) {
                    marker.bindPopup(markerInfo.title);
                }
                leafletMarkers.push(marker);
            });

            if (leafletMarkers.length > 1) {
                const group = new L.featureGroup(leafletMarkers);
                map.fitBounds(group.getBounds().pad(0.1));
            }
        } else {
            console.error('ObservationMap: Empty markers data');
        }
    } else {
        const lat = mapElement.getAttribute('data-lat');
        const lng = mapElement.getAttribute('data-lng');

        if (lat && lng) {
            const coordinates = [parseFloat(lat), parseFloat(lng)];
            const map = L.map('observation-map').setView(coordinates, 13);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            }).addTo(map);

            L.marker(coordinates).addTo(map);
        } else {
            console.error('ObservationMap: Missing coordinates in data attributes');
        }
    }
}

if (typeof window !== 'undefined') {
    document.addEventListener('DOMContentLoaded', initObservationMap);
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { initObservationMap, getMeanCoordinates };
}
