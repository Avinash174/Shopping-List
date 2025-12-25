import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shopping_list/model/category.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  String _enteredName = '';
  int _enteredQuantity = 1;
  Categories _selectedCategory = Categories.vegetables;

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _enteredName = '';
      _enteredQuantity = 1;
      _selectedCategory = Categories.vegetables;
    });
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final url = Uri.https(
      'shopping-list-da658-default-rtdb.firebaseio.com',
      'items.json',
    );
    log('URL: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _selectedCategory.name,
      }),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    log(
      'Name: $_enteredName, Quantity: $_enteredQuantity, Category: ${_selectedCategory.name}',
    );

    debugPrint('Response: ${response.statusCode}');
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
                validator: (value) {
                  if (value == null ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Enter a valid name';
                  }
                  return null;
                },
                onSaved: (value) => _enteredName = value!,
              ),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) {
                        final qty = int.tryParse(value ?? '');
                        if (qty == null || qty <= 0) {
                          return 'Invalid quantity';
                        }
                        return null;
                      },
                      onSaved: (value) => _enteredQuantity = int.parse(value!),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: DropdownButtonFormField<Categories>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: Categories.values.map((key) {
                        final cat = categories[key]!;
                        return DropdownMenuItem<Categories>(
                          value: key,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(cat.title),
                            ],
                          ),
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
                  TextButton(onPressed: _resetForm, child: const Text('Reset')),
                  ElevatedButton(
                    onPressed: _saveItem,
                    child: const Text('Add Item'),
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
