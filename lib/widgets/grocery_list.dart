import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/model/category.dart';
import 'package:shopping_list/model/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  late Future<List<GroceryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  // -------------------------------
  // Fetch items from Firebase
  // -------------------------------
  Future<List<GroceryItem>> _fetchItems() async {
    final url = Uri.https(
      'shopping-list-da658-default-rtdb.firebaseio.com',
      'items.json',
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<GroceryItem> items = [];

    data.forEach((id, item) {
      final category =
          categories[Categories.values.firstWhere(
            (c) => c.name == item['category'],
          )]!;

      items.add(
        GroceryItem(
          id: id,
          name: item['name'],
          quantity: item['quantity'],
          category: category,
        ),
      );
    });

    return items;
  }

  // -------------------------------
  // Add item
  // -------------------------------
  Future<void> _addItem(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NewItem()));

    if (result == true) {
      setState(() {
        _itemsFuture = _fetchItems(); // 🔑 refresh Future
      });
    }
  }

  // -------------------------------
  // Remove item
  // -------------------------------
  void _removeItem(GroceryItem item) {
    final url = Uri.https(
      'shopping-list-da658-default-rtdb.firebaseio.com',
      'items/${item.id}.json',
    );

    http.delete(url);

    setState(() {
      _itemsFuture = _fetchItems(); // 🔑 refresh after delete
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Item removed'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocery List'),
        actions: [
          IconButton(
            onPressed: () => _addItem(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<GroceryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No items added yet.\nTap + to add one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _itemsFuture = _fetchItems();
              });
              await _itemsFuture;
            },
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeItem(item),
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(item.name),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.category.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    trailing: Text(item.quantity.toString()),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
