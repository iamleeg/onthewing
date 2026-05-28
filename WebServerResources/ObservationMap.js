function initObservationMap() {
    const mapElement = document.getElementById('observation-map');
    if (!mapElement) return;

    const lat = mapElement.getAttribute('data-lat');
    const lng = mapElement.getAttribute('data-lng');

    if (lat && lng) {
        const coordinates = [parseFloat(lat), parseFloat(lng)];
        
        // Initialize the Leaflet map
        const map = L.map('observation-map').setView(coordinates, 13);

        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);

        // Add a marker at the location
        L.marker(coordinates).addTo(map);
    } else {
        console.error('ObservationMap: Missing coordinates in data attributes');
    }
}

if (typeof window !== 'undefined') {
    document.addEventListener('DOMContentLoaded', initObservationMap);
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { initObservationMap };
}
