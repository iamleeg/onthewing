/**
 * @jest-environment jsdom
 */
const { initObservationMap } = require('../WebServerResources/ObservationMap');

// Mock Leaflet global
global.L = {
    map: jest.fn().mockReturnValue({
        setView: jest.fn().mockReturnThis(),
    }),
    tileLayer: jest.fn().mockReturnValue({
        addTo: jest.fn().mockReturnThis(),
    }),
    marker: jest.fn().mockReturnValue({
        addTo: jest.fn().mockReturnThis(),
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
});
