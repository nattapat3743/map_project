import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'loginpage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ---------- Utils ----------
  String _formatDate(dynamic value) {
    try {
      if (value == null) return '-';
      if (value is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(value.toDate());
      }
      if (value is DateTime) {
        return DateFormat('dd/MM/yyyy').format(value);
      }
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          return DateFormat('dd/MM/yyyy').format(dt);
        }
      }
      return '-';
    } catch (_) {
      return '-';
    }
  }

  String _composeDisplayName({
    required String firstName,
    required String lastName,
    required String? email,
  }) {
    final fn = firstName.trim();
    final ln = lastName.trim();
    if (fn.isNotEmpty && ln.isNotEmpty) return '$fn $ln';
    if (fn.isNotEmpty) return fn;
    if (ln.isNotEmpty) return ln;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return '-';
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final auth = FirebaseAuth.instance;
  final cs = Theme.of(context).colorScheme;

  Widget _loading() => const Center(child: CircularProgressIndicator());

  // กล่องโปร่งแบบกระจก
  Widget _frosted({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ปุ่มไล่เฉด
  Widget _gradientButton({
    required VoidCallback onPressed,
    required Widget child,
    List<Color>? colors,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (colors ?? [cs.primary])[0].withOpacity(.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: child,
      ),
    );
  }

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      title: const Text('โปรไฟล์'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _gradientButton(
            colors: const [Color(0xFFE53935), Color(0xFFEF5350)],
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Row(
              children: [Icon(Icons.logout, size: 18), SizedBox(width: 6), Text('ออกจากระบบ')],
            ),
          ),
        ),
      ],
    ),

    body: Stack(
      children: [
        // พื้นหลังไล่เฉด + วงกลมนุ่มๆ
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer.withOpacity(.55), cs.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(top: 120, left: -40, child: _softBlob(cs.primary.withOpacity(.22), 200)),
        Positioned(bottom: 80, right: -30, child: _softBlob(cs.tertiary.withOpacity(.20), 170)),
        Positioned(bottom: 260, left: 40, child: _softBlob(cs.secondary.withOpacity(.18), 130)),

        // เนื้อหา
        StreamBuilder<User?>(
          stream: auth.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) return _loading();

            final user = authSnap.data;
            if (user == null) {
              return Center(
                child: _frosted(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 46),
                        const SizedBox(height: 10),
                        Text('กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _gradientButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Icon(Icons.login), SizedBox(width: 8), Text('เข้าสู่ระบบ')],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return _loading();
                if (userSnap.hasError) {
                  return Center(child: _errorCard('เกิดข้อผิดพลาด: ${userSnap.error}'));
                }
                final doc = userSnap.data;
                if (doc == null || !doc.exists) {
                  return Center(child: _errorCard('ไม่พบข้อมูลผู้ใช้'));
                }

                final data = doc.data() ?? <String, dynamic>{};
                final firstName = (data['firstName'] ?? '').toString();
                final lastName  = (data['lastName']  ?? '').toString();
                final email     = (data['email']     ?? user.email ?? '').toString();
                final createdAt = data['createdAt'];

                final displayName = _composeDisplayName(
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                );

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          // หัวการ์ดโปรไฟล์
                          _frosted(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                              child: Column(
                                children: [
                                  // Avatar วงแหวนไล่เฉด
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [cs.primary, cs.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 48,
                                      child: Icon(Icons.person, size: 48),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    displayName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurface.withOpacity(.7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // รายละเอียด
                          _frosted(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _profileInfoRow(icon: Icons.person, label: 'ชื่อ', value: firstName),
                                  const Divider(height: 24),
                                  _profileInfoRow(icon: Icons.person_outline, label: 'นามสกุล', value: lastName),
                                  const Divider(height: 24),
                                  _profileInfoRow(icon: Icons.email, label: 'อีเมล', value: email),
                                  if (createdAt != null) ...[
                                    const Divider(height: 24),
                                    _profileInfoRow(
                                      icon: Icons.calendar_today,
                                      label: 'วันที่สมัคร',
                                      value: _formatDate(createdAt),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  );
}

// วงกลมนุ่มๆ พื้นหลัง
Widget _softBlob(Color color, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color,
          blurRadius: size / 2.4,
          spreadRadius: size / 9,
        ),
      ],
    ),
  );
}

// การ์ดข้อความผิดพลาดแบบฟรอสต์
Widget _errorCard(String msg) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    ),
  );
}
}