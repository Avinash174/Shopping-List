import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/model/category.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  String _enteredName = '';
  int _enteredQuantity = 1;
  Categories _selectedCategory = Categories.vegetables;

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSending = true;
    });

    final url = Uri.https(
      'shopping-list-da658-default-rtdb.firebaseio.com',
      'items.json',
    );

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _selectedCategory.name,
      }),
    );

    if (!mounted) return;

    Navigator.of(context).pop(true); // 🔑 IMPORTANT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter a valid name'
                    : null,
                onSaved: (value) => _enteredName = value!,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Invalid quantity'
                          : null,
                      onSaved: (value) => _enteredQuantity = int.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Categories>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: Categories.values.map((cat) {
                        final category = categories[cat]!;
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(category.title),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => _formKey.currentState!.reset(),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
