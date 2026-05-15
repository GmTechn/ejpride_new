import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 28, 47),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Veuillez vous reconnecter.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune notification pour le moment.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white12, height: 22),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final read = data['read'] == true;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        read ? CupertinoIcons.bell : CupertinoIcons.bell_fill,
                        color: read ? Colors.white38 : Colors.green,
                      ),
                      title: Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          color: read ? Colors.white54 : Colors.white,
                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        data['message'] ?? '',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        doc.reference.update({'read': true});
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
