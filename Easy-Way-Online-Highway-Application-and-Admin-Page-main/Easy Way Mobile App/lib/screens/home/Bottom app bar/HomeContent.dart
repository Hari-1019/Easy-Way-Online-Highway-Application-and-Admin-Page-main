import 'package:firebase/screens/QR%20code%20Scanner/scan_code_page.dart';
import 'package:firebase/screens/home/Ordering/shop.dart';
import 'package:firebase/screens/home/maps/normal_map.dart';
import 'package:firebase/screens/home/services.dart';
import 'package:firebase/screens/home/vehicle_register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blue,
      ),
         body: HomeContent(),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  
  // Show emergency confirmation dialog
  void _showEmergencyConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text("Emergency Alert", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to send an emergency alert?", 
                   style: TextStyle(fontSize: 16)),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    Text("This will send your location and details to the admin dashboard immediately.", 
                         style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text("Only use this for real emergencies.", 
                         style: TextStyle(color: Colors.red[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("❌ Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close confirmation dialog
                      _sendEmergencyAlertBackground(); // Send alert
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("🚨 SEND ALERT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Send emergency alert in background without loading dialogs
  Future<void> _sendEmergencyAlertBackground() async {
    try {
      // Show sending message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📡 Sending emergency alert...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Get location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showSimpleError("Location permission required for emergency alerts.");
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get user info
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSimpleError("User not authenticated.");
        return;
      }

      String userId = currentUser.uid;
      String userEmail = currentUser.email ?? "unknown@email.com";
      
      // Get user profile data
      DatabaseReference userRef = FirebaseDatabase.instance.ref("user_profile").child(userId);
      DataSnapshot userSnapshot = await userRef.get();
      
      String userName = "Unknown User";
      String userPhone = "Unknown Phone";
      String userAddress = "Unknown Address";
      
      if (userSnapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        userName = userData['name'] ?? "Unknown User";
        userPhone = userData['phone'] ?? "Unknown Phone";
        userAddress = userData['address'] ?? "Unknown Address";
      }

      // Send to Firebase
      DatabaseReference emergencyRef = FirebaseDatabase.instance.ref("emergency_alerts");
      String alertId = emergencyRef.push().key!;
      
      await emergencyRef.child(alertId).set({
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'user_address': userAddress,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'active',
        'alert_type': 'emergency',
        'location_accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'address_coordinates': 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Emergency alert sent successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      _showSimpleError("Failed to send emergency alert: ${e.toString()}");
    }
  }

  void _showSimpleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              "",
              style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          
          // Start Ride Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            ),
            onPressed: () async {
              DatabaseReference databaseRef = FirebaseDatabase.instance.ref('vehicle_registration');
              User? user = FirebaseAuth.instance.currentUser;
      
              DataSnapshot snapshot = await databaseRef.child(user!.uid).get();
      
              if (!snapshot.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No vehicle registered. Please register your vehicle first.')),
                );
                return;
              }
      
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HighwayEntranceCodeScanScreen(
                        qrCode: '',
                      ),
                  ));
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("START RIDE",
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20)),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/ride.png',
                  width: 40,  // Adjust the width as needed
                  height: 40, // Adjust the height as needed
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Emergency Alert Button
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.5),
              ),
              onPressed: () async {
                // Show confirmation dialog first
                _showEmergencyConfirmation();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    "🚨 EMERGENCY ALERT",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // GridView with 4 buttons
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildGridButton("Vehicle Registrations", 'assets/images/vehicle.png', context),
              _buildGridButton("Ordering", 'assets/images/ordering.png', context),
              _buildGridButton("Road Map", 'assets/images/map.png', context),
              _buildGridButton("Services", 'assets/images/services.png', context),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build individual grid buttons with images
  Widget _buildGridButton(String title, String imagePath, BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(20),
      ),
      onPressed: () {
        if (title == "Vehicle Registrations") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleRegisterPage()),
          );
        } else if (title == "Ordering") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShoppingCenterPage(),
            ),
          );
        } else if (title == "Road Map") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NormalMapPage(
                qrCode: '',
              ),
            ),
          );
        } else if (title == "Services") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ServicePage(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 55,
            height: 55,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
