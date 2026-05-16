import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final String? profileImageUrl;

  const UserProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.zone,
    required this.role,
    required this.phone,
    this.profileImage,
    this.profileImageUrl,
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

  // Sélection et recadrage de la photo de profil
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
        IOSUiSettings(title: 'Rogner la photo de profil'),
        AndroidUiSettings(
          toolbarTitle: 'Rogner la photo de profil',
          lockAspectRatio: true,
        ),
      ],
    );

    if (croppedImage != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newImage = File(croppedImage.path);

      setState(() {
        profileImage = newImage;
      });

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      final uploadTask = await ref.putFile(newImage);

      final imageUrl = await uploadTask.ref.getDownloadURL();

      await updateUserField('profileImageUrl', imageUrl);
    }
  }

  // Modifier le nom
  void editName() {
    final nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Modifier mon nom',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: nameController,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Saisissez votre nom',
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
                'Annuler',
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
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  // Modifier le téléphone
  void editPhone() {
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Modifier mon numéro de téléphone',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Saisissez votre numéro de téléphone',
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
                'Annuler',
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
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  // Modifier la zone
  void editZone() {
    String selectedZone = zone;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Modifier ma zone',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: selectedZone,
            dropdownColor: const Color.fromARGB(255, 38, 38, 60),
            style: const TextStyle(color: Colors.white, fontSize: 14),
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
                'Annuler',
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
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  // Déconnexion
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

  // Suppression du compte
  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      await FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg')
          .delete()
          .catchError((_) {});

      await user.delete();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez vous reconnecter avant de supprimer le compte.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  // Confirmation de suppression du compte
  void confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          title: const Text(
            'Supprimer le compte ?',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: const Text(
            'Cette action est irréversible.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => deleteAccount(context),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
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
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context, profileImage);
          },
        ),
        title: const Text(
          'Mon profil',
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
                      : (widget.profileImageUrl != null &&
                            widget.profileImageUrl!.isNotEmpty &&
                            widget.profileImageUrl!.startsWith('https://'))
                      ? NetworkImage(widget.profileImageUrl!)
                      : null,
                  child:
                      profileImage == null &&
                          (widget.profileImageUrl == null ||
                              widget.profileImageUrl!.isEmpty ||
                              !widget.profileImageUrl!.startsWith('https://'))
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
                  'Changer ma photo de profil',
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
                role == 'driver' ? 'CONDUCTEUR' : 'PASSAGER',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),

              const SizedBox(height: 30),

              _ProfileTile(
                icon: CupertinoIcons.person_fill,
                title: 'Nom',
                value: name,
                onTap: editName,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 38, 38, 60),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.mail_solid, color: Colors.green),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Courriel",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _ProfileTile(
                icon: CupertinoIcons.phone_fill,
                title: 'Téléphone',
                value: phone.isEmpty ? 'Pas encore disponible' : phone,
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
                    'Déconnexion',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: confirmDeleteAccount,
                child: const Text(
                  'Supprimer mon compte',
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
