import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentsTab extends StatelessWidget {
  const AdminPaymentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payments Management")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No payments recorded yet."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;
              String type = orderData['type'] ?? 'Newspaper'; 
              String zipcode = orderData['zipcode'] ?? 'N/A';
              double amount = (orderData['total_amount'] as num?)?.toDouble() ?? 0.0;
              String mode = orderData['payment_mode'] ?? 'PhonePe';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == 'Greens' ? Colors.green : Colors.blue,
                    child: Icon(
                      type == 'Greens' ? Icons.eco : Icons.newspaper,
                      color: Colors.white,
                    ),
                  ),
                  title: Text("$type Order - ₹$amount"),
                  subtitle: Text("Zipcode: $zipcode | Payment Mode: $mode"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showOrderDetailsDialog(context, orderData);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, Map<String, dynamic> orderData) {
    List items = orderData['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${orderData['type']} Order Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Zipcode: ${orderData['zipcode']}"),
            Text("Amount Paid: ₹${orderData['total_amount']}"),
            Text("Payment Mode: ${orderData['payment_mode']}"),
            Text("Payment Status: ${orderData['payment_status']}"),
            const SizedBox(height: 10),
            const Text("Items Ordered:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ...items.map((item) => Text("- ${item['name']} (Qty: ${item['quantity']})")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}