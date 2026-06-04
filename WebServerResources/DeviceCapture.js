const DeviceCapture = {
    async captureAndSend() {
        try {
            // Request orientation permission if needed (iOS 13+)
            if (typeof DeviceOrientationEvent !== 'undefined' && 
                typeof DeviceOrientationEvent.requestPermission === 'function') {
                try {
                    const permission = await DeviceOrientationEvent.requestPermission();
                    if (permission !== 'granted') {
                        console.warn("DeviceOrientation permission denied");
                    }
                } catch (permError) {
                    console.error("Error requesting device orientation permission:", permError);
                }
            }

            const locationResult = await this.getLocation();
            const bearing = await this.getCompassBearing().catch(() => null);
            
            this.submitForm(locationResult, bearing);
            return { success: true };
        } catch (error) {
            console.error("Unexpected capture error:", error);
            return { success: false, error: error.message };
        }
    },

    async getLocation() {
        return new Promise((resolve) => {
            if (!navigator || !navigator.geolocation) {
                resolve({ data: null, error: 2 }); // GeolocationPositionError.POSITION_UNAVAILABLE
                return;
            }
            navigator.geolocation.getCurrentPosition(
                pos => resolve({ data: { lat: pos.coords.latitude, lon: pos.coords.longitude, acc: pos.coords.accuracy }, error: null }),
                err => resolve({ data: null, error: err.code }), // 1: Denied, 2: Unavailable, 3: Timeout
                { enableHighAccuracy: true, timeout: 10000 }
            );
        });
    },

    async getCompassBearing() { 
        return new Promise((resolve) => {
            let bestHeading = null;
            
            const handleOrientation = (event) => {
                let heading = event.webkitCompassHeading;
                let accuracy = event.webkitCompassAccuracy;
                
                if (heading === undefined && event.alpha !== null) {
                    heading = 360 - event.alpha;
                }
                
                if (heading !== undefined && heading !== null) {
                    // If accuracy is not supported/provided (e.g. non-iOS or test environment),
                    // resolve immediately to maintain compatibility and speed.
                    if (accuracy === undefined || accuracy === null) {
                        window.removeEventListener('deviceorientation', handleOrientation);
                        resolve(heading);
                        return;
                    }
                    
                    // If accuracy is supported, we check if it is calibrated (accuracy > 0)
                    if (accuracy > 0) {
                        // Calibrated reading! Resolve immediately with it.
                        window.removeEventListener('deviceorientation', handleOrientation);
                        resolve(heading);
                        return;
                    }
                    
                    // If accuracy is <= 0 (e.g., -1 meaning uncalibrated), we keep track of the heading,
                    // but we don't resolve yet, hoping for a calibrated event to arrive.
                    if (bestHeading === null) {
                        bestHeading = heading;
                    }
                }
            };
            window.addEventListener('deviceorientation', handleOrientation);
            setTimeout(() => {
                window.removeEventListener('deviceorientation', handleOrientation);
                resolve(bestHeading);
            }, 1000);
        });
    },

    submitForm(locationResult, bearing) {
        const setVal = (id, val) => {
            const el = document.getElementById(id);
            if (el) el.value = val;
        };
        const loc = locationResult.data;
        setVal('latitude', loc ? loc.lat : "");
        setVal('longitude', loc ? loc.lon : "");
        setVal('accuracy', loc ? loc.acc : "");
        setVal('locationError', locationResult.error !== null ? locationResult.error : "");
        setVal('bearing', bearing !== null ? bearing : "");
        setVal('bearingError', bearing === null ? "1" : "");

        const form = document.getElementById('location-capture-form') || document.forms[0];
        if (form) {
            form.submit();
        }
    }
};

if (typeof module !== 'undefined' && module.exports) {
    module.exports = DeviceCapture;
}
