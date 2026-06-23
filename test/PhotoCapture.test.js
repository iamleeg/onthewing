const PhotoCapture = require('../WebServerResources/PhotoCapture.js');

describe('PhotoCapture', () => {
    let mockForm, mockInputs, mockFile, mockBlob, mockStatus;

    beforeEach(() => {
        // Reset globals
        mockInputs = {
            'photo-url-123': { value: '' },
            'photo-action-123': { value: '' }
        };

        mockForm = {
            submit: jest.fn()
        };

        mockStatus = {
            textContent: '',
            style: { display: 'none', color: '' }
        };

        global.document = {
            getElementById: jest.fn((id) => {
                if (id === 'photo-form-123') return mockForm;
                if (id === 'upload-status-123') return mockStatus;
                return mockInputs[id] || null;
            })
        };

        mockFile = new Blob(['dummy content'], { type: 'image/jpeg' });
        mockBlob = new Blob(['compressed content'], { type: 'image/jpeg' });

        // Mock FileReader
        global.FileReader = class {
            readAsDataURL() {
                setTimeout(() => {
                    if (this.onload) {
                        this.onload({ target: { result: 'data:image/jpeg;base64,abc' } });
                    }
                }, 0);
            }
        };

        // Mock Image
        global.Image = class {
            constructor() {
                setTimeout(() => {
                    this.width = 2000;
                    this.height = 1000;
                    this.onload();
                }, 0);
            }
        };

        // Mock HTMLCanvasElement / CanvasRenderingContext2D
        const mockContext = {
            drawImage: jest.fn()
        };
        global.document.createElement = jest.fn((tag) => {
            if (tag === 'canvas') {
                return {
                    width: 0,
                    height: 0,
                    getContext: () => mockContext,
                    toBlob: jest.fn((callback) => callback(mockBlob))
                };
            }
            return {};
        });

        // Mock Firebase SDK
        const mockSnapshot = {
            ref: {
                getDownloadURL: jest.fn().mockResolvedValue('https://firebase.com/temp/user123/img.jpg')
            }
        };
        const mockStorageRef = {
            child: jest.fn(() => mockStorageRef),
            put: jest.fn().mockResolvedValue(mockSnapshot)
        };
        const mockStorage = {
            ref: () => mockStorageRef
        };
        const mockAuth = {
            currentUser: { uid: 'user123' }
        };

        global.firebase = {
            auth: () => mockAuth,
            storage: () => mockStorage
        };
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('compressImage', () => {
        it('should load file and resize it on canvas', async () => {
            const blob = await PhotoCapture.compressImage(mockFile);
            expect(blob).toBe(mockBlob);
            expect(global.document.createElement).toHaveBeenCalledWith('canvas');
        });
    });

    describe('handleFileSelect', () => {
        it('should upload compressed file and submit form', async () => {
            const mockEvent = {
                target: {
                    files: [mockFile]
                }
            };

            await PhotoCapture.handleFileSelect(
                mockEvent,
                '123',
                'photo-form-123',
                'photo-url-123',
                'photo-action-123',
                'upload-status-123'
            );

            expect(mockInputs['photo-url-123'].value).toBe('https://firebase.com/temp/user123/img.jpg');
            expect(mockInputs['photo-action-123'].value).toBe('upload');
            expect(mockForm.submit).toHaveBeenCalled();
            expect(mockStatus.textContent).toBe('Uploading...');
        });

        it('should show error message if upload fails', async () => {
            const mockEvent = {
                target: {
                    files: [mockFile]
                }
            };

            // Force Firebase to throw
            global.firebase.storage = () => {
                throw new Error('Network error');
            };

            await PhotoCapture.handleFileSelect(
                mockEvent,
                '123',
                'photo-form-123',
                'photo-url-123',
                'photo-action-123',
                'upload-status-123'
            );

            expect(mockStatus.textContent).toContain('Upload failed');
            expect(mockStatus.style.color).toBe('red');
            expect(mockForm.submit).not.toHaveBeenCalled();
        });
    });

    describe('removePhoto', () => {
        it('should clear URL, set action to remove, and submit form', async () => {
            mockInputs['photo-url-123'].value = 'some-url';

            await PhotoCapture.removePhoto(
                'photo-form-123',
                'photo-url-123',
                'photo-action-123'
            );

            expect(mockInputs['photo-url-123'].value).toBe('');
            expect(mockInputs['photo-action-123'].value).toBe('remove');
            expect(mockForm.submit).toHaveBeenCalled();
        });
    });
});
