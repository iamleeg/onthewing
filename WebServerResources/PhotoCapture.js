const PhotoCapture = {
    async handleFileSelect(event, uniqueID, formID, urlInputID, actionInputID, statusID) {
        const file = event.target.files[0];
        if (!file) return;

        const statusEl = document.getElementById(statusID);
        if (statusEl) {
            statusEl.textContent = "Uploading...";
            statusEl.style.color = "inherit";
            statusEl.style.display = "inline";
        }

        try {
            // Compress the image client-side
            const compressedBlob = await this.compressImage(file);

            // Ensure Firebase is initialized
            if (typeof firebase === 'undefined') {
                throw new Error("Firebase SDK not loaded");
            }

            // Get current user for the storage path
            const user = firebase.auth().currentUser;
            if (!user) {
                throw new Error("User not authenticated");
            }

            // Generate a random ID for the image
            const imageId = this.uuidv4() + '.jpg';
            const storagePath = `temp/${user.uid}/${imageId}`;

            // Upload to Firebase Storage
            const storageRef = firebase.storage().ref().child(storagePath);
            const snapshot = await storageRef.put(compressedBlob);
            const downloadUrl = await snapshot.ref.getDownloadURL();

            // Set the URL in the hidden field and submit form
            const urlInput = document.getElementById(urlInputID);
            if (urlInput) urlInput.value = downloadUrl;

            const actionInput = document.getElementById(actionInputID);
            if (actionInput) actionInput.value = "upload";

            const form = document.getElementById(formID);
            if (form) {
                form.submit();
            }
        } catch (error) {
            console.error("Photo upload failed:", error);
            if (statusEl) {
                statusEl.textContent = "Upload failed: " + error.message;
                statusEl.style.color = "red";
            }
        }
    },

    async removePhoto(formID, urlInputID, actionInputID) {
        const urlInput = document.getElementById(urlInputID);
        if (urlInput) urlInput.value = "";

        const actionInput = document.getElementById(actionInputID);
        if (actionInput) actionInput.value = "remove";

        const form = document.getElementById(formID);
        if (form) {
            form.submit();
        }
    },

    compressImage(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = (event) => {
                const img = new Image();
                img.src = event.target.result;
                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    let width = img.width;
                    let height = img.height;

                    // Resize to max 1080px width or height
                    const maxDim = 1080;
                    if (width > maxDim || height > maxDim) {
                        if (width > height) {
                            height = Math.round((height * maxDim) / width);
                            width = maxDim;
                        } else {
                            width = Math.round((width * maxDim) / height);
                            height = maxDim;
                        }
                    }

                    canvas.width = width;
                    canvas.height = height;

                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);

                    // Compress to JPEG with 0.8 quality
                    canvas.toBlob((blob) => {
                        if (blob) {
                            resolve(blob);
                        } else {
                            reject(new Error("Canvas toBlob failed"));
                        }
                    }, 'image/jpeg', 0.8);
                };
                img.onerror = (err) => reject(err);
            };
            reader.onerror = (err) => reject(err);
        });
    },

    uuidv4() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
};

if (typeof window !== 'undefined') {
    window.PhotoCapture = PhotoCapture;
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = PhotoCapture;
}
