import 'package:ejp_ride_version/elements/mytextfield.dart';
import 'package:flutter/material.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedSector;

  final List<String> sectors = [
    'Hull',
    'Plateau / Aylmer',
    'Ottawa Est',
    'Orléans',
    'Gatineau - Gatineau',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profil conducteur',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Parlez-nous de votre véhicule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Ces informations permettent aux administrateurs d’affecter correctement les passagers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),

                const SizedBox(height: 30),

                MyTextFormField(
                  labelText: 'Modèle du véhicule',
                  hintText: 'Exemple : Toyota Corolla',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le modèle du véhicule est requis.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  labelText: 'Couleur du véhicule',
                  hintText: 'Exemple : Noir',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La couleur du véhicule est requise.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  labelText: 'Numéro de plaque',
                  hintText: 'Exemple : ABCD 123',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro d’immatriculation est requis.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: selectedSector,
                  dropdownColor: const Color.fromARGB(255, 38, 38, 60),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Secteur',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 38, 38, 60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.white54,
                        width: 1.4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  items: sectors.map((sector) {
                    return DropdownMenuItem(value: sector, child: Text(sector));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSector = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner votre secteur.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Plus tard : sauvegarder le profil conducteur dans Firebase
                        // Naviguer vers le tableau de bord conducteur
                      }
                    },
                    child: const Text(
                      'Compléter le profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
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
