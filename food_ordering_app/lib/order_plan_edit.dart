import 'package:flutter/material.dart';
import 'database_helper.dart';

// Stateful widget for editing an existing order plan
class OrderPlanEdit extends StatefulWidget {
  final int planId; // Unique identifier for the order plan
  final String date; // Date associated with the order plan
  final double targetCost; // Target budget for the order plan
  final String items; // Comma-separated list of items in the order plan

  const OrderPlanEdit({
    super.key,
    required this.planId,
    required this.date,
    required this.targetCost,
    required this.items,
  });

  @override
  _OrderPlanEditState createState() => _OrderPlanEditState();
}

// Manages the state and logic for editing an order plan
class _OrderPlanEditState extends State<OrderPlanEdit> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // Helper for database operations
  List<Map<String, dynamic>> foodItems = []; // Stores all food items available in the database
  Map<String, int> selectedItems = {}; // Tracks selected items and their quantities
  double currentCost = 0.0; // Total cost of selected items
  double targetCost = 0.0; // Target cost for the order plan (editable)

  @override
  void initState() {
    super.initState();
    targetCost = widget.targetCost; // Initialize the target cost
    loadFoodItems(); // Load food items and populate the state
  }

  // Fetches all food items from the database and initializes selected items
  Future<void> loadFoodItems() async {
    final items = await dbHelper.fetchFoodItems(); // Fetch food items from the database
    setState(() {
      foodItems = items; // Update the list of food items
    });

    // Parse the comma-separated items from the widget and update selected items
    List<String> initialItems = widget.items.split(', ');
    for (var item in initialItems) {
      if (item.isNotEmpty) {
        selectedItems[item] = (selectedItems[item] ?? 0) + 1; // Count occurrences of each item
      }
    }

    calculateCurrentCost(); // Calculate the total cost of selected items
  }

  // Calculates the total cost of all selected items
  void calculateCurrentCost() {
    double cost = 0.0;
    selectedItems.forEach((name, quantity) {
      final item = foodItems.firstWhere(
        (element) => element['name'] == name,
        orElse: () => {}, // Handle missing items gracefully
      );
      if (item.isNotEmpty) {
        cost += item['cost'] * quantity; // Add the cost for each quantity of the item
      }
    });
    setState(() {
      currentCost = cost; // Update the total cost in the state
    });
  }

  // Displays an error dialog with a specified message
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Dark-themed background
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            message, // Error message to display
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  // Adds a food item to the selection and updates the total cost
  void addFoodItem(Map<String, dynamic> item) {
    final itemName = item['name'];
    final itemCost = item['cost'];

    // Check if adding the item exceeds the target cost
    if (currentCost + itemCost <= targetCost) {
      setState(() {
        selectedItems[itemName] = (selectedItems[itemName] ?? 0) + 1; // Increment the quantity
        currentCost += itemCost; // Add the item's cost to the total
      });
    } else {
      showErrorDialog('Adding this item exceeds your target cost!'); // Show an error message
    }
  }

  // Removes a food item from the selection and updates the total cost
  void removeFoodItem(String itemName) {
    if (selectedItems[itemName] != null && selectedItems[itemName]! > 0) {
      final item = foodItems.firstWhere(
        (element) => element['name'] == itemName,
        orElse: () => {}, // Handle missing items gracefully
      );

      if (item.isNotEmpty) {
        setState(() {
          currentCost -= item['cost']; // Deduct the item's cost from the total
          if (selectedItems[itemName] == 1) {
            selectedItems.remove(itemName); // Remove the item if quantity reaches zero
          } else {
            selectedItems[itemName] = selectedItems[itemName]! - 1; // Decrement the quantity
          }
        });
      }
    }
  }

  // Updates the target cost and validates it against the current cost
  void updateTargetCost(double newTargetCost) {
    if (newTargetCost < currentCost) {
      showErrorDialog(
          'Target cost cannot be less than current cost! Items have been reset.'); // Show error
      setState(() {
        selectedItems.clear(); // Clear all selected items
        currentCost = 0.0; // Reset the total cost
      });
    } else {
      setState(() {
        targetCost = newTargetCost; // Update the target cost
      });
    }
  }

  // Saves the updated order plan to the database
  Future<void> saveOrderPlan() async {
    // Validate that all required fields are set
    if (selectedItems.isEmpty || targetCost <= 0) {
      showErrorDialog('Please set all required fields!'); // Show an error message
      return;
    }

    // Create a comma-separated list of selected items
    List<String> itemsList = [];
    selectedItems.forEach((name, quantity) {
      for (int i = 0; i < quantity; i++) {
        itemsList.add(name);
      }
    });
    String updatedItems = itemsList.join(', '); // Join the items into a single string

    await dbHelper.updateOrderPlan(widget.planId, targetCost.toString(), updatedItems); // Update the plan

    // Show a success dialog and return to the previous screen
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Dark-themed background
          title: const Text(
            'Success',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Order plan updated successfully!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Navigate back to the previous screen
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  // Opens a dialog to edit the target cost
  void showEditTargetCostDialog() {
    final TextEditingController targetCostController =
        TextEditingController(text: targetCost.toStringAsFixed(2)); // Pre-fill with current target cost

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Dark-themed background
          title: const Text(
            'Edit Target Cost',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green,
            ),
          ),
          content: TextField(
            controller: targetCostController, // Input for new target cost
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Target Cost',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without saving
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                final newTargetCost = double.tryParse(targetCostController.text) ?? targetCost; // Parse input
                updateTargetCost(newTargetCost); // Update the target cost
                Navigator.pop(context); // Close the dialog
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Order Plan')), // Screen title
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0), // Padding around the section
            child: Column(
              children: [
                Text(
                  widget.date, // Display the date of the order plan
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16), // Spacing between sections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute elements
                  children: [
                    Row(
                      children: [
                        Text(
                          'Target Cost: \$${targetCost.toStringAsFixed(2)}', // Display the target cost
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green), // Edit button
                          onPressed: showEditTargetCostDialog, // Open the edit dialog
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Styling for cost display
                      decoration: BoxDecoration(
                        color: Colors.green, // Green background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Current Cost: \$${currentCost.toStringAsFixed(2)}', // Display the current cost
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length, // Number of food items to display
              itemBuilder: (context, index) {
                final item = foodItems[index]; // Current food item
                final itemName = item['name']; // Name of the item
                final itemQuantity = selectedItems[itemName] ?? 0; // Quantity of the item selected

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Card styling
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
                  child: ListTile(
                    title: Text(
                      itemName, // Display the item's name
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('\$${item['cost']}'), // Display the item's cost
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Minimize space usage
                      children: [
                        IconButton(
                          iconSize: 36, // Button size
                          icon: const Icon(Icons.remove_circle, color: Colors.red), // Remove button
                          onPressed: itemQuantity > 0 ? () => removeFoodItem(itemName) : null, // Remove action
                        ),
                        Text(
                          '$itemQuantity', // Display the item's quantity
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          iconSize: 36, // Button size
                          icon: const Icon(Icons.add_circle, color: Colors.green), // Add button
                          onPressed: () => addFoodItem(item), // Add action
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(), // Horizontal divider
          Padding(
            padding: const EdgeInsets.all(8.0), // Padding for the button
            child: ElevatedButton(
              onPressed: saveOrderPlan, // Save changes
              child: const Text('Save Changes'), // Button label
            ),
          ),
        ],
      ),
    );
  }
}