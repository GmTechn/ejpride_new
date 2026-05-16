// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:dio/dio.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/pages/notifications.dart';
import 'package:ejp_ride_version/pages/profilepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final String name;
  final String email;
  final String zone;
  final String phone;
  final File? profileImage;
  final String? profileImageUrl;

  const DashboardPage({
    super.key,
    required this.role,
    required this.name,
    required this.email,
    required this.zone,
    required this.phone,
    this.profileImage,
    this.profileImageUrl,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Dio dio = Dio();

  final String googleApiKey = 'AIzaSyDeKQL_4I2p_VESfOV2wiivm0LC8oefbDw';

  File? dashboardProfileImage;
  String? dashboardProfileImageUrl;
  GoogleMapController? mapController;

  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  final favoriteLabelController = TextEditingController();

  String activeAddressField = 'destination';
  String currentCity = 'Position actuelle';
  String pickupType = 'meeting_point';
  String? selectedMeetingPoint;
  String? selectedFavoriteAddress;

  bool saveDestinationAsFavorite = false;

  final List<String> meetingPoints = [
    'Hull (Galeries)',
    'Gatineau (Promenades)',
    'Aylmer (Galeries)',
    'Ottawa (Rideau)',
    'Orléans (St-Laurent)',
  ];

  bool get isDriver => widget.role == 'driver';

  @override
  void initState() {
    super.initState();
    dashboardProfileImage = widget.profileImage;
    dashboardProfileImageUrl = widget.profileImageUrl;
    loadCurrentCity();
  }

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    favoriteLabelController.dispose();
    super.dispose();
  }

  //loading current city to display it

  Future<void> loadCurrentCity() async {
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) return;

    final place = placemarks.first;

    setState(() {
      currentCity = place.locality?.isNotEmpty == true
          ? place.locality!
          : place.subAdministrativeArea ?? 'Position actuelle';
    });
  }

  //Submit request function

  Future<void> submitRideRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickupAddress = pickupType == 'meeting_point'
        ? selectedMeetingPoint
        : pickupController.text.trim();

    if (pickupAddress == null ||
        pickupAddress.isEmpty ||
        dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le point de départ et la destination sont requis.'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('ride_requests').add({
      'userId': user.uid,
      'name': widget.name,
      'email': widget.email,
      'phone': widget.phone,
      'zone': widget.zone,
      'pickupType': pickupType,
      'meetingPoint': pickupType == 'meeting_point'
          ? selectedMeetingPoint
          : null,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffController.text.trim(),
      'status': 'waiting',
      'declinedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (saveDestinationAsFavorite && dropoffController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite_addresses')
          .add({
            'label': favoriteLabelController.text.trim().isEmpty
                ? 'Favori'
                : favoriteLabelController.text.trim(),
            'address': dropoffController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande envoyée avec succès.')),
    );

    pickupController.clear();
    dropoffController.clear();
    favoriteLabelController.clear();

    setState(() {
      selectedMeetingPoint = null;
      selectedFavoriteAddress = null;
      saveDestinationAsFavorite = false;
      pickupType = 'meeting_point';
    });
  }

  //get address suggestion function
  Future<List<String>> getAddressSuggestions(String input) async {
    if (input.trim().length < 3) return [];

    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {
        'input': input,
        'key': googleApiKey,
        'components': 'country:ca',
        'language': 'fr',
      },
    );

    final predictions = response.data['predictions'] as List;

    return predictions.map((prediction) {
      final fullAddress = prediction['description'].toString();

      final parts = fullAddress.split(',');

      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }

      return fullAddress;
    }).toList();
  }

  //open profile page by clikcing on pp
  Future<void> _openProfile() async {
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
          profileImageUrl: dashboardProfileImageUrl,
        ),
      ),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final latestUrl = doc.data()?['profileImageUrl'] ?? '';

    setState(() {
      if (updatedImage != null) {
        dashboardProfileImage = updatedImage;
      }

      dashboardProfileImageUrl = latestUrl;
    });
  }

  //to go to current location
  Future<void> goToCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16,
      ),
    );
  }

  // open notifications
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(45.4215, -75.6972),
              zoom: 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            right: 18,
            bottom: 340,
            child: GestureDetector(
              onTap: goToCurrentLocation,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.placemark_fill,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),

          SafeArea(
            child: _TopBar(
              name: widget.name,
              currentCity: currentCity,
              profileImage: dashboardProfileImage,
              profileImageUrl: dashboardProfileImageUrl,
              onProfileTap: _openProfile,
              onNotificationTap: _openNotifications,
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.28,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 38, 38, 60),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 5),
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                          child: isDriver
                              ? _DriverSection(name: widget.name)
                              : _PassengerSection(
                                  name: widget.name,
                                  pickupController: pickupController,
                                  dropoffController: dropoffController,
                                  pickupType: pickupType,
                                  selectedMeetingPoint: selectedMeetingPoint,
                                  meetingPoints: meetingPoints,
                                  onPickupTypeChanged: (value) {
                                    setState(() => pickupType = value);
                                  },
                                  onMeetingPointChanged: (value) {
                                    setState(
                                      () => selectedMeetingPoint = value,
                                    );
                                  },
                                  selectedFavoriteAddress:
                                      selectedFavoriteAddress,
                                  favoriteLabelController:
                                      favoriteLabelController,
                                  saveDestinationAsFavorite:
                                      saveDestinationAsFavorite,
                                  onFavoriteSelected: (value) {
                                    setState(
                                      () => selectedFavoriteAddress = value,
                                    );
                                  },
                                  onSaveFavoriteChanged: (value) {
                                    setState(() {
                                      saveDestinationAsFavorite =
                                          value ?? false;
                                    });
                                  },
                                  onSubmit: submitRideRequest,
                                  activeAddressField: activeAddressField,
                                  onActiveAddressFieldChanged: (value) {
                                    setState(() => activeAddressField = value);
                                  },
                                  getAddressSuggestions: getAddressSuggestions,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final String currentCity;
  final File? profileImage;
  final String? profileImageUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const _TopBar({
    required this.name,
    required this.currentCity,
    required this.profileImage,
    this.profileImageUrl,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          // PROFILE
          GestureDetector(
            onTap: onProfileTap,

            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : (profileImageUrl != null &&
                        profileImageUrl!.isNotEmpty &&
                        profileImageUrl!.startsWith('https://'))
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child:
                  profileImage == null &&
                      (profileImageUrl == null ||
                          profileImageUrl!.isEmpty ||
                          !profileImageUrl!.startsWith('http'))
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      color: Color.fromARGB(255, 38, 38, 60),
                      size: 26,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 14),

          // LOCATION CENTER CARD
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tu es actuellement à :',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      currentCity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // NOTIFICATION
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.bell,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _favoriteIconName(String label) {
  final lower = label.toLowerCase();

  if (lower.contains('maison')) return 'home';
  if (lower.contains('église') || lower.contains('eglise')) return 'church';
  if (lower.contains('école') || lower.contains('ecole')) return 'school';
  if (lower.contains('travail')) return 'work';

  return 'other';
}

class _PassengerSection extends StatelessWidget {
  final String name;
  final TextEditingController pickupController;
  final TextEditingController dropoffController;

  final String pickupType;
  final String? selectedMeetingPoint;
  final List<String> meetingPoints;

  final void Function(String) onPickupTypeChanged;
  final void Function(String?) onMeetingPointChanged;

  final String? selectedFavoriteAddress;
  final TextEditingController favoriteLabelController;
  final bool saveDestinationAsFavorite;
  final void Function(String?) onFavoriteSelected;
  final void Function(bool?) onSaveFavoriteChanged;

  final VoidCallback onSubmit;

  final String activeAddressField;
  final void Function(String) onActiveAddressFieldChanged;

  final Future<List<String>> Function(String) getAddressSuggestions;

  const _PassengerSection({
    required this.name,
    required this.pickupController,
    required this.dropoffController,
    required this.pickupType,
    required this.selectedMeetingPoint,
    required this.meetingPoints,
    required this.onPickupTypeChanged,
    required this.onMeetingPointChanged,
    required this.selectedFavoriteAddress,
    required this.favoriteLabelController,
    required this.saveDestinationAsFavorite,
    required this.onFavoriteSelected,
    required this.onSaveFavoriteChanged,
    required this.onSubmit,
    required this.activeAddressField,
    required this.onActiveAddressFieldChanged,
    required this.getAddressSuggestions,
  });

  double progressValue(String status) {
    switch (status) {
      case 'waiting':
        return 0.20;
      case 'assigned':
        return 0.40;
      case 'on_the_way':
        return 0.60;
      case 'driver_arrived':
        return 0.80;
      case 'picked_up':
        return 0.90;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  String statusTitle(String status) {
    switch (status) {
      case 'waiting':
        return 'Recherche d’un chauffeur';
      case 'assigned':
        return 'Trajet assigné 🎉';
      case 'on_the_way':
        return 'Votre chauffeur est en route';
      case 'driver_arrived':
        return 'Votre chauffeur est arrivé 🚗';
      case 'picked_up':
        return 'Vous êtes en route';
      case 'completed':
        return 'Merci d’avoir choisi EJP Ride.';
      case 'no_driver_found':
        return 'Aucun chauffeur disponible';
      default:
        return 'Demander un trajet';
    }
  }

  String statusSubtitle(String status) {
    switch (status) {
      case 'waiting':
        return 'Recherche d’un chauffeur disponible...';
      case 'assigned':
        return 'Votre trajet pour dimanche a été confirmé.';
      case 'on_the_way':
        return 'Votre chauffeur est en route vers votre point de ramassage.';
      case 'driver_arrived':
        return 'Veuillez rejoindre votre chauffeur au point de ramassage.';
      case 'picked_up':
        return 'Vous êtes actuellement en route vers votre destination.';
      case 'no_driver_found':
        return 'Nous n’avons pas trouvé de chauffeur pour le moment.';
      case 'completed':
        return 'Merci d’avoir utilisé EJP Ride.';
      default:
        return 'Entrez votre point de départ et votre destination.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text(
        'Veuillez vous reconnecter.',
        style: TextStyle(color: Colors.white),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('userId', isEqualTo: user.uid)
          .where(
            'status',
            whereIn: [
              'waiting',
              'assigned',
              'on_the_way',
              'driver_arrived',
              'picked_up',
              'no_driver_found',
            ],
          )
          .snapshots(),
      builder: (context, snapshot) {
        final requests = snapshot.data?.docs ?? [];

        if (requests.isNotEmpty) {
          final data = requests.first.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'waiting';

          return _Panel(
            title: statusTitle(status),
            subtitle: statusSubtitle(status),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progressValue(status),
                  color: Colors.green,
                  backgroundColor: Colors.white24,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 18),
                Text(
                  'Point de départ : ${data['pickupAddress'] ?? ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Destination : ${data['dropoffAddress'] ?? ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                if (status == 'no_driver_found')
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
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('ride_requests')
                            .doc(requests.first.id)
                            .update({
                              'status': 'closed',
                              'closedAt': FieldValue.serverTimestamp(),
                            });
                      },
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                if (status == 'driver_arrived')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'Votre chauffeur est arrivé. Veuillez vous rendre au point de ramassage.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                if (status == 'waiting' || status == 'assigned') ...[
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        final driverId = data['driverId'];

                        await FirebaseFirestore.instance
                            .collection('ride_requests')
                            .doc(requests.first.id)
                            .update({
                              'status': 'cancelled',
                              'cancelledBy': 'passenger',
                              'cancelledAt': FieldValue.serverTimestamp(),
                            });

                        if (driverId != null &&
                            driverId.toString().isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .add({
                                'userId': driverId,
                                'title': 'Trajet annulé',
                                'message':
                                    '${data['name'] ?? 'Un passager'} a annulé sa demande.',
                                'type': 'ride_cancelled',
                                'rideId': requests.first.id,
                                'read': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Annuler la demande',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return _Panel(
          title: 'Planifier mon trajet',
          subtitle:
              'Choisissez votre point de ramassage et rendez-vous y à 13h00.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Type de ramassage'),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 28, 28, 47),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onPickupTypeChanged('meeting_point'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: pickupType == 'meeting_point'
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            'Point rencontre',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: pickupType == 'meeting_point'
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onPickupTypeChanged('home_address'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: pickupType == 'home_address'
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            'Adresse personnelle',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: pickupType == 'home_address'
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (pickupType == 'meeting_point')
                _MeetingPointDropdown(
                  selectedMeetingPoint: selectedMeetingPoint,
                  meetingPoints: meetingPoints,
                  onChanged: onMeetingPointChanged,
                ),

              if (pickupType == 'home_address')
                Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      onActiveAddressFieldChanged('pickup');
                    }
                  },
                  child: _AddressAutocompleteField(
                    controller: pickupController,
                    label: 'Adresse de ramassage',
                    icon: Icons.location_on_outlined,
                    suggestionsCallback: getAddressSuggestions,
                  ),
                ),

              const SizedBox(height: 10),

              Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    onActiveAddressFieldChanged('destination');
                  }
                },
                child: _AddressAutocompleteField(
                  controller: dropoffController,
                  label: 'Destination',
                  icon: CupertinoIcons.flag_fill,
                  suggestionsCallback: getAddressSuggestions,
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: 'Enregistrer comme favori',
                  child: GestureDetector(
                    onTap: () {
                      _showFavoriteDialog(
                        context: context,
                        favoriteLabelController: favoriteLabelController,
                        dropoffController: dropoffController,
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 28, 28, 47),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _FavoriteAddressButtons(
                title: 'Favoris récents',
                targetController: activeAddressField == 'pickup'
                    ? pickupController
                    : dropoffController,
                onFavoriteSelected: onFavoriteSelected,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onSubmit,
                  child: const Text(
                    'Confirmer la demande',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFavoriteDialog({
    required BuildContext context,
    required TextEditingController favoriteLabelController,
    required TextEditingController dropoffController,
  }) {
    final addressController = TextEditingController(
      text: dropoffController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 38, 38, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Enregistrer comme favori',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DashboardField(
                controller: favoriteLabelController,
                label: 'Nom du favori',
                icon: CupertinoIcons.star_fill,
              ),
              const SizedBox(height: 12),
              _DashboardField(
                controller: addressController,
                label: 'Adresse complète',
                icon: CupertinoIcons.location_fill,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                favoriteLabelController.clear();
                Navigator.pop(context);
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null || addressController.text.trim().isEmpty) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('favorite_addresses')
                    .add({
                      'label': favoriteLabelController.text.trim().isEmpty
                          ? 'Favori'
                          : favoriteLabelController.text.trim(),
                      'icon': _favoriteIconName(
                        favoriteLabelController.text.trim(),
                      ),
                      'address': addressController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                favoriteLabelController.clear();

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MeetingPointDropdown extends StatelessWidget {
  final String? selectedMeetingPoint;
  final List<String> meetingPoints;
  final void Function(String?) onChanged;

  const _MeetingPointDropdown({
    required this.selectedMeetingPoint,
    required this.meetingPoints,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedMeetingPoint,
      dropdownColor: const Color.fromARGB(255, 28, 28, 47),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: 'Point de rencontre',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        prefixIcon: const Icon(Icons.place, color: Colors.green),
        filled: true,
        fillColor: const Color.fromARGB(255, 28, 28, 47),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      items: meetingPoints.map((point) {
        return DropdownMenuItem(
          value: point,
          child: Text(point, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _FavoriteAddressButtons extends StatelessWidget {
  final String title;
  final TextEditingController targetController;
  final void Function(String?) onFavoriteSelected;

  const _FavoriteAddressButtons({
    required this.title,
    required this.targetController,
    required this.onFavoriteSelected,
  });

  IconData getFavoriteIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return CupertinoIcons.house_fill;
      case 'church':
        return Icons.church;
      case 'school':
        return CupertinoIcons.book_fill;
      case 'work':
        return CupertinoIcons.briefcase_fill;
      default:
        return CupertinoIcons.star_fill;
    }
  }

  Future<void> deleteFavorite(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_addresses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite_addresses')
          .snapshots(),
      builder: (context, snapshot) {
        final favorites = (snapshot.data?.docs ?? []).take(3).toList();

        if (favorites.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title),
            const SizedBox(height: 8),

            Column(
              children: favorites.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final label = data['label'] ?? 'Favori';
                final address = data['address'] ?? '';
                final iconName = data['icon'] ?? 'other';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    getFavoriteIcon(iconName),
                    color: Colors.green,
                    size: 18,
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () {
                    targetController.text = address;
                    onFavoriteSelected(address);
                  },
                  trailing: PopupMenuButton<String>(
                    color: const Color.fromARGB(255, 38, 38, 60),
                    icon: const Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await deleteFavorite(doc.id);
                      }

                      if (value == 'edit') {
                        final labelController = TextEditingController(
                          text: label,
                        );
                        final addressController = TextEditingController(
                          text: address,
                        );

                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: const Color.fromARGB(
                                255,
                                38,
                                38,
                                60,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: const Text(
                                'Modifier le favori',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DashboardField(
                                    controller: labelController,
                                    label: 'Nom du favori',
                                    icon: CupertinoIcons.star_fill,
                                  ),
                                  const SizedBox(height: 12),
                                  _DashboardField(
                                    controller: addressController,
                                    label: 'Adresse',
                                    icon: CupertinoIcons.location_fill,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Annuler',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .collection('favorite_addresses')
                                        .doc(doc.id)
                                        .update({
                                          'label': labelController.text.trim(),
                                          'address': addressController.text
                                              .trim(),
                                          'icon': _favoriteIconName(
                                            labelController.text.trim(),
                                          ),
                                        });

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text(
                                    'Enregistrer',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Modifier',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}

//SECTION LABEL TO CHOOSE TYPE OF PICKUP

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

//AUTOCOMPLETE CLASS FOR

class _AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Future<List<String>> Function(String) suggestionsCallback;

  const _AddressAutocompleteField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suggestionsCallback,
  });

  @override
  State<_AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<_AddressAutocompleteField> {
  List<String> suggestions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> search(String value) async {
    if (value.trim().length < 3) {
      setState(() => suggestions = []);
      return;
    }

    setState(() => isLoading = true);

    final results = await widget.suggestionsCallback(value);

    if (!mounted) return;

    setState(() {
      suggestions = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: search,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: Icon(widget.icon, color: Colors.green),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => suggestions = []);
                    },
                  )
                : null,
            labelText: widget.label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            filled: true,
            fillColor: const Color.fromARGB(255, 28, 28, 47),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(color: Colors.green),
          ),

        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 28, 28, 47),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: suggestions.take(3).map((suggestion) {
                return ListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  dense: true,
                  title: Text(
                    suggestion,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onTap: () {
                    setState(() {
                      widget.controller.text = suggestion;
                      suggestions = [];
                    });

                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.controller.text.length),
                    );

                    FocusScope.of(context).unfocus();
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

//DRIVER SECTION CLASS
class _DriverSection extends StatelessWidget {
  final String name;

  const _DriverSection({required this.name});

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigné';
      case 'on_the_way':
        return 'En route';
      case 'driver_arrived':
        return 'Chauffeur arrivé';
      case 'picked_up':
        return 'Passager récupéré';
      case 'completed':
        return 'Terminé';
      default:
        return 'Assigné';
    }
  }

  //updating ride status function

  Future<void> updateRideStatus(String rideId, String status) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'driver_arrived') {
      updateData['driverArrivedAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'picked_up') {
      updateData['rideStartedAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'completed') {
      updateData['rideCompletedAt'] = FieldValue.serverTimestamp();
    }

    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(rideId)
        .update(updateData);
  }

  //accepting ride function
  Future<void> acceptRide(String rideId) async {
    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(rideId)
        .update({
          'status': 'assigned',
          'driverId': FirebaseAuth.instance.currentUser?.uid,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
  }

  //appening address in google maps

  Future<void> openAddressInMaps(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final driver = FirebaseAuth.instance.currentUser;

    if (driver == null) {
      return const Text(
        'Veuillez vous reconnecter.',
        style: TextStyle(color: Colors.white),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: driver.uid)
          .where(
            'status',
            whereIn: ['assigned', 'on_the_way', 'driver_arrived', 'picked_up'],
          )
          .snapshots(),
      builder: (context, activeSnapshot) {
        final activeRides = activeSnapshot.data?.docs ?? [];

        return Column(
          children: [
            if (activeRides.isNotEmpty)
              _Panel(
                title: 'Mes passagers assignés',
                subtitle: 'Voici les trajets que vous avez acceptés.',
                child: Column(
                  children: activeRides.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'assigned';

                    String buttonText = 'Je suis en route';
                    String nextStatus = 'on_the_way';

                    if (status == 'on_the_way') {
                      buttonText = 'Je suis arrivé';
                      nextStatus = 'driver_arrived';
                    }

                    if (status == 'driver_arrived') {
                      buttonText = 'Passager récupéré';
                      nextStatus = 'picked_up';
                    }

                    if (status == 'picked_up') {
                      buttonText = 'Terminer le trajet';
                      nextStatus = 'completed';
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 28, 28, 47),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Passager',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                                openAddressInMaps(data['pickupAddress'] ?? ''),
                            child: Text(
                              'Départ : ${data['pickupAddress'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () =>
                                openAddressInMaps(data['dropoffAddress'] ?? ''),
                            child: Text(
                              'Destination : ${data['dropoffAddress'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Statut : ${_statusLabel(status)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  updateRideStatus(doc.id, nextStatus),
                              child: Text(
                                buttonText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (activeRides.isNotEmpty) const SizedBox(height: 20),
            _Panel(
              title: 'Demandes disponibles',
              subtitle: 'Vous pouvez accepter plusieurs trajets pour dimanche.',
              child: _AvailableRequestsList(
                driverId: driver.uid,
                acceptRide: acceptRide,
              ),
            ),
          ],
        );
      },
    );
  }
}

//AVAILABLE REQUESTS LIST CLASS
class _AvailableRequestsList extends StatelessWidget {
  final String driverId;
  final Future<void> Function(String rideId) acceptRide;

  const _AvailableRequestsList({
    required this.driverId,
    required this.acceptRide,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('status', isEqualTo: 'waiting')
          .snapshots(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data?.docs ?? [];

        final requests = allRequests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final declinedBy = List<String>.from(data['declinedBy'] ?? []);
          return !declinedBy.contains(driverId);
        }).toList();

        // if (snapshot.connectionState == ConnectionState.waiting &&
        //     !snapshot.hasData) {
        //   return const Center(
        //     child: CircularProgressIndicator(color: Colors.green),
        //   );
        // }

        if (requests.isEmpty) {
          return const Text(
            'Aucune demande pour le moment.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          );
        }

        return Column(
          children: requests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 28, 28, 47),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Passager',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Départ : ${data['pickupAddress'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Destination : ${data['dropoffAddress'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Téléphone : ${data['phone'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => acceptRide(doc.id),
                          child: const Text(
                            'Accepter',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final driver = FirebaseAuth.instance.currentUser;
                            if (driver == null) return;

                            final rideRef = FirebaseFirestore.instance
                                .collection('ride_requests')
                                .doc(doc.id);

                            final rideSnapshot = await rideRef.get();
                            final rideData =
                                rideSnapshot.data() as Map<String, dynamic>;

                            final declinedBy = List<String>.from(
                              rideData['declinedBy'] ?? [],
                            );

                            if (!declinedBy.contains(driver.uid)) {
                              declinedBy.add(driver.uid);
                            }

                            final driversSnapshot = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .where('role', isEqualTo: 'driver')
                                .get();

                            final totalDrivers = driversSnapshot.docs.length;

                            if (declinedBy.length >= totalDrivers) {
                              await rideRef.update({
                                'declinedBy': declinedBy,
                                'status': 'no_driver_found',
                                'noDriverFoundAt': FieldValue.serverTimestamp(),
                              });
                            } else {
                              await rideRef.update({'declinedBy': declinedBy});
                            }
                          },
                          child: const Text(
                            'Refuser',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

//PANNEL THAT DISPLAYS ALL
class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 38, 38, 60),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

//DASHBOARD FIELD CLASS
class _DashboardField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _DashboardField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: controller.clear,
              )
            : null,
        prefixIcon: Icon(icon, color: Colors.green, size: 14),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: const Color.fromARGB(255, 28, 28, 47),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}
