import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_plan_edit.dart';

// Displays a list of saved order plans and provides options to edit or delete them
class OrderPlans extends StatefulWidget {
  const OrderPlans({super.key});

  @override
  _OrderPlansState createState() => _OrderPlansState();
}

// Manages the state and logic for displaying and interacting with order plans
class _OrderPlansState extends State<OrderPlans> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // Database helper for CRUD operations
  List<Map<String, dynamic>> orderPlans = []; // List of order plans fetched from the database

  @override
  void initState() {
    super.initState();
    loadOrderPlans(); // Load order plans when the screen initializes
  }

  // Fetches all order plans from the database and updates the UI
  Future<void> loadOrderPlans() async {
    final plans = await dbHelper.fetchAllOrderPlans(); // Fetches plans from the database
    setState(() {
      orderPlans = plans; // Updates the state with the fetched plans
    });
  }

  // Deletes an order plan from the database by ID and refreshes the list
  Future<void> deleteOrderPlan(int id) async {
    await dbHelper.deleteOrderPlan(id); // Deletes the plan with the given ID
    loadOrderPlans(); // Reloads the list of plans to reflect changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Plans')), // Screen title
      // Displays a message if no order plans are found, else shows a list of plans
      body: orderPlans.isEmpty
          ? const Center(
              child: Text(
                'No Order Plans Found', // Message displayed when there are no plans
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: orderPlans.length, // Number of order plans in the list
              itemBuilder: (context, index) {
                final plan = orderPlans[index]; // Current order plan data
                return Card(
                  color: Colors.grey[850], // Background color of the card
                  margin: const EdgeInsets.all(8.0), // Margin around the card
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 3, // Shadow effect for the card
                  child: ListTile(
                    // Displays the date of the order plan
                    title: Text(
                      'Date: ${plan['date']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Displays additional details about the order plan
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Cost: \$${plan['target_cost']}'), // Displays the target cost
                        Text('Items: ${plan['items']}'), // Displays the items in the plan
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Ensures buttons take minimal space
                      children: [
                        // Button to navigate to the edit screen for the order plan
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green), // Edit icon
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderPlanEdit(
                                  planId: plan['id'], // Passes the ID to the edit screen
                                  date: plan['date'], // Passes the date to the edit screen
                                  targetCost: plan['target_cost'], // Passes the target cost
                                  items: plan['items'], // Passes the items list
                                ),
                              ),
                            ).then((_) => loadOrderPlans()); // Refreshes the list after editing
                          },
                        ),
                        // Button to delete the order plan with confirmation
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red), // Delete icon
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.grey[900], // Dialog background color
                                title: const Text('Delete Order Plan'), // Dialog title
                                content: const Text(
                                  'Are you sure you want to delete this order plan?', // Confirmation message
                                ),
                                actions: [
                                  // Cancel button to close the dialog without deleting
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Closes the dialog
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  // Delete button to confirm deletion
                                  TextButton(
                                    onPressed: () {
                                      deleteOrderPlan(plan['id']); // Deletes the selected plan
                                      Navigator.pop(context); // Closes the dialog
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red), // Red text for delete button
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}