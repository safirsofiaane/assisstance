import 'package:assistantsapp/controllers/enterprise/enterprise_provider.dart';
import 'package:assistantsapp/controllers/subscription_controller.dart';
import 'package:assistantsapp/models/enterprise.dart';
import 'package:assistantsapp/models/enum/role_enum.dart';
import 'package:assistantsapp/services/firestore_service.dart';
import 'package:assistantsapp/services/shared_preferences_manager.dart';
import 'package:assistantsapp/utils/constants/app_colors.dart';
import 'package:assistantsapp/views/sharedwidgets/make_conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EnterpriseDetailScreen extends StatelessWidget {
  const EnterpriseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Enterprise? enterprise =
        Provider.of<EnterpriseProvider>(context, listen: false)
            .selectedEnterprise;

    if (enterprise == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Enterprise Details'),
        ),
        body: const Center(child: Text('No Enterprise Selected')),
      );
    }

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () async {
            try {
              String userRole = SharedPreferencesManager.getUserRole();
              var userData = FirestoreService().auth.currentUser;
              if (userData != null) {
                if (Role.clients.name == userRole) {
                  await SubscriptionController().sendSubscription(
                      userId: userData.uid,
                      associationId: enterprise.id,
                      userName: userData.displayName ?? 'Missed Name');
                } else {
                  await SubscriptionController().sendSubscription(
                      userId: userData.uid,
                      associationId: enterprise.id,
                      userName: userData.displayName ?? '',
                      isAssistant: true);
                }
                await makeConversation(
                  context,
                  "I hope this message finds you well. I am writing to request a subscription.",
                  enterpriseName: enterprise.enterpriseName,
                  enterpriseid: enterprise.id,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscribe sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text(
            'Subscribe Now',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(enterprise.enterpriseName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEnterpriseHeader(enterprise),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  _buildLocationInfo(enterprise),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Assistants'),
                  const SizedBox(height: 10),
                  buildAssistantList(enterprise.assistants),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterpriseHeader(Enterprise enterprise) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(80)),
      ),
      width: double.infinity,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          enterprise.imageUrl != null && enterprise.imageUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(enterprise.imageUrl!),
                )
              : const CircleAvatar(
                  radius: 50,
                  child: Icon(
                    Icons.business,
                    size: 50,
                    color: AppColors.secondary,
                  ),
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: _buildInfoRow(Icons.email, enterprise.email),
          ),
          if (enterprise.phoneNumber != null &&
              enterprise.phoneNumber!.isNotEmpty)
            _buildInfoRow(Icons.phone, enterprise.phoneNumber!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String info) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 10),
        Center(
          child: Text(
            info,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(Enterprise enterprise) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          child: Icon(
            Icons.location_on,
            color: AppColors.secondary,
            size: 40,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              enterprise.address?.province ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              enterprise.address?.city ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildAssistantList(List<DocumentReference<Object?>>? assistantRefs) {
    if (assistantRefs == null || assistantRefs.isEmpty) {
      return const Center(child: Text('No Assistants Available'));
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(assistantRefs.map((ref) => ref.get()).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading assistants'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Assistants Available'));
        } else {
          final assistants = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assistants.length,
            itemBuilder: (context, index) {
              final assistantData =
                  assistants[index].data() as Map<String, dynamic>;
              final userName = assistantData['userName'] ?? 'Unknown';
              final imageUrl = assistantData['imageUrl'] ?? '';
              final serviceType =
                  assistantData['serviceType'] ?? 'Service Type';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                    radius: 30,
                  ),
                  title: Text(userName),
                  subtitle: Text(serviceType),
                  onTap: () {
                    // Navigate to assistant details
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
