const DeviceCapture = require('../WebServerResources/DeviceCapture.js');

describe('DeviceCapture', () => {
    let mockForm, mockInputs;

    beforeEach(() => {
        // Reset globals and mock DOM elements
        global.navigator = {};
        global.window = {
            addEventListener: jest.fn(),
            removeEventListener: jest.fn()
        };
        global.DeviceOrientationEvent = undefined;

        mockInputs = {
            latitude: { value: '' },
            longitude: { value: '' },
            accuracy: { value: '' },
            locationError: { value: '' },
            bearing: { value: '' },
            bearingError: { value: '' }
        };

        mockForm = {
            submit: jest.fn()
        };

        global.document = {
            getElementById: jest.fn((id) => {
                if (id === 'location-capture-form') return mockForm;
                return mockInputs[id] || null;
            }),
            forms: [mockForm]
        };

        jest.useFakeTimers();
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    describe('getLocation', () => {
        it('should return error code 2 if geolocation is not supported', async () => {
            delete global.navigator.geolocation;
            const res = await DeviceCapture.getLocation();
            expect(res.data).toBeNull();
            expect(res.error).toBe(2);
        });

        it('should return lat, lon, acc on success', async () => {
            const mockPosition = {
                coords: {
                    latitude: 51.5,
                    longitude: -0.12,
                    accuracy: 15
                }
            };
            global.navigator.geolocation = {
                getCurrentPosition: jest.fn((success) => success(mockPosition))
            };

            const res = await DeviceCapture.getLocation();
            expect(res.error).toBeNull();
            expect(res.data).toEqual({ lat: 51.5, lon: -0.12, acc: 15 });
        });

        it('should return error code on geolocation failure', async () => {
            const mockError = { code: 1 }; // Permission denied
            global.navigator.geolocation = {
                getCurrentPosition: jest.fn((success, failure) => failure(mockError))
            };

            const res = await DeviceCapture.getLocation();
            expect(res.data).toBeNull();
            expect(res.error).toBe(1);
        });
    });

    describe('getCompassBearing', () => {
        it('should return webkitCompassHeading if available', async () => {
            let orientationHandler;
            global.window.addEventListener = jest.fn((event, handler) => {
                if (event === 'deviceorientation') {
                    orientationHandler = handler;
                }
            });

            const bearingPromise = DeviceCapture.getCompassBearing();

            // Simulate the event firing
            orientationHandler({ webkitCompassHeading: 120, alpha: null });

            const res = await bearingPromise;
            expect(res).toBe(120);
            expect(global.window.removeEventListener).toHaveBeenCalledWith('deviceorientation', orientationHandler);
        });

        it('should fallback to 360 - alpha if webkitCompassHeading is missing', async () => {
            let orientationHandler;
            global.window.addEventListener = jest.fn((event, handler) => {
                if (event === 'deviceorientation') {
                    orientationHandler = handler;
                }
            });

            const bearingPromise = DeviceCapture.getCompassBearing();

            // Simulate multiple events firing to trigger the alpha fallback
            for (let i = 0; i < 10; i++) {
                orientationHandler({ webkitCompassHeading: undefined, alpha: 90 });
            }

            const res = await bearingPromise;
            expect(res).toBe(270); // 360 - 90
        });

        it('should time out after 1 second and return null if no event is fired', async () => {
            let orientationHandler;
            global.window.addEventListener = jest.fn((event, handler) => {
                if (event === 'deviceorientation') {
                    orientationHandler = handler;
                }
            });

            const bearingPromise = DeviceCapture.getCompassBearing();

            // Fast forward timers
            jest.advanceTimersByTime(1000);

            const res = await bearingPromise;
            expect(res).toBeNull();
            expect(global.window.removeEventListener).toHaveBeenCalledWith('deviceorientation', orientationHandler);
        });

        it('should wait for calibrated reading if initial reading is uncalibrated', async () => {
            let orientationHandler;
            global.window.addEventListener = jest.fn((event, handler) => {
                if (event === 'deviceorientation') {
                    orientationHandler = handler;
                }
            });

            const bearingPromise = DeviceCapture.getCompassBearing();

            // First event: uncalibrated (accuracy = -1)
            orientationHandler({ webkitCompassHeading: 120, webkitCompassAccuracy: -1, alpha: null });
            
            // Second event: calibrated (accuracy = 15)
            orientationHandler({ webkitCompassHeading: 150, webkitCompassAccuracy: 15, alpha: null });

            const res = await bearingPromise;
            expect(res).toBe(150); // Resolved to the calibrated heading!
            expect(global.window.removeEventListener).toHaveBeenCalledWith('deviceorientation', orientationHandler);
        });

        it('should resolve with uncalibrated reading if timeout is reached and no calibrated reading was received', async () => {
            let orientationHandler;
            global.window.addEventListener = jest.fn((event, handler) => {
                if (event === 'deviceorientation') {
                    orientationHandler = handler;
                }
            });

            const bearingPromise = DeviceCapture.getCompassBearing();

            // Fire uncalibrated event
            orientationHandler({ webkitCompassHeading: 120, webkitCompassAccuracy: -1, alpha: null });

            // Fast forward timers
            jest.advanceTimersByTime(1000);

            const res = await bearingPromise;
            expect(res).toBe(120); // Resolved to the uncalibrated heading
            expect(global.window.removeEventListener).toHaveBeenCalledWith('deviceorientation', orientationHandler);
        });
    });

    describe('submitForm', () => {
        it('should correctly populate DOM elements and submit the form', () => {
            const locationResult = {
                data: { lat: 10, lon: 20, acc: 5 },
                error: null
            };
            const bearing = 45;

            DeviceCapture.submitForm(locationResult, bearing);

            expect(mockInputs.latitude.value).toBe(10);
            expect(mockInputs.longitude.value).toBe(20);
            expect(mockInputs.accuracy.value).toBe(5);
            expect(mockInputs.locationError.value).toBe("");
            expect(mockInputs.bearing.value).toBe(45);
            expect(mockInputs.bearingError.value).toBe("");
            expect(mockForm.submit).toHaveBeenCalled();
        });

        it('should handle uncaptured states correctly', () => {
            const locationResult = {
                data: null,
                error: 1
            };
            const bearing = null;

            DeviceCapture.submitForm(locationResult, bearing);

            expect(mockInputs.latitude.value).toBe("");
            expect(mockInputs.longitude.value).toBe("");
            expect(mockInputs.accuracy.value).toBe("");
            expect(mockInputs.locationError.value).toBe(1);
            expect(mockInputs.bearing.value).toBe("");
            expect(mockInputs.bearingError.value).toBe("1");
            expect(mockForm.submit).toHaveBeenCalled();
        });
    });

    describe('captureAndSend', () => {
        it('should request permissions on iOS 13+ if supported', async () => {
            const requestPermissionMock = jest.fn().mockResolvedValue('granted');
            global.DeviceOrientationEvent = {
                requestPermission: requestPermissionMock
            };

            jest.spyOn(DeviceCapture, 'getLocation').mockResolvedValue({ data: { lat: 1, lon: 2, acc: 3 }, error: null });
            jest.spyOn(DeviceCapture, 'getCompassBearing').mockResolvedValue(45);

            const success = await DeviceCapture.captureAndSend();
            expect(success).toEqual({ success: true });
            expect(requestPermissionMock).toHaveBeenCalled();
            expect(mockForm.submit).toHaveBeenCalled();
        });
    });
});
