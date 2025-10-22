// Firebase configuration
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

// Initialize Firebase and setup login
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Firebase
    if (!firebase.apps.length) {
        firebase.initializeApp(firebaseConfig);
    }
    
    console.log('🔥 Firebase initialized for admin login');
    
    // Setup login form
    const loginForm = document.getElementById("loginForm");
    
    if (loginForm) {
        loginForm.addEventListener("submit", async function (event) {
            event.preventDefault();
            
            const emailField = document.getElementById("email");
            const passwordField = document.getElementById("password");
            const submitBtn = document.getElementById("submit");
            
            const email = emailField.value.trim();
            const password = passwordField.value.trim();
            
            // Clear any previous error messages
            removeErrorMessage();
            
            // Disable submit button
            submitBtn.disabled = true;
            submitBtn.textContent = '⏳ Logging in...';
            
            try {
                console.log('🔍 Attempting login for:', email);
                
                // Get Firebase database reference
                const database = firebase.database();
                
                // Check admin credentials
                const adminSnapshot = await database.ref('admin_users').once('value');
                const admins = adminSnapshot.val();
                
                console.log('📊 Checking admin users...');
                
                let validAdmin = null;
                if (admins) {
                    for (const adminId in admins) {
                        const admin = admins[adminId];
                        console.log(`Checking admin: ${admin.email}`);
                        
                        if (admin.email === email && admin.password === password && admin.is_active) {
                            validAdmin = admin;
                            validAdmin.id = adminId;
                            console.log('✅ Valid admin found!');
                            break;
                        }
                    }
                }
                
                if (validAdmin) {
                    // Update last login
                    try {
                        await database.ref(`admin_users/${validAdmin.id}/last_login`).set(new Date().toISOString());
                    } catch (error) {
                        console.log('⚠️ Could not update last login:', error.message);
                    }
                    
                    // Store session data
                    sessionStorage.setItem('adminId', validAdmin.id);
                    sessionStorage.setItem('adminEmail', validAdmin.email);
                    sessionStorage.setItem('adminName', validAdmin.name || 'Admin');
                    sessionStorage.setItem('adminRole', validAdmin.role || 'admin');
                    
                    // Log successful login
                    console.log('🎉 LOGIN SUCCESS');
                    console.log('📧 Email:', validAdmin.email);
                    console.log('👤 Name:', validAdmin.name);
                    console.log('🎯 Role:', validAdmin.role);
                    
                    // Redirect to dashboard
                    window.location.href = 'admin-dashboard.html';
                    
                } else {
                    // Login failed
                    console.log('❌ LOGIN FAILED - Invalid credentials');
                    showErrorMessage('Invalid email or password. Please check your credentials.');
                }
                
            } catch (error) {
                console.error('❌ Login error:', error);
                showErrorMessage('Login failed. Please try again.');
            } finally {
                // Re-enable submit button
                submitBtn.disabled = false;
                submitBtn.textContent = '🔐 Secure Login';
            }
        });
    }
});

// Helper function to show error messages
function showErrorMessage(message) {
    removeErrorMessage();
    
    const form = document.getElementById('loginForm');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.style.cssText = `
        background: #ffebee;
        color: #c62828;
        padding: 10px;
        border-radius: 5px;
        margin: 10px 0;
        border-left: 4px solid #c62828;
        font-size: 14px;
    `;
    errorDiv.textContent = message;
    
    form.appendChild(errorDiv);
}

// Helper function to remove error messages
function removeErrorMessage() {
    const existingError = document.querySelector('.error-message');
    if (existingError) {
        existingError.remove();
    }
}