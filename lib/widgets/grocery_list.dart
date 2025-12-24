import 'package:flutter/material.dart';
import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatelessWidget {
  const GroceryList({super.key});

  void addItem(BuildContext context) {
    // Function to add a new item (to be implemented)
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const NewItem()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocery List'),
        actions: [
          IconButton(
            onPressed: () {
              addItem(context);
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: groceryItems[index].category.color,
            ),
            trailing: Text(groceryItems[index].quantity.toString()),
          );
        },
      ),
    );
  }
}
