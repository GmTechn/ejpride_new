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
    'East',
    'West',
    'South',
    'Downtown',
    'Orleans',
    'Gatineau',
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
          'Driver Profile',
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
                  'Tell us about your car',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'This helps admins assign passengers properly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),

                const SizedBox(height: 30),

                MyTextFormField(
                  labelText: 'Car Model',
                  hintText: 'Example: Toyota Corolla',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Car model is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  labelText: 'Car Color',
                  hintText: 'Example: Black',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Car color is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  labelText: 'Plate Number',
                  hintText: 'Example: ABCD 123',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Plate number is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                MyTextFormField(
                  labelText: 'Number of Seats',
                  hintText: 'Example: 4',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Number of seats is required';
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
                    labelText: 'Main Sector',
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
                      return 'Please select your sector';
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
                        // Later: save driver profile in Firebase
                        // Navigate to Driver Dashboard
                      }
                    },
                    child: const Text(
                      'Complete Profile',
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
