import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:groceries/data/categories.dart';
import 'package:groceries/models/grocery_item.dart';
import 'package:groceries/widgets/new_item.dart';
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
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.parse(
        'https://flutter-groceries-dad62-default-rtdb.firebaseio.com/groceries-list.json');
    try {
      final response = await http.get(
        url,
      );
      if (response.statusCode >= 400) {
        setState(() {
          _error =
              'Failed to fetch shopping List data. Please try again later.';
        });
      }
      //response body will be null when we have no items in our firebase
      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final categori = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: categori));
      }
      setState(() {
        _groceryItems = loadedItems;
        isLoading = false;
      });
      print(response.body);
    } catch (e) {
      setState(() {
        _error = 'Something went wrong, try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item) async {
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.parse(
        'https://flutter-groceries-dad62-default-rtdb.firebaseio.com/groceries-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // optional show error message
      setState(() {
        _groceryItems.insert(_groceryItems.indexOf(item), item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('Uh Oh, your groceries list is empty..'),
    );

    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (something) {
            setState(() {
              removeItem(_groceryItems[index]);
            });
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
        ),
        body: content);
  }
}
