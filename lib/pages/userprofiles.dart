import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RideUserProfilePage extends StatelessWidget {
  final String role;
  final String name;
  final String phone;
  final String zone;
  final String profileImageUrl;
  final String carModel;
  final String carColor;
  final String plateNumber;

  const RideUserProfilePage({
    super.key,
    required this.role,
    required this.name,
    required this.phone,
    required this.zone,
    required this.profileImageUrl,
    this.carModel = '',
    this.carColor = '',
    this.plateNumber = '',
  });

  bool get isDriver => role == 'driver';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isDriver ? 'Profil du chauffeur' : 'Profil du passager',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 62,
                backgroundColor: Colors.white,
                backgroundImage:
                    profileImageUrl.isNotEmpty &&
                        profileImageUrl.startsWith('https://')
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(
                        CupertinoIcons.person_fill,
                        size: 52,
                        color: Colors.green,
                      )
                    : null,
              ),

              const SizedBox(height: 20),

              Text(
                name.isNotEmpty ? name : 'Utilisateur',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              _InfoTile(
                icon: CupertinoIcons.phone_fill,
                label: 'Téléphone',
                text: phone,
              ),

              _InfoTile(
                icon: CupertinoIcons.location_fill,
                label: 'Zone',
                text: zone,
              ),

              if (isDriver) ...[
                const SizedBox(height: 12),

                _InfoTile(
                  icon: CupertinoIcons.car_detailed,
                  label: 'Modèle de voiture',
                  text: carModel,
                ),

                _InfoTile(
                  icon: CupertinoIcons.paintbrush_fill,
                  label: 'Couleur de voiture',
                  text: carColor,
                ),

                _InfoTile(
                  icon: CupertinoIcons.number,
                  label: 'Plaque d’immatriculation',
                  text: plateNumber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 38, 38, 60),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: label == 'Téléphone'
                      ? () async {
                          final uri = Uri(scheme: 'tel', path: text);

                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      : null,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: label == 'Téléphone' ? Colors.green : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: label == 'Téléphone'
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
