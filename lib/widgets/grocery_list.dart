import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_items.dart';
import 'package:shopping_list_app/widgets/new_list.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final url = Uri.https('shopping-list-efa84-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(
        () {
          _error = 'Error ${response.statusCode.toString()}';
        },
      );
    }
    if (response.body == 'null') {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }
    setState(
      () {
        _groceryItems = loadedItems;
        isLoading = false;
      },
    );
  }

  void _addItem() async {
    final newItems = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const NewItemspage(),
      ),
    );
    if (newItems == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItems);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('shopping-list-efa84-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final reponse = await http.delete(url);
    if (reponse.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error ${reponse.statusCode.toString()}, Failed to delete. try again later.'),
        ),
      );

      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            leading: Container(
              height: 24,
              width: 24,
              color: _groceryItems[index].category.color,
            ),
            title: Text(_groceryItems[index].name),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(
                  0.4,
                ),
              ),
            ),
            Text(
              'Failed to fetch data. please try again later.',
              style: TextStyle(
                color: Colors.white.withOpacity(
                  0.8,
                ),
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
          title: const Text('Your Groceries'),
          elevation: 0,
        ),
        body: content);
  }
}
