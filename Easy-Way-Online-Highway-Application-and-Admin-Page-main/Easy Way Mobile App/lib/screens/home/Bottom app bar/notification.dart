import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<List<NotificationModel>> fetchNotifications() async {
    // Simulate a delay for fetching data
    await Future.delayed(const Duration(seconds: 2));

    // Replace this with your API call or database query
    return List.generate(
      10,
      (index) => NotificationModel(
        title: 'Notification Title $index',
        description: 'This is a description for notification $index.',
        timestamp: '2024-11-16 12:${index}0 PM',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: fetchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange), // Set the color to orange
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error fetching notifications'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No notifications available'),
                  );
                } else {
                  final notifications = snapshot.data!;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationCard(
                        title: notification.title,
                        description: notification.description,
                        timestamp: notification.timestamp,
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
class NotificationModel {
  final String title;
  final String description;
  final String timestamp;

  NotificationModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String timestamp;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.description,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(
          timestamp,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}