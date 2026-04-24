import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpage.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({
    super.key,
    required this.startStation,
    required this.endStation,
    required this.stopCount,
    required this.lineChanges,
    required this.minutes,
    required this.fare,
    this.passengerName,
    this.paidAt,
    this.paymentMethod = 'PromptPay',
    this.paymentRef,
  });

  final String startStation;
  final String endStation;
  final int stopCount;
  final int lineChanges;
  final int minutes;
  final int fare;
  final String? passengerName;
  final DateTime? paidAt;
  final String paymentMethod;
  final String? paymentRef;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  String? firstName;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          firstName = (doc.data()?['firstName'] as String?)?.trim();
          firstName ??= user.email;
        });
      } else {
        setState(() {
          firstName = user.email;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = widget.paidAt ?? DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จรับเงิน'),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long, size: 56, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    'BTS / MRT Ticket Receipt',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(thickness: 1.2, height: 28),

                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(widget.passengerName ?? 'ผู้โดยสาร'),
                    subtitle: Text('ชื่อผู้จอง: ${firstName ?? "กำลังโหลด..."}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.train),
                    title: Text('${widget.startStation} ➝ ${widget.endStation}'),
                    subtitle: Text(
                      'จำนวนสถานี ${widget.stopCount} • เปลี่ยนสาย ${widget.lineChanges}',
                    ),
                    trailing: Text('${widget.minutes} นาที'),
                  ),

                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.payments),
                    title: Text('ชำระเงินโดย: ${widget.paymentMethod}'),
                    subtitle: Text('รหัสอ้างอิง: ${widget.paymentRef ?? "-"}'),
                    trailing: Text(
                      '฿${widget.fare}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('ชำระเมื่อ ${fmt.format(dt)}'),
                  const SizedBox(height: 14),
                  Text(
                    'ขอบคุณที่ใช้บริการ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // ปุ่มออกจากระบบด้านล่าง (เผื่อผู้ใช้หาไอคอนด้านบนไม่เจอ)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _signingOut ? null : _confirmSignOut,
                      icon: _signingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_signingOut ? 'กำลังออกจากระบบ...' : 'ออกจากระบบ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
