import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String zone;
  final String role;
  final String phone;

  final File? profileImage;

  const UserProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.zone,
    required this.role,
    required this.phone,
    this.profileImage,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late String name;
  late String email;
  late String zone;
  late String phone;
  late String role;

  File? profileImage;
  bool imageExpanded = false;

  final ImagePicker picker = ImagePicker();

  final List<String> zones = [
    'Hull',
    'Gatineau-Gatineau',
    'Plateau - Aylmer',
    'Ottawa Est',
    'Orléans',
  ];

  @override
  void initState() {
    super.initState();
    name = widget.name;
    email = widget.email;
    zone = widget.zone;
    phone = widget.phone;
    role = widget.role;
    profileImage = widget.profileImage;
  }

  Future<void> updateUserField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      field: value,
    });
  }

  Future<void> pickAndCropImage() async {
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
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
      final newImage = File(croppedImage.path);

      setState(() {
        profileImage = newImage;
      });

      await updateUserField('profileImagePath', croppedImage.path);

      if (mounted) {
        Navigator.pop(context, newImage);
      }
    }
  }

  //editting user name

  void editName() {
    final nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Edit Name',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: nameController,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isNotEmpty) {
                  setState(() {
                    name = newName;
                  });

                  await updateUserField('fullName', newName);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  //editting phone name

  void editPhone() {
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Edit Phone Number',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newPhone = phoneController.text.trim();

                if (newPhone.isNotEmpty) {
                  setState(() {
                    phone = newPhone;
                  });

                  await updateUserField('phone', newPhone);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void editZone() {
    String selectedZone = zone;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Edit Zone',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: selectedZone,
            dropdownColor: const Color.fromARGB(255, 38, 38, 60),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
            items: zones.map((zone) {
              return DropdownMenuItem(value: zone, child: Text(zone));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedZone = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  zone = selectedZone;
                });

                await updateUserField('zone', selectedZone);

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Delete Account?',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => deleteAccount(context),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = imageExpanded ? 150.0 : 55.0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  setState(() {
                    imageExpanded = !imageExpanded;
                  });
                },
                onLongPress: pickAndCropImage,
                child: CircleAvatar(
                  radius: imageSize,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!)
                      : null,
                  child: profileImage == null
                      ? const Icon(
                          CupertinoIcons.person_fill,
                          size: 50,
                          color: Colors.green,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: pickAndCropImage,
                child: const Text(
                  'Change profile picture',
                  style: TextStyle(color: Colors.green, fontSize: 13),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                role.toUpperCase(),
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),

              const SizedBox(height: 30),

              _ProfileTile(
                icon: CupertinoIcons.person_fill,
                title: 'Name',
                value: name,
                onTap: editName,
              ),

              const SizedBox(height: 14),

              _ProfileTile(
                icon: CupertinoIcons.mail_solid,
                title: 'Email',
                value: email,
                onTap: () {},
              ),

              const SizedBox(height: 14),

              _ProfileTile(
                icon: CupertinoIcons.phone_fill,
                title: 'Phone Number',
                value: phone.isEmpty ? 'Not available yet' : phone,
                onTap: editPhone,
              ),

              const SizedBox(height: 14),

              _ProfileTile(
                icon: CupertinoIcons.location_fill,
                title: 'Zone',
                value: zone,
                onTap: editZone,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => logout(context),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: confirmDeleteAccount,
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 38, 38, 60),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.pencil, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
