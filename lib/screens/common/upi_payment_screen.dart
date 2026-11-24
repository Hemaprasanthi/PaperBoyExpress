import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';

/// Shows a UPI QR code that is valid for [kUpiQrValidity]. Pops with `true` once
/// the payment has been confirmed and [onPaid] has finished.
///
/// The UPI id is a dummy and nothing verifies the payment yet, so confirming is
/// a manual "I've paid" tap. Swap that for a payment-gateway callback later.
class UpiPaymentScreen extends StatefulWidget {
  final double amount;
  final String description;

  /// Runs after the customer confirms payment; throw to show an error and stay on the screen.
  final Future<void> Function(String transactionRef) onPaid;

  const UpiPaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.onPaid,
  });

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  late String _transactionRef;
  late DateTime _expiresAt;
  Timer? _ticker;
  Duration _remaining = kUpiQrValidity;
  bool _busy = false;

  bool get _expired => _remaining <= Duration.zero;

  @override
  void initState() {
    super.initState();
    _generate();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _generate() {
    _transactionRef = 'PBX${DateTime.now().millisecondsSinceEpoch}';
    _expiresAt = DateTime.now().add(kUpiQrValidity);
    _remaining = kUpiQrValidity;
  }

  void _tick() {
    if (!mounted) return;
    final left = _expiresAt.difference(DateTime.now());
    setState(() => _remaining = left > Duration.zero ? left : Duration.zero);
  }

  String get _upiUri {
    String enc(String s) => Uri.encodeComponent(s);
    return 'upi://pay?pa=${enc(kUpiId)}&pn=${enc(kUpiPayeeName)}'
        '&am=${widget.amount.toStringAsFixed(2)}&cu=INR'
        '&tn=${enc(widget.description)}&tr=${enc(_transactionRef)}';
  }

  String get _countdown {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirmPaid() async {
    if (_expired || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPaid(_transactionRef);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowTime = _remaining.inMinutes < 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay with UPI')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(formatInr(widget.amount),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(widget.description, style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Scan with any UPI app',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: _expired
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_off_outlined, size: 48, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text('QR code expired',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : QrImageView(
                            data: _upiUri,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (_expired)
                    FilledButton.icon(
                      onPressed: () => setState(_generate),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate new QR'),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 18, color: lowTime ? Colors.red : Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Valid for $_countdown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: lowTime ? Colors.red : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SelectableText('UPI ID: $kUpiId',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('Ref: $_transactionRef',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_expired || _busy) ? null : _confirmPaid,
            icon: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_busy ? 'Confirming...' : 'I\'ve completed the payment'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 12),
          Text(
            'Demo mode: the UPI ID is a placeholder and payments aren\'t verified yet - '
            'tapping the button above marks this payment as done.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
