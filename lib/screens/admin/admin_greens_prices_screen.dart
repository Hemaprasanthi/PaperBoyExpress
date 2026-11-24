import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGreensPricesScreen extends StatefulWidget {
  const AdminGreensPricesScreen({Key? key}) : super(key: key);

  @override
  _AdminGreensPricesScreenState createState() => _AdminGreensPricesScreenState();
}

class _AdminGreensPricesScreenState extends State<AdminGreensPricesScreen> {
  final TextEditingController _zipcodeController = TextEditingController(text: "560102");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updatePrice(String docId, double newPrice) {
    String zipcode = _zipcodeController.text.trim();
    _firestore.collection('greens').doc(docId).set({
      'zipcode_pricing': {
        zipcode: {
          'price': newPrice,
          'available': true,
        }
      }
    }, SetOptions(merge: true));
  }

  void _addNewGreenDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Green Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price for Zipcode"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                String zipcode = _zipcodeController.text.trim();
                _firestore.collection('greens').add({
                  'name': nameController.text.trim(),
                  'zipcode_pricing': {
                    zipcode: {
                      'price': double.parse(priceController.text),
                      'available': true,
                    }
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Greens Prices"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewGreenDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _zipcodeController,
              decoration: const InputDecoration(
                labelText: "Target Zipcode",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('greens').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                String activeZip = _zipcodeController.text.trim();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    var zipData = data['zipcode_pricing']?[activeZip];
                    double price = zipData != null ? (zipData['price'] as num).toDouble() : 0.0;

                    return ListTile(
                      title: Text(data['name'] ?? 'Unnamed Green'),
                      subtitle: Text("Price in $activeZip: ₹$price"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          TextEditingController editPriceController = TextEditingController(text: price.toString());
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Edit Price for ${data['name']}"),
                              content: TextField(
                                controller: editPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: "Price in $activeZip"),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () {
                                    _updatePrice(docs[index].id, double.parse(editPriceController.text));
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Save"),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}