import 'package:firebase/screens/home/Ordering/cargills.dart';
import 'package:firebase/screens/home/home.dart';
import 'package:flutter/material.dart';

class ShoppingCenterPage extends StatelessWidget {
  // Sample data for shopping centers
  final List<Map<String, String>> shoppingCenters = [
    {
      "name": "Cargills Food City",
      "description": "Fresh groceries and household items.",
      "image": "assets/images/cfoodcity.jpg",  // Local asset image
    },
    {
      "name": "Keells Super",
      "description": "Your trusted supermarket for daily needs.",
      "image": "assets/images/keells.png", // Remote image URL
    },
    {
      "name": "Arpico Supercentre",
      "description": "Quality products and great offers.",
      "image": "assets/images/arpico.jpg", // Remote image URL
    },
  ];

  ShoppingCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Centers"),
        backgroundColor: Colors.orange[900],
      ),
      body: ListView.builder(
        itemCount: shoppingCenters.length,
        itemBuilder: (context, index) {
          final center = shoppingCenters[index];
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: center['image']!.startsWith('http')
                    ? Image.network(
                        center['image']!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        center['image']!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(
                center['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(center['description']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (center['name'] == "Cargills Food City") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CargillsOrderPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Home()),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
