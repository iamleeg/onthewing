// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseAuth.test.js - Unit tests for FirebaseAuth.js
// Copyright (C) 2026 Graham Lee
//

const FirebaseAuth = require('../WebServerResources/FirebaseAuth.js');

describe('FirebaseAuth', () => {
    let mockForm, mockInputs;

    beforeEach(() => {
        // Reset globals and mock DOM elements
        global.window = {
            location: {
                hostname: 'localhost'
            },
            addEventListener: jest.fn()
        };

        mockInputs = {
            'login-uid': { value: '' },
            'login-name': { value: '' },
            'login-email': { value: '' },
            'login-avatarUrl': { value: '' },
            'login-token': { value: '' }
        };

        mockForm = {
            submit: jest.fn()
        };

        global.document = {
            getElementById: jest.fn((id) => {
                if (id === 'firebase-login-form' || id === 'logout-form') return mockForm;
                return mockInputs[id] || null;
            }),
            forms: [mockForm]
        };

        // Mock Firebase Auth SDK
        const mockAuth = {
            onAuthStateChanged: jest.fn(),
            signInWithEmailAndPassword: jest.fn().mockResolvedValue({}),
            createUserWithEmailAndPassword: jest.fn().mockResolvedValue({
                user: {
                    updateProfile: jest.fn().mockResolvedValue({})
                }
            }),
            signOut: jest.fn().mockResolvedValue({}),
            currentUser: {
                uid: 'user123',
                displayName: 'Test User',
                email: 'test@example.com',
                photoURL: 'avatar.jpg',
                getIdToken: jest.fn().mockResolvedValue('jwt123')
            }
        };

        global.firebase = {
            apps: [],
            initializeApp: jest.fn(function() {
                this.apps.push({});
            }),
            auth: jest.fn(() => mockAuth)
        };
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('init', () => {
        it('should choose devConfig on localhost', () => {
            global.window.location.hostname = 'localhost';
            FirebaseAuth.init();
            expect(global.firebase.initializeApp).toHaveBeenCalledWith(expect.objectContaining({
                projectId: 'onthewing-eedce',
                appId: '1:683850194494:web:e41bf51b06a75ef7e43b6f' // dev appId
            }));
        });

        it('should choose prodConfig on production domain', () => {
            global.window.location.hostname = 'journalonthewing.co.uk';
            FirebaseAuth.init();
            expect(global.firebase.initializeApp).toHaveBeenCalledWith(expect.objectContaining({
                projectId: 'onthewing-eedce',
                appId: '1:683850194494:web:9916ab916c3dc8d0e43b6f' // prod appId
            }));
        });
    });

    describe('handleAuthStateChanged', () => {
        it('should populate login form and submit when user is authenticated', async () => {
            FirebaseAuth.init();
            
            const mockUser = {
                uid: 'uid-456',
                displayName: 'Jane Doe',
                email: 'jane@example.com',
                photoURL: 'jane.jpg',
                getIdToken: jest.fn().mockResolvedValue('token-abc')
            };

            await FirebaseAuth.handleAuthStateChanged(mockUser);

            expect(mockInputs['login-uid'].value).toBe('uid-456');
            expect(mockInputs['login-name'].value).toBe('Jane Doe');
            expect(mockInputs['login-email'].value).toBe('jane@example.com');
            expect(mockInputs['login-avatarUrl'].value).toBe('jane.jpg');
            expect(mockInputs['login-token'].value).toBe('token-abc');
            expect(mockForm.submit).toHaveBeenCalled();
        });
    });

    describe('loginWithEmail', () => {
        it('should call signInWithEmailAndPassword', async () => {
            FirebaseAuth.init();
            await FirebaseAuth.loginWithEmail('test@example.com', 'password');
            expect(global.firebase.auth().signInWithEmailAndPassword).toHaveBeenCalledWith('test@example.com', 'password');
        });
    });

    describe('registerWithEmail', () => {
        it('should call createUserWithEmailAndPassword', async () => {
            FirebaseAuth.init();
            await FirebaseAuth.registerWithEmail('test@example.com', 'password', 'Test User');
            expect(global.firebase.auth().createUserWithEmailAndPassword).toHaveBeenCalledWith('test@example.com', 'password');
        });
    });

    describe('logout', () => {
        it('should call signOut and submit logout form', async () => {
            FirebaseAuth.init();
            await FirebaseAuth.logout();
            expect(global.firebase.auth().signOut).toHaveBeenCalled();
            expect(mockForm.submit).toHaveBeenCalled();
        });
    });
});
