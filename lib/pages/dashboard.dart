import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ejp_ride_version/pages/profilepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final String name;
  final String email;
  final String zone;
  final String phone;
  final File? profileImage;

  const DashboardPage({
    super.key,
    required this.role,
    required this.name,
    required this.email,
    required this.zone,
    required this.phone,
    this.profileImage,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const String googleApiKey = 'AIzaSyDeKQL_4I2p_VESfOV2wiivm0LC8oefbDw';

  bool get isDriver => widget.role == 'driver';

  File? dashboardProfileImage;
  GoogleMapController? mapController;

  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  final TextEditingController pickupAddressController = TextEditingController();

  final TextEditingController dropoffAddressController =
      TextEditingController();

  String rideStatus = 'none';
  String? activeRideRequestId;

  String currentLocation = 'Getting location...';
  LatLng currentLatLng = const LatLng(45.4215, -75.6972);

  @override
  void initState() {
    super.initState();
    dashboardProfileImage = widget.profileImage;
    getCurrentLocation();
  }

  @override
  void dispose() {
    pickupAddressController.dispose();
    dropoffAddressController.dispose();
    sheetController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        currentLocation = 'Location off';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocation = 'Location unavailable';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    final newLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      currentLatLng = newLatLng;
    });

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newLatLng, zoom: 16),
      ),
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final fullAddress = '${place.street ?? ''}, ${place.locality ?? ''}'
            .trim();

        final city = place.locality ?? 'Current city';

        setState(() {
          currentLocation = city;
          pickupAddressController.text = fullAddress;
        });
      }
    } catch (_) {
      setState(() {
        currentLocation = 'Current location';
      });
    }
  }

  Future<List<String>> getAddressSuggestions(String input) async {
    if (input.trim().length < 3) return [];

    try {
      final response = await Dio().get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input.trim(),
          'key': googleApiKey,
          'components': 'country:ca',
          'location': '${currentLatLng.latitude},${currentLatLng.longitude}',
          'radius': 50000,
        },
      );

      if (response.data['status'] != 'OK') return [];

      final predictions = response.data['predictions'] as List;

      return predictions
          .map((prediction) => prediction['description'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> submitRideRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final pickup = pickupAddressController.text.trim();
    final dropoff = dropoffAddressController.text.trim();

    if (pickup.isEmpty || dropoff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and drop-off are required')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 18),
              Text(
                'We are looking for a ride for you...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 18),
              Text(
                'We are looking for a ride for you...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    final doc = await FirebaseFirestore.instance
        .collection('ride_requests')
        .add({
          'userId': user.uid,
          'name': widget.name,
          'email': widget.email,
          'phone': widget.phone,
          'zone': widget.zone,
          'pickupAddress': pickup,
          'dropoffAddress': dropoff,
          'latitude': currentLatLng.latitude,
          'longitude': currentLatLng.longitude,
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
        });
    if (mounted) Navigator.pop(context);

    setState(() {
      rideStatus = 'waiting';
      activeRideRequestId = doc.id;
    });

    await sheetController.animateTo(
      0.25,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> cancelRideRequest() async {
    if (activeRideRequestId == null) return;

    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(activeRideRequestId)
        .delete();

    setState(() {
      rideStatus = 'none';
      activeRideRequestId = null;
      dropoffAddressController.clear();
    });

    await getCurrentLocation();

    await sheetController.animateTo(
      0.55,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLatLng,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                getCurrentLocation();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: currentLatLng,
                ),
              },
            ),
          ),

          IgnorePointer(
            // ignore: deprecated_member_use
            child: Container(color: Colors.black.withOpacity(0.10)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final updatedImage = await Navigator.push<File?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            name: widget.name,
                            email: widget.email,
                            zone: widget.zone,
                            role: widget.role,
                            phone: widget.phone,
                            profileImage: dashboardProfileImage,
                          ),
                        ),
                      );

                      if (updatedImage != null) {
                        setState(() {
                          dashboardProfileImage = updatedImage;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: dashboardProfileImage != null
                          ? FileImage(dashboardProfileImage!)
                          : null,
                      child: dashboardProfileImage == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 28,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(180, 240, 240, 245),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.location_fill,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Your location',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  currentLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.bell,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: 0.55,
            minChildSize: 0.25,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: const [0.25, 0.55, 0.90],
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 28, 28, 47),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: isDriver
                      ? _DriverContent(name: widget.name)
                      : _PassengerContent(
                          name: widget.name,
                          pickupController: pickupAddressController,
                          dropoffController: dropoffAddressController,
                          onRequestRide: submitRideRequest,
                          onCancelRide: cancelRideRequest,
                          rideStatus: rideStatus,
                          suggestionCallback: getAddressSuggestions,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PassengerContent extends StatefulWidget {
  final String name;
  final VoidCallback onRequestRide;
  final VoidCallback onCancelRide;
  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final String rideStatus;
  final Future<List<String>> Function(String) suggestionCallback;

  const _PassengerContent({
    required this.name,
    required this.onRequestRide,
    required this.onCancelRide,
    required this.pickupController,
    required this.dropoffController,
    required this.rideStatus,
    required this.suggestionCallback,
  });

  @override
  State<_PassengerContent> createState() => _PassengerContentState();
}

class _PassengerContentState extends State<_PassengerContent> {
  bool get hasActiveRequest => widget.rideStatus == 'waiting';

  Color get statusColor {
    switch (widget.rideStatus) {
      case 'waiting':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  String get statusText {
    switch (widget.rideStatus) {
      case 'waiting':
        return 'We are looking for a driver for you...';
      case 'accepted':
        return 'Ride confirmed';
      default:
        return 'No active ride request';
    }
  }

  Widget buildAddressField({
    required String label,
    required TextEditingController controller,
  }) {
    return TypeAheadField<String>(
      hideOnSelect: true,
      hideOnEmpty: true,
      hideOnUnfocus: true,
      suggestionsCallback: widget.suggestionCallback,
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion, style: const TextStyle(fontSize: 13)),
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion;

        FocusManager.instance.primaryFocus?.unfocus();

        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            setState(() {});
          }
        });
      },
      builder: (context, textController, focusNode) {
        if (textController.text != controller.text) {
          textController.text = controller.text;
          textController.selection = TextSelection.fromPosition(
            TextPosition(offset: textController.text.length),
          );
        }

        return TextField(
          controller: textController,
          focusNode: focusNode,
          enabled: !hasActiveRequest,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            hintText: label == 'Pickup'
                ? 'Enter your pickup address'
                : 'Where are you going?',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color.fromARGB(255, 38, 38, 60),
            suffixIcon: controller.text.isNotEmpty && !hasActiveRequest
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      textController.clear();
                      controller.clear();
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white54),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
          onChanged: (value) {
            controller.text = value;
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 18),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Hello, ${widget.name} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Need a ride this Sunday?',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),

        const SizedBox(height: 18),

        buildAddressField(label: 'Pickup', controller: widget.pickupController),

        const SizedBox(height: 12),

        buildAddressField(
          label: 'Drop-off',
          controller: widget.dropoffController,
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasActiveRequest ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: hasActiveRequest
                ? widget.onCancelRide
                : widget.onRequestRide,
            child: Text(
              hasActiveRequest ? 'Cancel Ride Request' : 'Confirm Ride Request',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 38, 38, 60),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              widget.rideStatus == 'waiting'
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    )
                  : Icon(CupertinoIcons.clock, color: statusColor, size: 19),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

class _DriverContent extends StatelessWidget {
  final String name;

  const _DriverContent({required this.name});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('status', isEqualTo: 'waiting')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final requests = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hello, $name 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available ride requests',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),

            const SizedBox(height: 16),

            if (snapshot.connectionState == ConnectionState.waiting)
              const CircularProgressIndicator(color: Colors.green),

            if (requests.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 38, 38, 60),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'No ride requests yet',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

            ...requests.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 38, 38, 60),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.person, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${data['name'] ?? 'Passenger'} • ${data['zone'] ?? ''}\n${data['pickupAddress'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
