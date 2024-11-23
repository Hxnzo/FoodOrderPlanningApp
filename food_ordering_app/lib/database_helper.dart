import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Helper class for managing SQLite database operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal(); // Singleton instance
  static Database? _database; // The database instance

  // Factory constructor to return the singleton instance
  factory DatabaseHelper() => _instance;

  // Private constructor to initialize the singleton
  DatabaseHelper._internal();

  // Getter to retrieve the database instance, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!; // Return existing database instance
    _database = await _initDatabase(); // Initialize database if null
    return _database!;
  }

  // Initializes the SQLite database
  Future<Database> _initDatabase() async {
    // Construct the database file path
    String path = join(await getDatabasesPath(), 'food_ordering.db');
    return await openDatabase(
      path, // Path to the database
      version: 1, // Database version for migrations
      onCreate: (db, version) async {
        // Create the `food_items` table
        await db.execute('''
          CREATE TABLE food_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT, // Auto-incrementing ID
            name TEXT NOT NULL, // Name of the food item
            cost REAL NOT NULL // Cost of the food item
          );
        ''');
        // Create the `order_plans` table
        await db.execute('''
          CREATE TABLE order_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT, // Auto-incrementing ID
            date TEXT NOT NULL, // Date of the order plan
            items TEXT NOT NULL, // Comma-separated list of items
            target_cost REAL NOT NULL // Target cost for the plan
          );
        ''');
      },
    );
  }

  // Inserts a new food item into the `food_items` table
  Future<void> insertFoodItem(String name, double cost) async {
    final db = await database; // Get database instance
    await db.insert('food_items', {'name': name, 'cost': cost}); // Insert item
  }

  // Fetches all food items from the `food_items` table
  Future<List<Map<String, dynamic>>> fetchFoodItems() async {
    final db = await database; // Get database instance
    return await db.query('food_items'); // Query all rows in `food_items`
  }

  // Deletes a food item from the `food_items` table by ID
  Future<void> deleteFoodItem(int id) async {
    final db = await database; // Get database instance
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]); // Delete row by ID
  }

  // Updates an existing food item in the `food_items` table
  Future<void> updateFoodItem(int id, String name, double cost) async {
    final db = await database; // Get database instance
    await db.update(
      'food_items', // Table name
      {'name': name, 'cost': cost}, // Columns to update
      where: 'id = ?', // Where clause
      whereArgs: [id], // Arguments for the where clause
    );
  }

  // Inserts a new order plan into the `order_plans` table
  Future<void> insertOrderPlan(String date, String items, double targetCost) async {
    final db = await database; // Get database instance
    await db.insert('order_plans', {
      'date': date,
      'items': items,
      'target_cost': targetCost,
    }); // Insert order plan
  }

  // Fetches order plans for a specific date from the `order_plans` table
  Future<List<Map<String, dynamic>>> fetchOrderPlans(String date) async {
    final db = await database; // Get database instance
    return await db.query('order_plans', where: 'date = ?', whereArgs: [date]); // Query by date
  }

  // Fetches all order plans from the `order_plans` table
  Future<List<Map<String, dynamic>>> fetchAllOrderPlans() async {
    final db = await database; // Get database instance
    return await db.query('order_plans'); // Query all rows in `order_plans`
  }

  // Deletes an order plan from the `order_plans` table by ID
  Future<void> deleteOrderPlan(int id) async {
    final db = await database; // Get database instance
    await db.delete('order_plans', where: 'id = ?', whereArgs: [id]); // Delete row by ID
  }

  // Updates an existing order plan in the `order_plans` table
  Future<void> updateOrderPlan(int id, String targetCost, String items) async {
    final db = await database; // Get database instance
    await db.update(
      'order_plans', // Table name
      {'target_cost': targetCost, 'items': items}, // Columns to update
      where: 'id = ?', // Where clause
      whereArgs: [id], // Arguments for the where clause
    );
  }
}