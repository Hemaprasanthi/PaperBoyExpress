import 'package:flutter/material.dart';
import 'package0:cloud_firestore/cloud_firestore.dart';

class GreensCheckoutScreen extends StatefulWidget {
  final String userZipcode;
  final List<Map<String, dynamic>> cartItems;

  const GreensCheckoutScreen({
    Key? key,
    required this.userZipcode,
    required this.cartItems,
  }) : super(key: key);

  @override
  _GreensCheckoutScreenState createState() => _GreensCheckoutScreenState();
}

class _GreensCheckoutScreenState extends State<GreensCheckoutScreen> {
  bool _isProcessing = false;

  double get totalAmount {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  Future<void> _processPhonePePayment() async {
    // 1. Verify Zipcode
    if (widget.userZipcode != '560102') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greens delivery is currently only available for 560102.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 2. Trigger PhonePe SDK (use your existing PhonePe implementation from Newspapers)
      bool isSuccess = await initiatePhonePeSDKPayment(totalAmount);

      if (isSuccess) {
        // 3. Write Order to Firestore for Admin Payments Tab
        await FirebaseFirestore.instance.collection('orders').add({
          'type': 'Greens',
          'zipcode': widget.userZipcode,
          'items': widget.cartItems,
          'total_amount': totalAmount,
          'payment_mode': 'PhonePe',
          'payment_status': 'Paid',
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greens order placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Replace with your current PhonePe method call
  Future<bool> initiatePhonePeSDKPayment(double amount) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text("Zipcode: ${widget.userZipcode}"),
                  trailing: Text("₹${item['price'] * item['quantity']}"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPhonePePayment,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("Pay ₹$totalAmount with PhonePe"),
            ),
          )
        ],
      ),
    );
  }
}