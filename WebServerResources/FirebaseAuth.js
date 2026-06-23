// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FirebaseAuth.js - Client side Firebase Authentication controller
// Copyright (C) 2026 Graham Lee
//

const devConfig = {
  apiKey: "AIzaSyBDYw9mlmTVqfoGC3z0cBsaQlAcukEwIHY",
  authDomain: "onthewing-eedce.firebaseapp.com",
  projectId: "onthewing-eedce",
  storageBucket: "onthewing-eedce.firebasestorage.app",
  messagingSenderId: "683850194494",
  appId: "1:683850194494:web:e41bf51b06a75ef7e43b6f",
  measurementId: "G-P9YYFNLJN9"
};

const prodConfig = {
  apiKey: "AIzaSyBDYw9mlmTVqfoGC3z0cBsaQlAcukEwIHY",
  authDomain: "onthewing-eedce.firebaseapp.com",
  projectId: "onthewing-eedce",
  storageBucket: "onthewing-eedce.firebasestorage.app",
  messagingSenderId: "683850194494",
  appId: "1:683850194494:web:9916ab916c3dc8d0e43b6f",
  measurementId: "G-SXW0JRP9GC"
};

const FirebaseAuth = {
    init() {
        const isProd = typeof window !== 'undefined' && (window.location.hostname === 'journalonthewing.co.uk' || window.location.hostname === 'www.journalonthewing.co.uk');
        const config = isProd ? prodConfig : devConfig;
        
        if (typeof firebase !== 'undefined') {
            if (!firebase.apps.length) {
                firebase.initializeApp(config);
                if (!isProd) {
                    firebase.auth().useEmulator("http://localhost:9099");
                    firebase.storage().useEmulator("localhost", 9199);
                }
            }
            this.setupListeners();
        }
    },
    
    setupListeners() {
        firebase.auth().onAuthStateChanged(user => {
            this.handleAuthStateChanged(user);
        });
    },
    
    async handleAuthStateChanged(user) {
        if (user) {
            const loginForm = document.getElementById('firebase-login-form');
            if (loginForm) {
                const token = await user.getIdToken();
                const setVal = (id, val) => {
                    const el = document.getElementById(id);
                    if (el) el.value = val;
                };
                setVal('login-uid', user.uid || '');
                setVal('login-name', user.displayName || '');
                setVal('login-email', user.email || '');
                setVal('login-avatarUrl', user.photoURL || '');
                setVal('login-token', token || '');
                
                loginForm.submit();
            }
        }
    },

    async loginWithEmail(email, password) {
        try {
            this.clearErrors();
            await firebase.auth().signInWithEmailAndPassword(email, password);
        } catch (error) {
            this.showError(error.message);
        }
    },

    async registerWithEmail(email, password, displayName) {
        try {
            this.clearErrors();
            const userCredential = await firebase.auth().createUserWithEmailAndPassword(email, password);
            if (displayName) {
                await userCredential.user.updateProfile({
                    displayName: displayName
                });
                const currentUser = firebase.auth().currentUser;
                await this.handleAuthStateChanged(currentUser);
            }
        } catch (error) {
            this.showError(error.message);
        }
    },

    async logout() {
        try {
            if (typeof firebase !== 'undefined') {
                await firebase.auth().signOut();
            }
            const logoutForm = document.getElementById('logout-form');
            if (logoutForm) {
                logoutForm.submit();
            } else {
                window.location.href = '/';
            }
        } catch (error) {
            console.error("Logout failed:", error);
        }
    },

    showError(message) {
        const errEl = document.getElementById('auth-error-message');
        if (errEl) {
            errEl.textContent = message;
            errEl.style.display = 'block';
        }
    },

    clearErrors() {
        const errEl = document.getElementById('auth-error-message');
        if (errEl) {
            errEl.textContent = '';
            errEl.style.display = 'none';
        }
    }
};

if (typeof window !== 'undefined') {
    window.addEventListener('DOMContentLoaded', () => {
        FirebaseAuth.init();
    });
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = FirebaseAuth;
}
