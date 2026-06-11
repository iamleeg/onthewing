/**
 * @jest-environment jsdom
 */
const { initObservationMap, getMeanCoordinates } = require('../WebServerResources/ObservationMap');

// Mock Leaflet global
const mockMap = {
    setView: jest.fn().mockReturnThis(),
    fitBounds: jest.fn().mockReturnThis(),
};
const mockMarker = {
    addTo: jest.fn().mockReturnThis(),
    bindPopup: jest.fn().mockReturnThis(),
};
global.L = {
    map: jest.fn().mockReturnValue(mockMap),
    tileLayer: jest.fn().mockReturnValue({
        addTo: jest.fn().mockReturnThis(),
    }),
    marker: jest.fn().mockReturnValue(mockMarker),
    featureGroup: jest.fn().mockReturnValue({
        getBounds: jest.fn().mockReturnValue({
            pad: jest.fn().mockReturnValue([[40, -10], [60, 10]]),
        }),
    }),
};

describe('ObservationMap', () => {
    beforeEach(() => {
        document.body.innerHTML = '';
        jest.clearAllMocks();
        console.error = jest.fn();
    });

    test('initializes map when element and coordinates are present', () => {
        document.body.innerHTML = `
            <div id="observation-map" data-lat="51.5074" data-lng="-0.1278"></div>
        `;

        initObservationMap();

        expect(L.map).toHaveBeenCalledWith('observation-map');
        expect(L.map().setView).toHaveBeenCalledWith([51.5074, -0.1278], 13);
        expect(L.tileLayer).toHaveBeenCalled();
        expect(L.marker).toHaveBeenCalledWith([51.5074, -0.1278]);
    });

    test('does not initialize map when element is missing', () => {
        initObservationMap();
        expect(L.map).not.toHaveBeenCalled();
    });

    test('logs error and does not initialize map when coordinates are missing', () => {
        document.body.innerHTML = `
            <div id="observation-map" data-lat="51.5074"></div>
        `;

        initObservationMap();

        expect(L.map).not.toHaveBeenCalled();
        expect(console.error).toHaveBeenCalledWith('ObservationMap: Missing coordinates in data attributes');
    });

    describe('getMeanCoordinates', () => {
        test('handles empty coordinates', () => {
            expect(getMeanCoordinates([])).toEqual([0, 0]);
        });

        test('handles single coordinate', () => {
            expect(getMeanCoordinates([[51.5074, -0.1278]])).toEqual([51.5074, -0.1278]);
        });

        test('averages simple coordinates', () => {
            const mean = getMeanCoordinates([[10, 20], [20, 40]]);
            expect(mean[0]).toBeCloseTo(15.22, 1);
            expect(mean[1]).toBeCloseTo(29.80, 1);
        });

        test('correctly handles wrapping around the antimeridian', () => {
            // Two points right next to each other across the 180/-180 line
            const mean = getMeanCoordinates([[0, 179], [0, -179]]);
            // Mean longitude should be 180 (or -180), NOT 0 (Prime Meridian)
            expect(Math.abs(mean[1])).toBeCloseTo(180, 4);
            expect(mean[0]).toBeCloseTo(0, 4);
        });
    });

    describe('multiple observations map initialization', () => {
        test('plots multiple markers and fits bounds', () => {
            const markers = [
                { lat: 51.5074, lng: -0.1278, title: 'Observation 1 at 12:00' },
                { lat: 48.8566, lng: 2.3522, title: 'Observation 2 at 13:00' }
            ];
            document.body.innerHTML = `
                <div id="observation-map" data-markers='${JSON.stringify(markers)}'></div>
            `;

            initObservationMap();

            expect(L.map).toHaveBeenCalledWith('observation-map');
            // Check that it set view to the mean center
            const expectedCenter = getMeanCoordinates([[51.5074, -0.1278], [48.8566, 2.3522]]);
            expect(mockMap.setView).toHaveBeenCalledWith(expectedCenter, 13);
            
            // Markers added
            expect(L.marker).toHaveBeenCalledWith([51.5074, -0.1278]);
            expect(L.marker).toHaveBeenCalledWith([48.8566, 2.3522]);
            
            // Popovers bound
            expect(mockMarker.bindPopup).toHaveBeenCalledWith('Observation 1 at 12:00');
            expect(mockMarker.bindPopup).toHaveBeenCalledWith('Observation 2 at 13:00');

            // fitBounds called because we have > 1 markers
            expect(mockMap.fitBounds).toHaveBeenCalled();
        });
    });
});
