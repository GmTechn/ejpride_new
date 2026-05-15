import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/elements/mytextfield.dart';
import 'package:ejp_ride_version/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileSetUpPage extends StatefulWidget {
  final String role;

  const ProfileSetUpPage({super.key, required this.role});

  @override
  State<ProfileSetUpPage> createState() => _ProfileSetUpPageState();
}

class _ProfileSetUpPageState extends State<ProfileSetUpPage> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  File? _profileImage;

  String? selectedZone;

  bool isLoading = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  final carModelController = TextEditingController();
  final carColorController = TextEditingController();
  final plateNumberController = TextEditingController();

  final List<String> zones = [
    'Hull',
    'Gatineau-Gatineau',
    'Plateau - Aylmer',
    'Ottawa Est',
    'Orléans',
  ];

  bool get isDriver => widget.role == 'driver';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    final CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        IOSUiSettings(title: 'Crop Profile Picture'),
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          lockAspectRatio: true,
        ),
      ],
    );

    if (croppedImage != null) {
      setState(() {
        _profileImage = File(croppedImage.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 38, 38, 60),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.photo,
                    color: Colors.green,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickImage(ImageSource.gallery);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    CupertinoIcons.camera,
                    color: Colors.green,
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found. Please login again.')),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final profileData = {
      'uid': user.uid,
      'email': user.email,
      'role': widget.role,
      'fullName': fullNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'zone': selectedZone,
      'profileImagePath': _profileImage?.path,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (isDriver) {
      profileData.addAll({
        'carModel': carModelController.text.trim(),
        'carColor': carColorController.text.trim(),
        'plateNumber': plateNumberController.text.trim(),
      });
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profileData);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          role: widget.role,
          name: fullNameController.text.trim(),
          email: user.email ?? '',
          zone: selectedZone!,
          phone: phoneController.text.trim(),
          profileImage: _profileImage, // TEMPORAIRE pour éviter crash mémoire
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isDriver ? 'Driver Profile' : 'Passenger Profile';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,

                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color.fromARGB(255, 38, 38, 60),

                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,

                    child: _profileImage == null
                        ? const Icon(
                            CupertinoIcons.camera,
                            color: Colors.white70,
                            size: 42,
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: _showImagePickerOptions,

                  child: const Text(
                    'Add profile picture',
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  controller: fullNameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                MyTextFormField(
                  controller: phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  keyboardType: TextInputType.phone,

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _ZoneDropdown(
                  value: selectedZone,
                  zones: zones,

                  onChanged: (value) {
                    setState(() {
                      selectedZone = value;
                    });
                  },
                ),

                if (isDriver) ...[
                  const SizedBox(height: 14),

                  MyTextFormField(
                    controller: carModelController,
                    labelText: 'Car Make / Model',
                    hintText: 'Example: Toyota Corolla',

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Car make/model is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  MyTextFormField(
                    controller: carColorController,
                    labelText: 'Car Color',
                    hintText: 'Example: Black',

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Car color is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  MyTextFormField(
                    controller: plateNumberController,
                    labelText: 'Plate Number',
                    hintText: 'Example: ABCD 123',

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Plate number is required';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: isLoading ? null : saveProfile,

                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneDropdown extends StatelessWidget {
  final String? value;
  final List<String> zones;
  final void Function(String?) onChanged;

  const _ZoneDropdown({
    required this.value,
    required this.zones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,

      dropdownColor: const Color.fromARGB(255, 38, 38, 60),

      style: const TextStyle(color: Colors.white, fontSize: 14),

      decoration: InputDecoration(
        labelText: 'Zone',

        labelStyle: const TextStyle(color: Colors.white70),

        filled: true,
        fillColor: const Color.fromARGB(255, 38, 38, 60),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.white54, width: 1.4),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),

      items: zones.map((zone) {
        return DropdownMenuItem(value: zone, child: Text(zone));
      }).toList(),

      onChanged: onChanged,

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your zone';
        }

        return null;
      },
    );
  }
}
