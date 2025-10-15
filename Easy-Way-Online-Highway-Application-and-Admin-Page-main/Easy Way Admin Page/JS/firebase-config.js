// Firebase Configuration for Admin Dashboard
const firebaseConfig = {
    apiKey: "AIzaSyCbHTRknLUKcrJJdTfQDmhVE7Rrl7qNp8c",
    authDomain: "flutter-firebase-test-67eab.firebaseapp.com",
    databaseURL: "https://flutter-firebase-test-67eab-default-rtdb.firebaseio.com",
    projectId: "flutter-firebase-test-67eab",
    storageBucket: "flutter-firebase-test-67eab.firebasestorage.app",
    messagingSenderId: "448579172727",
    appId: "1:448579172727:web:bb93e7b03c130d4b8b81d8",
    measurementId: "G-4X8BVNG58J"
};

// Initialize Firebase
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}

// Get Firebase services (only database needed for admin panel)
const database = firebase.database();

// Export for use in other files
window.firebaseDatabase = database;

console.log('🔥 Firebase initialized successfully for Admin Dashboard');
console.log('📊 Ready to monitor existing tables: user_profile, payments, vehicle_registration');