import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/utils/phone_number_utils.dart';

class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['displayName'] ?? 'No display name',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text('Email: ${data['email'] ?? 'No email'}'),
                      const SizedBox(height: 5.0),
                      Text('Mobile: ${sanitizePhoneNumber(data['mobileNumber'] ?? 'No mobile number')}'),
                      const SizedBox(height: 5.0),
                      Text('Address: ${data['address'] ?? 'No address'}'),
                      const SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () => _launchURL('tel:${sanitizePhoneNumber(data['mobileNumber'])}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.email),
                            onPressed: () => _launchURL('mailto:${data['email']}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.message),
                            onPressed: () => _launchURL('https://wa.me/${sanitizePhoneNumber(data['mobileNumber'])}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  
}
