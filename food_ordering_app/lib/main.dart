import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_plans.dart';

// Entry point of the Flutter application
void main() {
  runApp(const FoodOrderingApp());
}

// Main application widget, setting the app-wide theme and the initial screen
class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      // Custom dark theme with green accents
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        colorScheme: const ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
        // Styling for elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const FoodItemsScreen(), // The starting screen of the app
    );
  }
}

// Stateful widget to manage the logic and UI for creating an order plan
class FoodItemsScreen extends StatefulWidget {
  const FoodItemsScreen({super.key});

  @override
  _FoodItemsScreenState createState() => _FoodItemsScreenState();
}

// State class for handling user interaction and managing data
class _FoodItemsScreenState extends State<FoodItemsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // Helper for database operations
  List<Map<String, dynamic>> foodItems = []; // Stores food items fetched from the database
  Map<String, int> selectedItems = {}; // Keeps track of selected items and their quantities
  double targetCost = 0.0; // Maximum cost the user is willing to spend
  double currentCost = 0.0; // Cost of currently selected items
  String selectedDate = 'DATE NOT SELECTED'; // Stores the date selected by the user
  final TextEditingController targetCostController = TextEditingController(); // Controller for target cost input

  @override
  void initState() {
    super.initState();
    loadFoodItems(); // Load food items from the database on screen initialization
  }

  // Fetches the list of food items from the database and updates the state
  Future<void> loadFoodItems() async {
    final items = await dbHelper.fetchFoodItems();
    setState(() {
      foodItems = items;
    });
  }

  // Displays a dialog box for showing errors to the user
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            message,
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
                Navigator.pop(context); // Closes the dialog box
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

  // Adds a food item to the user's selection while checking the target cost limit
  void addFoodItem(Map<String, dynamic> item) {
    final itemName = item['name'];
    final itemCost = item['cost'];

    if (currentCost + itemCost <= targetCost) {
      setState(() {
        selectedItems[itemName] = (selectedItems[itemName] ?? 0) + 1; // Increment item count
        currentCost += itemCost; // Update the total cost
      });
    } else {
      showErrorDialog('Adding this item exceeds your target cost!');
    }
  }

  // Removes a food item from the user's selection
  void removeFoodItem(String itemName) {
    if (selectedItems[itemName] != null && selectedItems[itemName]! > 0) {
      final item = foodItems.firstWhere(
        (element) => element['name'] == itemName,
        orElse: () => {},
      );

      if (item.isNotEmpty) {
        setState(() {
          currentCost -= item['cost']; // Decrease the total cost
          if (selectedItems[itemName] == 1) {
            selectedItems.remove(itemName); // Remove the item if quantity reaches zero
          } else {
            selectedItems[itemName] = selectedItems[itemName]! - 1; // Decrease quantity
          }
        });
      }
    }
  }

  // Updates the target cost set by the user and validates against the current cost
  void updateTargetCost(double newTargetCost) {
    if (newTargetCost < currentCost) {
      showErrorDialog(
          'Target cost cannot be less than current cost! Items have been reset.');
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

  // Saves the current order plan to the database with validation checks
  Future<void> saveOrderPlan() async {
    if (selectedDate == 'DATE NOT SELECTED' || selectedItems.isEmpty || targetCost <= 0) {
      showErrorDialog('Please set all required fields!'); // Show error for invalid input
      return;
    }

    // Prepare a comma-separated list of selected items
    List<String> itemsList = [];
    selectedItems.forEach((name, quantity) {
      for (int i = 0; i < quantity; i++) {
        itemsList.add(name);
      }
    });
    String items = itemsList.join(', ');

    await dbHelper.insertOrderPlan(selectedDate, items, targetCost); // Save the order to the database

    // Display success message and reset selections
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Success',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Order plan saved successfully!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
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

    setState(() {
      selectedItems.clear(); // Reset selected items
      currentCost = 0.0; // Reset the total cost
    });
  }

  // Opens a date picker dialog for the user to select a date
  void showDatePickerDialog() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Default to current date
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2100), // Latest selectable date
    );

    if (picked != null) {
      setState(() {
        selectedDate = '${picked.year}-${picked.month}-${picked.day}'; // Update the selected date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order Plan')), // Title of the screen
      body: Column(
        children: [
          // Section for entering target cost and selecting a date
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Input field for setting the target cost
                    TextField(
                      controller: targetCostController,
                      decoration: const InputDecoration(
                        labelText: 'Target Cost',
                        labelStyle: TextStyle(fontSize: 18),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20),
                      onChanged: (value) {
                        final newTargetCost = double.tryParse(value) ?? 0.0;
                        updateTargetCost(newTargetCost);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Select Date'),
                          onPressed: showDatePickerDialog,
                        ),
                        Text(
                          selectedDate, // Displays the selected date
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Display current cost of selected items
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Current Cost: \$${currentCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // List of available food items
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                final itemName = item['name'];
                final itemQuantity = selectedItems[itemName] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(itemName),
                    subtitle: Text('\$${item['cost']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: itemQuantity > 0 ? () => removeFoodItem(itemName) : null,
                        ),
                        Text(
                          '$itemQuantity', // Display quantity of selected item
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => addFoodItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Buttons for saving or viewing order plans
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: saveOrderPlan, // Save current order plan
                  child: const Text('Save Order Plan'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderPlans()), // Navigate to view plans
                    );
                  },
                  child: const Text('View Order Plans'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}