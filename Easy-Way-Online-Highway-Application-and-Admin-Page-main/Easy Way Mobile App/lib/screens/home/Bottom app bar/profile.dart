import 'package:firebase/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // ignore: non_constant_identifier_names
  String user_id = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool isProfileSaved = false;
  bool isLoading = false;
  final AuthServices _authServices = AuthServices();
  late final DatabaseReference userRef;

  late final DatabaseReference _databaseReference;

  @override
  void initState() {
    super.initState();
    userRef = FirebaseDatabase.instance
        .ref()
        .child('user_profile')
        .child(_authServices.userID);
    _databaseReference = FirebaseDatabase.instance.ref("user_profile");
  fetchCurrentUser();
  fetchUserData();
        profileExists().then((exists) {
          setState(() {
            isProfileSaved = exists;
          });
        });
      }

  Future<void> fetchCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _emailController.text = currentUser.email ?? '';
        });
      } else {
        print('No user is logged in.');
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }

  Future<bool> profileExists() async {
    final snapshot = await _databaseReference.get();
    return snapshot.exists;
  }

 Future<void> fetchUserData() async {
  try {
    final DatabaseEvent event = await userRef.once();
    if (event.snapshot.exists) {
      final Map<String, dynamic> userData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
      });
    } else {
      showSnackbar('User profile not found.');
    }
  } catch (e) {
    showSnackbar('Error fetching user data: $e');
  }
}

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = _authServices.userID;
      if (userId.isEmpty) {
        showSnackbar('User not logged in');
        return;
      }

      await userRef.set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });

      setState(() {
        isProfileSaved = true;
      });

      showSnackbar('Profile saved successfully');
    } catch (e) {
      showSnackbar('Error saving profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await userRef.update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });

      showSnackbar('Profile updated successfully');
    } catch (e) {
      showSnackbar('Error updating profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 40),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange[900]!,
              Colors.orange[800]!,
              Colors.orange[400]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Center(
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: AssetImage(
                      'assets/images/logo.png',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                buildTextFormField(
                  label: "Name",
                  isReadOnly: false,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                buildTextFormField(
                  isReadOnly: true,
                  label: "Email",
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                buildTextFormField(
                  isReadOnly: false,
                  label: "Phone Number",
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    } else if (!RegExp(r"^[0-9]{10}$").hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                buildTextFormField(
                  isReadOnly: false,
                  label: "Address",
                  controller: _addressController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[900],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (isProfileSaved) {
                                updateProfileData();
                              } else {
                                saveProfileData();
                              }
                            }
                          },
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(isProfileSaved ? Icons.update : Icons.save),
                    label: Text(
                      isProfileSaved ? 'Update Profile' : 'Save Changes',
                      style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextFormField({
    required String label,
    required String? Function(String?) validator,
    required bool isReadOnly,
    TextEditingController? controller,
  }) {
    return TextFormField(
      readOnly: isReadOnly,
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
