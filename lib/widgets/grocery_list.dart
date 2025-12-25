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
  final List<GroceryItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // --------------------------------
  // Load items from Firebase
  // --------------------------------
  Future<void> _loadItems() async {
    final url = Uri.https(
      'shopping-list-da658-default-rtdb.firebaseio.com',
      'items.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data';
          _isLoading = false;
        });
        return;
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      data.forEach((id, item) {
        final category =
            categories[Categories.values.firstWhere(
              (c) => c.name == item['category'],
            )]!;

        loadedItems.add(
          GroceryItem(
            id: id,
            name: item['name'],
            quantity: item['quantity'],
            category: category,
          ),
        );
      });

      setState(() {
        _items
          ..clear()
          ..addAll(loadedItems);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  // --------------------------------
  // Add new item
  // --------------------------------
  Future<void> _addItem(BuildContext context) async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (_) => const NewItem()));

    if (newItem == null) return;

    setState(() {
      _items.add(newItem);
    });
  }

  // --------------------------------
  // Remove item
  // --------------------------------
  void _removeItem(GroceryItem item) {
    final index = _items.indexOf(item);

    setState(() {
      _items.removeAt(index);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: const Text('Item removed'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _items.insert(index, item);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!));
    } else if (_items.isEmpty) {
      content = const Center(
        child: Text(
          'No items added yet.\nTap + to add one.',
          textAlign: TextAlign.center,
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeItem(item),
            background: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.red),
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
      );
    }

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
      body: RefreshIndicator(onRefresh: () => _loadItems(), child: content),
    );
  }
}
