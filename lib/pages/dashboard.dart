// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:dio/dio.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/pages/profilepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  final Dio dio = Dio();

  final String googleApiKey = 'AIzaSyDeKQL_4I2p_VESfOV2wiivm0LC8oefbDw';

  File? dashboardProfileImage;

  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  final favoriteLabelController = TextEditingController();
  String activeAddressField = 'destination';

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
  }

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    favoriteLabelController.dispose();
    super.dispose();
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

    return predictions
        .map((prediction) => prediction['description'].toString())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              name: widget.name,
              zone: widget.zone,
              profileImage: dashboardProfileImage,
              onProfileTap: () async {
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
                  setState(() => dashboardProfileImage = updatedImage);
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 30,
                ),
                child: isDriver
                    ? _DriverSection(name: widget.name)
                    : _PassengerSection(
                        name: widget.name,
                        pickupController: pickupController,
                        dropoffController: dropoffController,
                        activeAddressField: activeAddressField,
                        onActiveAddressFieldChanged: (value) {
                          setState(() {
                            activeAddressField = value;
                          });
                        },
                        pickupType: pickupType,
                        selectedMeetingPoint: selectedMeetingPoint,
                        meetingPoints: meetingPoints,
                        onPickupTypeChanged: (value) {
                          setState(() {
                            pickupType = value;
                          });
                        },
                        onMeetingPointChanged: (value) {
                          setState(() {
                            selectedMeetingPoint = value;
                          });
                        },
                        selectedFavoriteAddress: selectedFavoriteAddress,
                        favoriteLabelController: favoriteLabelController,
                        saveDestinationAsFavorite: saveDestinationAsFavorite,
                        onFavoriteSelected: (value) {
                          setState(() {
                            selectedFavoriteAddress = value;
                          });
                        },
                        onSaveFavoriteChanged: (value) {
                          setState(() {
                            saveDestinationAsFavorite = value ?? false;
                          });
                        },
                        onSubmit: submitRideRequest,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final String zone;
  final File? profileImage;
  final VoidCallback onProfileTap;

  const _TopBar({
    required this.name,
    required this.zone,
    required this.profileImage,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white,
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : null,
              child: profileImage == null
                  ? const Icon(Icons.person, color: Colors.green, size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  zone,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 38, 38, 60),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell,
              color: Colors.white,
              size: 20,
            ),
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
              ],
            ),
          );
        }

        return _Panel(
          title: 'Planifier mon trajet',
          subtitle:
              'Choisissez votre point de ramassage et votre destination pour dimanche.',
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
                  child: _DashboardField(
                    controller: pickupController,
                    label: 'Adresse de ramassage',
                    icon: Icons.location_on_outlined,
                  ),
                ),

              const SizedBox(height: 10),

              Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    onActiveAddressFieldChanged('destination');
                  }
                },
                child: _DashboardField(
                  controller: dropoffController,
                  label: 'Destination',
                  icon: CupertinoIcons.flag_fill,
                ),
              ),

              const SizedBox(height: 6),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: 'Enregistrer comme favori',
                  child: Checkbox(
                    value: false,
                    onChanged: (_) {
                      _showFavoriteDialog(
                        context: context,
                        favoriteLabelController: favoriteLabelController,
                        dropoffController: dropoffController,
                      );
                    },
                    activeColor: Colors.green,
                    side: const BorderSide(color: Colors.white54),
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

              const SizedBox(height: 24),

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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Départ : ${data['pickupAddress'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Destination : ${data['dropoffAddress'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Statut : ${_statusLabel(status)}',
                            style: const TextStyle(color: Colors.white60),
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (requests.isEmpty) {
          return const Text(
            'Aucune demande pour le moment.',
            style: TextStyle(color: Colors.white60),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Départ : ${data['pickupAddress'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Destination : ${data['dropoffAddress'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

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
