// ignore_for_file: use_build_context_synchronously

import 'package:ejp_ride_version/elements/mytextfield.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestRidePage extends StatefulWidget {
  const RequestRidePage({super.key});

  @override
  State<RequestRidePage> createState() => _RequestRidePageState();
}

class _RequestRidePageState extends State<RequestRidePage> {
  final pickupController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  String? selectedZone;

  final List<String> meetingPoints = [
    'Hull — Galeries de Hull',
    'Gatineau — Les Promenades Gatineau',
    'Plateau / Aylmer — Galeries d’Aylmer',
    'Ottawa — Centre Rideau',
    'Orléans — Centre commercial Saint-Laurent',
  ];

  @override
  void dispose() {
    pickupController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Demander un trajet',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Informations sur le trajet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Entrez votre adresse. Le point de rencontre sera attribué ultérieurement.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 24),

                _ZoneDropdown(
                  value: selectedZone,
                  zones: meetingPoints,
                  onChanged: (value) {
                    setState(() {
                      selectedZone = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                MyTextFormField(
                  controller: pickupController,
                  labelText: 'Adresse de départ',
                  hintText: 'Entrez votre adresse',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L’adresse est requise.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                MyTextFormField(
                  controller: phoneController,
                  labelText: 'Numéro de téléphone',
                  hintText: 'Entrez votre numéro de téléphone',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro de téléphone est requis.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                MyTextFormField(
                  controller: notesController,
                  labelText: 'Notes',
                  hintText: 'Notes optionnelles',
                  validator: null,
                ),

                const SizedBox(height: 28),

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
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            setState(() {
                              isLoading = true;
                            });

                            await FirebaseFirestore.instance
                                .collection('ride_requests')
                                .add({
                                  'userId': user.uid,
                                  'email': user.email,
                                  'zone': selectedZone,
                                  'pickupAddress': pickupController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                  'notes': notesController.text.trim(),
                                  'status': 'waiting',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (!mounted) return;

                            setState(() {
                              isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Votre demande de trajet a été envoyée.',
                                ),
                              ),
                            );

                            Navigator.pop(context);
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Envoyer la demande',
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
          return 'Veuillez sélectionner votre zone.';
        }
        return null;
      },
    );
  }
}
