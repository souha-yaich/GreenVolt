import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  void _modifySolarPanelInfo() {
    showDialog(
      context: context,
      builder: (context) {
        int newPanelCount = 1;
        double newPanelPower = 0.0;

        return AlertDialog(
          title: const Text('Modify Solar Panel Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Solar Panels',
                  hintText: 'Enter number of panels',
                ),
                onChanged: (value) {
                  newPanelCount = int.tryParse(value) ?? 1;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Power per Panel (W)',
                  hintText: 'Enter power in watts',
                ),
                onChanged: (value) {
                  newPanelPower = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('solarPanel') // Directly at this level
                        .doc(user.uid) // Use user ID as doc name
                        .set({
                      'panelCount': newPanelCount,
                      'panelPower': newPanelPower,
                    }, SetOptions(merge: true));
                  }
                  setState(() {});
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error saving solar panel info: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    String userId = getCurrentUserId();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_back.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFF3BA040),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.home, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Tooltip(
                      message: 'Log Out',
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await AuthService().logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const WelcomeScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: size.height * 0.4),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            areaCard('Area 1', const Color(0xFF4CAF50), context,
                                '1', userId),
                            areaCard(
                                'Area 2', Colors.green, context, '2', userId),
                            areaCard(
                                'Area 3', Colors.red, context, '3', userId),
                            areaCard(
                                'Area 4', Colors.red, context, '4', userId),
                            const SizedBox(
                                height: 20), // Space before total energy
                            solarPanelCard(userId), // Solar Panel Info Card
                            const SizedBox(height: 20),
                            solarProductionCard(userId),
                            const SizedBox(height: 20),
                            totalEnergyCard(userId), // Total Energy Section
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: const Color(0xFF3BA040),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.battery_charging_full,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/battery');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cloud,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/weather');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget solarPanelCard(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('solarPanel')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('solarPanel')
            .doc(userId);

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          // Initialize the document with default values
          docRef.set(
              {'panelCount': 0, 'panelPower': 0.0}, SetOptions(merge: true));
          return const Card(
            child: ListTile(
              title: Text("No Solar Panel Info available. Initializing..."),
            ),
          );
        }

        var panelCount = snapshot.data!['panelCount'] ?? 0;
        var panelPower = snapshot.data!['panelPower'] ?? 0.0;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ListTile(
            title: const Text(
              "Solar Panel Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Panels: $panelCount\nPower per panel: ${panelPower}W",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: _modifySolarPanelInfo,
            ),
          ),
        );
      },
    );
  }

  Widget totalEnergyCard(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('areas')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No energy data available.'));
        }

        double totalEnergy = snapshot.data!.docs.fold(
            0.0,
            (previousValue, doc) =>
                previousValue + (doc['totalEnergy'] ?? 0.0).toDouble());

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with bold text
                Text(
                  "Total Energy Consumption",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold, // Bold text
                    color: Colors.black, // Keep black color for the title
                  ),
                ),
                const SizedBox(height: 8),
                // Display energy value with bold text
                Text(
                  "${totalEnergy.toStringAsFixed(2)} kWh",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold, // Bold text
                    color:
                        Colors.black, // Keep black color for the energy value
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget solarProductionCard(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('User data not found.'));
        }

        // Get sun hours per day from user document
        double sunHoursPerDay =
            (userSnapshot.data!['adjustedSunHours'] ?? 0.0).toDouble();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('solarPanel')
              .snapshots(),
          builder: (context, solarPanelSnapshot) {
            if (solarPanelSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!solarPanelSnapshot.hasData ||
                solarPanelSnapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No solar panel data available.'));
            }

            double totalEstimatedEnergy = 0.0;

            for (var panelDoc in solarPanelSnapshot.data!.docs) {
              double panelCount = (panelDoc['panelCount'] ?? 0.0).toDouble();
              double panelEnergy = (panelDoc['panelPower'] ?? 0.0).toDouble();
              double estimatedEnergy =
                  (panelCount * panelEnergy * sunHoursPerDay) / 1000;

              // Update Firestore with estimated energy
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('solarPanel')
                  .doc(panelDoc.id)
                  .update({
                'estimatedEnergy':
                    double.tryParse(estimatedEnergy.toStringAsFixed(4))
              });

              totalEstimatedEnergy += estimatedEnergy;
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Estimated Solar Energy Production",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${totalEstimatedEnergy.toStringAsFixed(2)} kWh",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget areaCard(String title, Color statusColor, BuildContext context,
      String areaId, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('areas')
          .doc(areaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              title: Text("Loading..."),
              subtitle: Text("Fetching data"),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor,
                radius: 10,
              ),
              title: Text(title),
              subtitle: const Text("No data available"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/area',
                    arguments: {
                      'areaId': areaId,
                      'areaName': title,
                    },
                  );
                },
              ),
            ),
          );
        }

        var areaData = snapshot.data!.data() as Map<String, dynamic>;
        double totalEnergy = (areaData['totalEnergy'] ?? 0.0).toDouble();
        int priority = areaData['priority'] ?? 1;

        // Ensure 'priority' field exists
        if (!areaData.containsKey('priority')) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('areas')
              .doc(areaId)
              .update({'priority': priority});
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor,
                  radius: 10,
                ),
                title: Text("Area $areaId"), // Extracted from doc ID
                subtitle: Text(
                    'Energy: ${totalEnergy.toStringAsFixed(2)} kWh\nPriority: $priority'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/area',
                      arguments: {
                        'areaId': areaId,
                        'areaName': "Area $areaId",
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () =>
                    _modifyPriority(context, userId, areaId, priority),
                icon: const Icon(Icons.settings, color: Colors.grey),
                label: const Text("Modify Priority"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

// Function to modify priority
  void _modifyPriority(
      BuildContext context, String userId, String areaId, int currentPriority) {
    TextEditingController controller =
        TextEditingController(text: currentPriority.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Modify Priority"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter new priority"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                int? newPriority = int.tryParse(controller.text);
                if (newPriority != null) {
                  await _checkAndUpdatePriority(
                      context, userId, areaId, newPriority);
                  Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndUpdatePriority(BuildContext context, String userId,
      String areaId, int newPriority) async {
    var areasCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas');

    // Retrieve all 4 areas
    var querySnapshot = await areasCollection.get();

    String? conflictingAreaId;
    for (var doc in querySnapshot.docs) {
      if (doc.id != areaId && doc['priority'] == newPriority) {
        conflictingAreaId = doc.id;
        print("Conflict found with Area $conflictingAreaId"); // Debug log
        break;
      }
    }

    if (conflictingAreaId != null) {
      print("Conflict detected, swapping priorities automatically...");
      _swapPriorities(userId, areaId, conflictingAreaId, newPriority);
    } else {
      print("No conflict. Updating priority to $newPriority");
      await areasCollection.doc(areaId).update({'priority': newPriority});
      print("Priority updated successfully!");
    }
  }

  void _swapPriorities(String userId, String areaId, String conflictingAreaId,
      int newPriority) async {
    var areasCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas');

    try {
      print(
          "Attempting to swap priorities between Area $areaId and Area $conflictingAreaId");

      // Get the priorities of both areas
      var areaSnapshot = await areasCollection.doc(areaId).get();
      var conflictingAreaSnapshot =
          await areasCollection.doc(conflictingAreaId).get();

      // Check if both areas exist
      if (!areaSnapshot.exists || !conflictingAreaSnapshot.exists) {
        print("One or both areas do not exist.");
        return;
      }

      int areaPriority = areaSnapshot['priority'];
      int conflictingPriority = conflictingAreaSnapshot['priority'];

      print("Current priority of Area $areaId: $areaPriority");
      print(
          "Current priority of conflicting area ($conflictingAreaId): $conflictingPriority");

      // Swap priorities
      print("Updating priority of Area $areaId to $conflictingPriority");
      await areasCollection
          .doc(areaId)
          .update({'priority': conflictingPriority});

      print("Updating priority of Area $conflictingAreaId to $areaPriority");
      await areasCollection
          .doc(conflictingAreaId)
          .update({'priority': areaPriority});

      print("Priority swap successful!");
    } catch (e) {
      print("Error during priority swap: $e");
    }
  }
}
