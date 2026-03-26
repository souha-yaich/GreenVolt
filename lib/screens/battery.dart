import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:greenvolt/main.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  _BatteryPageState createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  int capacity = 0;
  double batteryVoltage = 0;
  double batteryPercentage = 0;
  int remainingCapacity = 0;
  bool ruleBasedEnabled = false;
  double totalEnergyConsumption = 0;
  double area1Energy = 0;
  double area2Energy = 0;
  double area3Energy = 0;
  double area4Energy = 0;

  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('battery/SoC');

  @override
  void initState() {
    super.initState();
    _fetchBatteryInfo();
    _fetchBatteryData();
    _fetchRuleBasedStatus();
    _fetchTotalEnergyConsumption();
    _fetchTotalEnergyPerArea();
    //  _checkBatteryAndSendEmail();
  }

  Future<void> sendEmail(String email, double soc) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=Battery Alert&body=Warning: Your battery SoC is at ${soc.toStringAsFixed(1)}%. Only priority 1 areas are powered.',
    );

    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    } else {
      print('Could not launch email client');
    }
  }

  void _fetchBatteryData() {
    try {
      _database.onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            batteryPercentage = (event.snapshot.value as num).toDouble();
          });
        } else {
          print('Battery data not found');
        }
      });
    } catch (e) {
      print('Error fetching battery data: $e');
    }
  }

  Future<void> _fetchBatteryInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          capacity = data?['capacity'] ?? capacity;
          batteryVoltage = data?['batteryVoltage'] ?? batteryVoltage;
          remainingCapacity = data?['remainingCapacity'] ?? remainingCapacity;
        });
      } else {
        print('User data not found');
      }
    } catch (e) {
      print('Error fetching battery info: $e');
    }
  }

  Future<void> _fetchRuleBasedStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          ruleBasedEnabled = userDoc.data()?['ruleBasedEnabled'] ?? false;
        });
      } else {
        print('Rule-based status not found');
      }
    } catch (e) {
      print('Error fetching rule-based status: $e');
    }
  }

  Future<void> _fetchTotalEnergyConsumption() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          totalEnergyConsumption = userDoc.data()?['totalEnergy'] ?? double.nan;
          print(totalEnergyConsumption);
        });
      } else {
        setState(() {
          totalEnergyConsumption = double.nan;
        });
        print('Total energy consumption data not found');
      }
    } catch (e) {
      print('Error fetching total energy consumption: $e');
    }
  }

  Future<void> _fetchTotalEnergyPerArea() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch areas from Firestore
      final areasCollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('areas')
          .get();

      if (areasCollection.docs.isNotEmpty) {
        // Convert docs to a list and sort by priority
        var areas = areasCollection.docs.map((doc) {
          return {
            'id': doc.id,
            'priority': doc['priority'],
            'totalEnergy': doc['totalEnergy'],
          };
        }).toList();

        // Sort areas by the priority field in ascending order
        areas.sort((a, b) => a['priority'].compareTo(b['priority']));

        setState(() {
          // Update energy values according to sorted areas
          area1Energy = areas.isNotEmpty
              ? areas[0]['totalEnergy'] ?? double.nan
              : double.nan;
          area2Energy = areas.length > 1
              ? areas[1]['totalEnergy'] ?? double.nan
              : double.nan;
          area3Energy = areas.length > 2
              ? areas[2]['totalEnergy'] ?? double.nan
              : double.nan;
          area4Energy = areas.length > 3
              ? areas[3]['totalEnergy'] ?? double.nan
              : double.nan;

          // Print out the fetched energies for debugging
          print("Area 1 Energy: $area1Energy");
          print("Area 2 Energy: $area2Energy");
          print("Area 3 Energy: $area3Energy");
          print("Area 4 Energy: $area4Energy");
        });
      } else {
        // If no areas are found, set energies to NaN
        setState(() {
          area1Energy = area2Energy = area3Energy = area4Energy = double.nan;
        });
        print('No energy data found for areas');
      }
    } catch (e) {
      print('Error fetching energy data for areas: $e');
    }
  }

  Future<void> _toggleRuleBased(bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'ruleBasedEnabled': value}, SetOptions(merge: true));

      setState(() {
        ruleBasedEnabled = value;
      });
    } catch (e) {
      print('Error updating rule-based status: $e');
    }
  }

  double? calculateAutonomy() {
    double availableEnergy = 0;
    double autonomy = 0;

    double fixedEnergyBattery20 = 0.2 * capacity * batteryVoltage;
    double fixedEnergyBattery10 = 0.1 * capacity * batteryVoltage;
//the totalEnergyConsumption,area1Energy,area2Energy,area3Energy are in kw but we applyed a ponderation with 1000 Given the limited battery capacity (3.7 Wh and 1ah)
    double energyCase1W = (totalEnergyConsumption) / 24;
    double energyCase2W = (area1Energy + area2Energy + area3Energy) / 24;
    double energyCase3W = (area1Energy + area2Energy) / 24;
    double energyCase4W = (area1Energy) / 24;

    if (ruleBasedEnabled) {
      if (batteryPercentage >= 70) {
        availableEnergy =
            (batteryPercentage - 70) * capacity * batteryVoltage / 100;
        double t1 = availableEnergy / energyCase1W;
        double t2 = (fixedEnergyBattery20 / energyCase2W) +
            (fixedEnergyBattery20 / energyCase3W) +
            (fixedEnergyBattery10 / energyCase4W);
        autonomy = t1 + t2;
      } else if (batteryPercentage >= 50 && batteryPercentage < 70) {
        availableEnergy =
            (batteryPercentage - 50) * capacity * batteryVoltage / 100;
        double t1 = availableEnergy / energyCase2W;
        double t2 = (fixedEnergyBattery20 / energyCase3W) +
            (fixedEnergyBattery10 / energyCase4W);
        autonomy = t1 + t2;
      } else if (batteryPercentage >= 30 && batteryPercentage < 50) {
        availableEnergy =
            (batteryPercentage - 30) * capacity * batteryVoltage / 100;
        double t1 = availableEnergy / energyCase3W;
        double t2 = (fixedEnergyBattery10 / energyCase4W);
        autonomy = t1 + t2;
      } else if (batteryPercentage >= 20 && batteryPercentage < 30) {
        availableEnergy =
            (batteryPercentage - 20) * capacity * batteryVoltage / 100;
        double t1 = availableEnergy / energyCase4W;
        autonomy = t1;
      }
    } else {
      autonomy = ((batteryPercentage / 100) * capacity * batteryVoltage) /
          (energyCase1W);
    }
    print("batteryPercentage: $batteryPercentage");
    print("autonomy: $autonomy");

    return autonomy;
  }

  Future<void> _checkBatteryAndSendEmail() async {
    if (batteryPercentage < 30) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEmail = user.email;
        if (userEmail != null) {
          _sendEmail(
              userEmail, batteryPercentage); // Call _sendEmail with userEmail
        }
      }
    }
  }

  Future<void> _sendEmail(String userEmail, double soc) async {
    final serviceId = 'service_y4yy5cw'; // Replace with your EmailJS service ID
    final templateId =
        'template_294ldkg'; // Replace with your EmailJS template ID
    final userId = 'sw8a4y-0zlsMHrrJI'; // Replace with your EmailJS public key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId, // Correct parameter
        'template_params': {
          'userEmail': userEmail, // Matches template variable {{userEmail}}
          'name': 'GreenVolt Alert', // Matches {{name}}
          'subject': 'Low Battery Alert', // Matches {{subject}}
          'message':
              'Battery SoC is below 30% (${soc.toStringAsFixed(1)}%). Only areas with priority one are currently working.',
          'time': DateTime.now().toString(), // Matches {{time}}, optional
        }
      }),
    );

    print(
        'EmailJS Response: ${response.body}'); // Print the response for debugging
  }
  /* Future<void> _sendEmail(String recipientEmail, double soc) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {
        'subject': 'Low Battery Alert',
        'body':
            'Battery SoC is below 30% (${soc.toStringAsFixed(1)}%). Only areas with priority one are currently working.',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print('Could not launch email');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }*/

  @override
  Widget build(BuildContext context) {
    double? autonomy = calculateAutonomy();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/batt.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFF3BA040).withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.battery_charging_full, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Battery status',
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 13.0,
                        percent: batteryPercentage / 100,
                        center: Text(
                          '${batteryPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                        progressColor: Colors.green,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Capacity $capacity Ah',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Voltage: ${batteryVoltage.toStringAsFixed(2)} V',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _modifyBatteryInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Modify Battery Info',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Autonomy: ${autonomy != null ? autonomy.toStringAsFixed(2) : "NaN"} hours',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Rule-Based Prioritization',
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: ruleBasedEnabled,
                            onChanged: _toggleRuleBased,
                            activeColor: Colors.green,
                          ),
                        ],
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
                      icon: const Icon(
                        Icons.battery_charging_full,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/battery');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.home,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
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

  void _modifyBatteryInfo() {
    showDialog(
      context: context,
      builder: (context) {
        int newCapacity = capacity;
        double newBatteryVoltage = batteryVoltage;

        return AlertDialog(
          title: const Text('Modify Battery Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacity (Ah)',
                  hintText: '$capacity',
                ),
                onChanged: (value) {
                  newCapacity = int.tryParse(value) ?? capacity;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Battery Voltage (V)',
                  hintText: '$batteryVoltage',
                ),
                onChanged: (value) {
                  newBatteryVoltage = double.tryParse(value) ?? batteryVoltage;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save new values
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .set({
                  'capacity': newCapacity,
                  'batteryVoltage': newBatteryVoltage,
                }, SetOptions(merge: true));
                Navigator.of(context).pop();
                setState(() {
                  capacity = newCapacity;
                  batteryVoltage = newBatteryVoltage;
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
