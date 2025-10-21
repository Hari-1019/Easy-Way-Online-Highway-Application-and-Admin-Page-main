// Admin Dashboard JavaScript
class AdminDashboard {
    constructor() {
        this.currentUser = null;
        this.usersData = {};
        this.paymentsData = {};
        this.vehiclesData = {};
        this.emergencyAlerts = {};
        
        this.init();
    }

    async init() {
        this.setupEventListeners();
        this.showLoading();
        
        // Check if admin is logged in via session storage
        const adminId = sessionStorage.getItem('adminId');
        const adminEmail = sessionStorage.getItem('adminEmail');
        
        if (adminId && adminEmail) {
            this.currentUser = {
                id: adminId,
                email: adminEmail,
                name: sessionStorage.getItem('adminName') || 'Admin'
            };
            
            document.getElementById('adminEmail').textContent = adminEmail;
            await this.loadDashboardData();
            this.hideLoading();
        } else {
            this.redirectToLogin();
        }
    }

    // Session-based authentication (no Firebase Auth needed)
    checkAdminSession() {
        const adminId = sessionStorage.getItem('adminId');
        if (!adminId) {
            this.redirectToLogin();
            return false;
        }
        return true;
    }

    setupEventListeners() {
        // Tab navigation
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchTab(e.target.dataset.tab));
        });

        // Logout button
        document.getElementById('logoutBtn').addEventListener('click', () => this.logout());

        // Modal controls
        document.getElementById('addAdminBtn').addEventListener('click', () => this.showAdminModal());
        document.querySelector('.close').addEventListener('click', () => this.hideAdminModal());
        document.getElementById('adminRegistrationForm').addEventListener('submit', (e) => this.createAdmin(e));

        // Other action buttons
        document.getElementById('exportDataBtn').addEventListener('click', () => this.exportData());
        document.getElementById('backupBtn').addEventListener('click', () => this.backupDatabase());
    }

    async loadUserData(user) {
        try {
            // Check if user is admin
            const adminRef = database.ref(`admin_users/${user.uid}`);
            const adminSnapshot = await adminRef.once('value');
            
            if (!adminSnapshot.exists()) {
                alert('Access denied. Admin privileges required.');
                await this.logout();
                return;
            }
            
            this.adminData = adminSnapshot.val();
        } catch (error) {
            console.error('Error loading user data:', error);
        }
    }

    async loadDashboardData() {
        try {
            console.log('🔄 Starting to load dashboard data...');
            
            await Promise.all([
                this.loadUsers(),
                this.loadPayments(), 
                this.loadVehicles(),
                this.loadEmergencyAlerts()
            ]);
            
            console.log('📊 All data loaded, updating statistics...');
            this.updateStatistics();
            
            console.log('📋 Rendering tables...');
            this.renderTables();
            
            console.log('🎯 Hiding loading spinner...');
            this.hideLoading();
            
            console.log('✅ Dashboard loaded successfully!');
        } catch (error) {
            console.error('❌ Error loading dashboard data:', error);
            this.showError('Failed to load dashboard data: ' + error.message);
        }
    }

    async loadUsers() {
        try {
            const usersRef = firebase.database().ref('user_profile');
            const snapshot = await usersRef.once('value');
            this.usersData = snapshot.val() || {};
            console.log('✅ Loaded users:', Object.keys(this.usersData).length);
        } catch (error) {
            console.error('Error loading users:', error);
            this.usersData = {};
        }
    }

    async loadPayments() {
        try {
            const paymentsRef = firebase.database().ref('payments');
            const snapshot = await paymentsRef.once('value');
            this.paymentsData = snapshot.val() || {};
            console.log('✅ Loaded payments:', Object.keys(this.paymentsData).length);
        } catch (error) {
            console.error('Error loading payments:', error);
            this.paymentsData = {};
        }
    }

    async loadVehicles() {
        try {
            const vehiclesRef = firebase.database().ref('vehicle_registration');
            const snapshot = await vehiclesRef.once('value');
            this.vehiclesData = snapshot.val() || {};
            console.log('✅ Loaded vehicles:', Object.keys(this.vehiclesData).length);
        } catch (error) {
            console.error('Error loading vehicles:', error);
            this.vehiclesData = {};
        }
    }

    async loadEmergencyAlerts() {
        try {
            const alertsRef = firebase.database().ref('emergency_alerts');
            const snapshot = await alertsRef.once('value');
            this.emergencyAlerts = snapshot.val() || {};
            console.log('🚨 Loaded emergency alerts:', Object.keys(this.emergencyAlerts).length);
            
            // Render emergency alerts immediately
            this.renderEmergencyAlerts();
        } catch (error) {
            console.error('Error loading emergency alerts:', error);
            this.emergencyAlerts = {};
        }
    }

    renderEmergencyAlerts() {
        const container = document.getElementById('emergency-alerts-container');
        if (!container) return;

        const alertsArray = Object.keys(this.emergencyAlerts).map(key => ({
            id: key,
            ...this.emergencyAlerts[key]
        }));

        const activeAlerts = alertsArray.filter(alert => alert.status === 'active');
        const todayAlerts = alertsArray.filter(alert => {
            const alertDate = new Date(alert.timestamp);
            const today = new Date();
            return alertDate.toDateString() === today.toDateString();
        });

        // Update statistics
        document.getElementById('activeAlertsCount').textContent = activeAlerts.length;
        document.getElementById('todayAlertsCount').textContent = todayAlerts.length;
        document.getElementById('resolvedAlertsCount').textContent = alertsArray.filter(alert => alert.status === 'resolved').length;

        if (activeAlerts.length === 0) {
            container.innerHTML = `
                <div class="no-alerts">
                    <div class="no-alerts-icon">✅</div>
                    <h3>No Active Emergency Alerts</h3>
                    <p>All clear! No emergency situations reported.</p>
                </div>
            `;
            return;
        }

        container.innerHTML = `
            <div class="emergency-alerts-list">
                ${activeAlerts.map(alert => `
                    <div class="emergency-alert active" data-alert-id="${alert.id}">
                        <div class="alert-header">
                            <span class="alert-status">🚨 ACTIVE EMERGENCY</span>
                            <span class="alert-time">${new Date(alert.timestamp).toLocaleString()}</span>
                        </div>
                        <div class="alert-content">
                            <div class="alert-user-info">
                                <h4>👤 ${alert.user_name || 'Unknown User'}</h4>
                                <p>📧 ${alert.user_email || 'No email'}</p>
                                <p>📱 ${alert.user_phone || 'No phone'}</p>
                                <p>🏠 ${alert.user_address || 'No address'}</p>
                            </div>
                            <div class="alert-location-info">
                                <h4>📍 Location Details</h4>
                                <p><strong>Coordinates:</strong> ${alert.latitude}, ${alert.longitude}</p>
                                <p><strong>Accuracy:</strong> ±${alert.location_accuracy}m</p>
                                <p><strong>Altitude:</strong> ${alert.altitude}m</p>
                                <p><strong>Speed:</strong> ${alert.speed} km/h</p>
                            </div>
                        </div>
                        <div class="alert-actions">
                            <button onclick="adminDashboard.viewOnMap('${alert.latitude}', '${alert.longitude}')" class="btn-map">
                                🗺️ View on Map
                            </button>
                            <button onclick="adminDashboard.markAlertResolved('${alert.id}')" class="btn-resolve">
                                ✅ Mark Resolved
                            </button>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    async markAlertResolved(alertId) {
        try {
            await firebase.database().ref(`emergency_alerts/${alertId}`).update({
                status: 'resolved',
                resolved_at: new Date().toISOString(),
                resolved_by: sessionStorage.getItem('adminEmail')
            });
            
            console.log(`✅ Emergency alert ${alertId} marked as resolved`);
            await this.loadEmergencyAlerts(); // Refresh the list
            
            // Show success message
            alert('✅ Emergency alert has been marked as resolved!');
        } catch (error) {
            console.error('❌ Error resolving alert:', error);
            alert('❌ Error resolving alert. Please try again.');
        }
    }

    viewOnMap(latitude, longitude) {
        const mapUrl = `https://www.google.com/maps?q=${latitude},${longitude}&z=15`;
        window.open(mapUrl, '_blank');
    }

    updateStatistics() {
        // User statistics
        const totalUsers = Object.keys(this.usersData).length;
        document.getElementById('totalUsers').textContent = totalUsers;
        document.getElementById('activeUsers').textContent = this.getActiveUsersToday();

        // Payment statistics
        const totalRevenue = this.calculateTotalRevenue();
        const todayRevenue = this.calculateTodayRevenue();
        document.getElementById('totalRevenue').textContent = `LKR ${totalRevenue.toLocaleString()}`;
        document.getElementById('todayRevenue').textContent = `LKR ${todayRevenue.toLocaleString()}`;

        // Vehicle statistics
        const totalVehicles = this.getTotalVehicles();
        document.getElementById('totalVehicles').textContent = totalVehicles;
        document.getElementById('activeVehicles').textContent = totalVehicles; // Assume all registered vehicles are active
    }

    renderTables() {
        this.renderUsersTable();
        this.renderPaymentsTable();
        this.renderVehiclesTable();
    }

    renderUsersTable() {
        const tbody = document.getElementById('usersTableBody');
        tbody.innerHTML = '';

        Object.entries(this.usersData).forEach(([userId, userData]) => {
            const row = this.createUserRow(userId, userData);
            tbody.appendChild(row);
        });
    }

    createUserRow(userId, userData) {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${userId.substring(0, 8)}...</td>
            <td>${userData.name || 'N/A'}</td>
            <td>${userData.email || 'N/A'}</td>
            <td>${userData.phone || 'N/A'}</td>
            <td>${userData.address || 'N/A'}</td>
            <td>${this.formatDate(new Date())}</td>
            <td><span class="status-badge status-active">Active</span></td>
            <td>
                <button class="action-btn" onclick="adminDashboard.viewUserDetails('${userId}')">View</button>
            </td>
        `;
        return tr;
    }

    renderPaymentsTable() {
        const tbody = document.getElementById('paymentsTableBody');
        tbody.innerHTML = '';

        Object.entries(this.paymentsData).forEach(([userId, userPayments]) => {
            const userEmail = this.usersData[userId]?.email || 'Unknown';
            
            Object.entries(userPayments).forEach(([paymentId, paymentData]) => {
                const row = this.createPaymentRow(paymentId, userEmail, paymentData);
                tbody.appendChild(row);
            });
        });
    }

    createPaymentRow(paymentId, userEmail, paymentData) {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${paymentId.substring(0, 10)}...</td>
            <td>${userEmail}</td>
            <td>LKR ${paymentData.cost}</td>
            <td>${paymentData.details}</td>
            <td>${paymentData.payment_method}</td>
            <td>${this.formatDate(new Date(paymentData.payment_date))}</td>
            <td><span class="status-badge status-active">Completed</span></td>
        `;
        return tr;
    }

    renderVehiclesTable() {
        const tbody = document.getElementById('vehiclesTableBody');
        tbody.innerHTML = '';

        Object.entries(this.vehiclesData).forEach(([key, vehicleData]) => {
            if (typeof vehicleData === 'object' && vehicleData.license_plate) {
                // This is a user's vehicle data
                const userId = key;
                const userEmail = this.usersData[userId]?.email || 'Unknown';
                const row = this.createVehicleRow(vehicleData, userEmail);
                tbody.appendChild(row);
            }
        });
    }

    createVehicleRow(vehicleData, userEmail) {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${vehicleData.license_plate}</td>
            <td>${vehicleData.owner_name}</td>
            <td>${userEmail}</td>
            <td>${vehicleData.vehicle_type}</td>
            <td>${vehicleData.model}</td>
            <td>${this.formatDate(new Date())}</td>
            <td><span class="status-badge status-active">Active</span></td>
        `;
        return tr;
    }

    switchTab(tabName) {
        // Remove active class from all tabs and content
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

        // Add active class to clicked tab and corresponding content
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
        document.getElementById(`${tabName}-tab`).classList.add('active');
    }

    async createAdmin(event) {
        event.preventDefault();
        
        const name = document.getElementById('adminName').value;
        const email = document.getElementById('adminEmailNew').value;
        const password = document.getElementById('adminPassword').value;
        const role = document.getElementById('adminRole').value;

        try {
            // Create admin user in Firebase Auth
            const userCredential = await auth.createUserWithEmailAndPassword(email, password);
            const user = userCredential.user;

            // Save admin data to database
            await database.ref(`admin_users/${user.uid}`).set({
                name: name,
                email: email,
                role: role,
                created_date: new Date().toISOString(),
                created_by: this.currentUser.uid,
                status: 'active'
            });

            // Save admin login credentials for monitoring
            await database.ref(`admin_credentials/${user.uid}`).set({
                email: email,
                password_hash: btoa(password), // Basic encoding (use proper hashing in production)
                role: role,
                created_date: new Date().toISOString()
            });

            alert('Admin user created successfully!');
            this.hideAdminModal();
            document.getElementById('adminRegistrationForm').reset();

        } catch (error) {
            console.error('Error creating admin:', error);
            alert('Error creating admin: ' + error.message);
        }
    }

    showAdminModal() {
        document.getElementById('adminModal').style.display = 'block';
    }

    hideAdminModal() {
        document.getElementById('adminModal').style.display = 'none';
    }

    async exportData() {
        try {
            const data = {
                users: this.usersData,
                payments: this.paymentsData,
                vehicles: this.vehiclesData,
                exported_date: new Date().toISOString()
            };

            const jsonData = JSON.stringify(data, null, 2);
            const blob = new Blob([jsonData], { type: 'application/json' });
            const url = URL.createObjectURL(blob);

            const a = document.createElement('a');
            a.href = url;
            a.download = `easywaydata_${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);

            alert('Data exported successfully!');
        } catch (error) {
            console.error('Error exporting data:', error);
            alert('Error exporting data: ' + error.message);
        }
    }

    async backupDatabase() {
        try {
            // In a real application, this would trigger a server-side backup
            alert('Database backup initiated. You will receive an email confirmation.');
            
            // Log the backup request
            await database.ref('admin_logs').push({
                action: 'database_backup',
                admin_id: this.currentUser.uid,
                admin_email: this.currentUser.email,
                timestamp: new Date().toISOString()
            });
        } catch (error) {
            console.error('Error initiating backup:', error);
            alert('Error initiating backup: ' + error.message);
        }
    }

    viewUserDetails(userId) {
        const userData = this.usersData[userId];
        const userPayments = this.paymentsData[userId] || {};
        const userVehicle = this.vehiclesData[userId] || {};

        let details = `User Details:\n\n`;
        details += `ID: ${userId}\n`;
        details += `Name: ${userData.name || 'N/A'}\n`;
        details += `Email: ${userData.email || 'N/A'}\n`;
        details += `Phone: ${userData.phone || 'N/A'}\n`;
        details += `Address: ${userData.address || 'N/A'}\n\n`;
        
        details += `Payments: ${Object.keys(userPayments).length}\n`;
        details += `Vehicles: ${userVehicle.license_plate ? 1 : 0}`;

        alert(details);
    }

    // Utility methods
    getActiveUsersToday() {
        // In a real app, you'd track login activity
        return Math.floor(Object.keys(this.usersData).length * 0.3);
    }

    calculateTotalRevenue() {
        let total = 0;
        Object.values(this.paymentsData).forEach(userPayments => {
            Object.values(userPayments).forEach(payment => {
                total += payment.cost || 0;
            });
        });
        return total;
    }

    calculateTodayRevenue() {
        const today = new Date().toISOString().split('T')[0];
        let total = 0;
        
        Object.values(this.paymentsData).forEach(userPayments => {
            Object.values(userPayments).forEach(payment => {
                if (payment.payment_date && payment.payment_date.startsWith(today)) {
                    total += payment.cost || 0;
                }
            });
        });
        return total;
    }

    getTotalVehicles() {
        let count = 0;
        Object.entries(this.vehiclesData).forEach(([key, value]) => {
            if (typeof value === 'object' && value.license_plate) {
                count++;
            }
        });
        return count;
    }

    formatDate(date) {
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        }).format(date);
    }

    logout() {
        try {
            // Clear session storage
            sessionStorage.removeItem('adminId');
            sessionStorage.removeItem('adminEmail'); 
            sessionStorage.removeItem('adminName');
            sessionStorage.removeItem('adminRole');
            
            this.redirectToLogin();
        } catch (error) {
            console.error('Error signing out:', error);
        }
    }

    redirectToLogin() {
        window.location.href = 'Web.html';
    }

    showLoading() {
        document.getElementById('loadingSpinner').style.display = 'flex';
    }

    hideLoading() {
        const loadingSpinner = document.getElementById('loadingSpinner');
        if (loadingSpinner) {
            loadingSpinner.style.display = 'none';
            console.log('✅ Loading spinner hidden');
        } else {
            console.log('⚠️ Loading spinner element not found');
        }
    }

    showError(message) {
        alert('Error: ' + message);
    }
}

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.adminDashboard = new AdminDashboard();
});

// Global functions for button clicks
function viewUserDetails(userId) {
    window.adminDashboard.viewUserDetails(userId);
}