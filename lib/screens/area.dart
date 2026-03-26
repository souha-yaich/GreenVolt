import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AreaPage extends StatefulWidget {
  final String areaId;
  final String areaName;

  const AreaPage({Key? key, required this.areaId, required this.areaName})
      : super(key: key);

  @override
  _AreaPageState createState() => _AreaPageState();
}

class _AreaPageState extends State<AreaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  @override
  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      userId = _auth.currentUser!.uid;
      setState(() {});
      calculateTotalEnergyStream().listen((energy) {
        updateTotalEnergy(energy);
      });
    }
  }

  void _showAddComponentDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController voltageController = TextEditingController();
    TextEditingController currentController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Component'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: voltageController,
                decoration: const InputDecoration(labelText: 'Voltage (V)')),
            TextField(
                controller: currentController,
                decoration: const InputDecoration(labelText: 'Current (A)')),
            TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time of Use')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addComponent(
                nameController.text,
                voltageController.text,
                currentController.text,
                timeController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void updateTotalEnergy(double totalEnergy) async {
    print("Updating total energy for area: $totalEnergy");

    DocumentReference areaDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .doc(widget.areaId);

    try {
      await areaDocRef
          .set({'totalEnergy': totalEnergy}, SetOptions(merge: true));
      print("Total energy updated successfully for area.");

      // Now update total energy at the user level
      updateUserTotalEnergy();
    } catch (error) {
      print("Error updating total energy: $error");
    }
  }

  void updateUserTotalEnergy() async {
    double totalUserEnergy = 0.0;

    QuerySnapshot areasSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .get();

    for (var doc in areasSnapshot.docs) {
      double areaEnergy = (doc['totalEnergy'] ?? 0.0).toDouble();
      totalUserEnergy += areaEnergy;
    }

    // Update the totalEnergy at the user document level
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'totalEnergy': totalUserEnergy},
      SetOptions(merge: true),
    );

    print("Updated total user energy: $totalUserEnergy");
  }

  Stream<double> calculateTotalEnergyStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .doc(widget.areaId)
        .collection('components')
        .snapshots()
        .map((snapshot) {
      double totalEnergy = 0.0;
      for (var doc in snapshot.docs) {
        double voltage = double.tryParse(doc['voltage'] ?? '0.0') ?? 0.0;
        double current = double.tryParse(doc['current'] ?? '0.0') ?? 0.0;
        double time = double.tryParse(doc['time'] ?? '0.0') ?? 0.0;
        totalEnergy += (voltage * current * time) / 1000;
        totalEnergy = double.parse(
            totalEnergy.toStringAsFixed(2)); // Round to 2 decimal places
      }
      updateTotalEnergy(totalEnergy); // Update Firestore
      return totalEnergy;
    });
  }

  Future<void> _addComponent(
      String name, String voltage, String current, String time) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .doc(widget.areaId)
        .collection('components')
        .add({
      'name': name,
      'voltage': voltage,
      'current': current,
      'time': time,
    });
  }

  Future<void> _deleteComponent(String componentId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .doc(widget.areaId)
        .collection('components')
        .doc(componentId)
        .delete();
  }

  void _showModifyComponentDialog(String componentId, String currentName,
      String currentVoltage, String currentCurrent, String currentTime) {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    TextEditingController voltageController =
        TextEditingController(text: currentVoltage);
    TextEditingController currentController =
        TextEditingController(text: currentCurrent);
    TextEditingController timeController =
        TextEditingController(text: currentTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Component'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: voltageController,
                decoration: const InputDecoration(labelText: 'Voltage (V)')),
            TextField(
                controller: currentController,
                decoration: const InputDecoration(labelText: 'Current (A)')),
            TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time of Use')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _modifyComponent(
                componentId,
                nameController.text,
                voltageController.text,
                currentController.text,
                timeController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Modify'),
          ),
        ],
      ),
    );
  }

  Future<void> _modifyComponent(String componentId, String name, String voltage,
      String current, String time) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('areas')
        .doc(widget.areaId)
        .collection('components')
        .doc(componentId)
        .update({
      'name': name,
      'voltage': voltage,
      'current': current,
      'time': time,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.areaName,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Handle logout action
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('areas')
                      .doc(widget.areaId)
                      .collection('components')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No components found.'));
                    }
                    return Table(
                      border: TableBorder.all(color: Colors.grey, width: 0.5),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.green[100]),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Component',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Voltage (V)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Current (A)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Time of Use',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Modify',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Delete',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        for (var doc in snapshot.data!.docs)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(doc['name']),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(doc['voltage']),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(doc['current']),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(doc['time']),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.green),
                                onPressed: () {
                                  _showModifyComponentDialog(
                                    doc.id,
                                    doc['name'],
                                    doc['voltage'],
                                    doc['current'],
                                    doc['time'],
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteComponent(doc.id);
                                },
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddComponentDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Component'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<double>(
              stream: calculateTotalEnergyStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No energy data available.'));
                }

                double totalEnergy = snapshot.data ?? 0.0;

                return Column(
                  children: [
                    const Text(
                      "Total Energy",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${totalEnergy.toStringAsFixed(2)} kWh", // Display the calculated energy value
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                // Handle Battery icon press
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.home,
                color: Colors.white,
              ),
              onPressed: () {
                // Handle Home icon press
              },
            ),
            IconButton(
              icon: Icon(
                Icons.cloud,
                color: Colors.white.withOpacity(0.5),
              ),
              onPressed: () {
                // Handle Cloud icon press
              },
            ),
          ],
        ),
      ),
    );
  }
}
