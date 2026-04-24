import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // แอนิเมชันพื้นหลังนุ่มๆ
  late final AnimationController _ctrl;
  late final Animation<double> _float1;
  late final Animation<double> _float2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _float1 = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _float2 = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // อัปเดต indicator ความแข็งแรงรหัสผ่านแบบเรียลไทม์ (ไม่เกี่ยวกับ validate)
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      isDense: true,
      fillColor: cs.surface.withOpacity(0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
    );
  }

  // ตัวช่วยแสดงความแข็งแรงของรหัสผ่าน (แค่ UI ไม่ไปเปลี่ยนกฎ validate)
  ({String label, double score, Color color}) _passwordStrength(String s) {
    int score = 0;
    if (s.length >= 6) score++;
    if (s.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;
    if (RegExp(r'[0-9]').hasMatch(s)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`/\\\[\]]').hasMatch(s)) score++;

    if (s.isEmpty) {
      return (label: 'รหัสผ่าน', score: 0.0, color: Colors.transparent);
    } else if (score <= 2) {
      return (label: 'อ่อน', score: 0.33, color: Colors.redAccent);
    } else if (score == 3) {
      return (label: 'ปานกลาง', score: 0.66, color: Colors.orange);
    } else {
      return (label: 'แข็งแรง', score: 1.0, color: Colors.green);
    }
  }

  Future<void> _register() async {
    // ตรวจสอบความถูกต้องเมื่อ "กด" ปุ่มสมัครสมาชิกเท่านั้น
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง')),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // บันทึกเฉพาะข้อมูลจำเป็น (ไม่เก็บรหัสผ่าน)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลงทะเบียนสำเร็จ')),
      );

      // กลับไปหน้าเข้าสู่ระบบ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'weak-password':
          message = 'รหัสผ่านควรยาวอย่างน้อย 6 ตัวอักษร';
          break;
        case 'invalid-email':
          message = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'operation-not-allowed':
          message = 'โปรดเปิดใช้งาน Email/Password ใน Firebase Auth';
          break;
        default:
          message = 'สมัครสมาชิกไม่สำเร็จ (${e.code})';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถสมัครสมาชิกได้ กรุณาลองใหม่ ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strength = _passwordStrength(_passwordCtrl.text);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // พื้นหลังไล่เฉด
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
          // วงกลมนุ่มๆ เคลื่อนไหว
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: 120 + _float1.value,
                  left: -30,
                  child: _softBall(cs.primary.withOpacity(.25), 180),
                ),
                Positioned(
                  bottom: 90 + _float2.value,
                  right: -40,
                  child: _softBall(cs.tertiary.withOpacity(.22), 160),
                ),
                Positioned(
                  bottom: 260 - _float1.value,
                  left: 24,
                  child: _softBall(cs.secondary.withOpacity(.18), 120),
                ),
              ],
            ),
          ),

          // การ์ดกระจกฟรอสต์
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(.55),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withOpacity(.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode
                            .disabled, // แจ้งเตือนเฉพาะตอนกดปุ่ม
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Header(),
                            const SizedBox(height: 20),

                            // ชื่อ-นามสกุล (จัดเคียงกันบนจอใหญ่)
                            LayoutBuilder(
                              builder: (context, c) {
                                final twoCols = c.maxWidth >= 460;
                                return twoCols
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _firstNameCtrl,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: _decoration(
                                                label: 'ชื่อ',
                                                icon: Icons.badge,
                                              ),
                                              validator: (v) => (v == null ||
                                                      v.trim().isEmpty)
                                                  ? 'กรุณากรอกชื่อ'
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _lastNameCtrl,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: _decoration(
                                                label: 'นามสกุล',
                                                icon: Icons.badge_outlined,
                                              ),
                                              validator: (v) => (v == null ||
                                                      v.trim().isEmpty)
                                                  ? 'กรุณากรอกนามสกุล'
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          TextFormField(
                                            controller: _firstNameCtrl,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: _decoration(
                                              label: 'ชื่อ',
                                              icon: Icons.badge,
                                            ),
                                            validator: (v) => (v == null ||
                                                    v.trim().isEmpty)
                                                ? 'กรุณากรอกชื่อ'
                                                : null,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _lastNameCtrl,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: _decoration(
                                              label: 'นามสกุล',
                                              icon: Icons.badge_outlined,
                                            ),
                                            validator: (v) => (v == null ||
                                                    v.trim().isEmpty)
                                                ? 'กรุณากรอกนามสกุล'
                                                : null,
                                          ),
                                        ],
                                      );
                              },
                            ),
                            const SizedBox(height: 12),

                            // อีเมล
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  _decoration(label: 'อีเมล', icon: Icons.email),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (value.isEmpty) {
                                  return 'กรุณากรอกอีเมล';
                                }
                                if (!emailRegex.hasMatch(value)) {
                                  return 'รูปแบบอีเมลไม่ถูกต้อง';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // รหัสผ่าน + strength bar
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                label: 'รหัสผ่าน',
                                icon: Icons.lock,
                                suffix: IconButton(
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                  icon: Icon(_obscurePass
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  tooltip: _obscurePass
                                      ? 'แสดงรหัสผ่าน'
                                      : 'ซ่อนรหัสผ่าน',
                                ),
                              ),
                              validator: (v) {
                                final value = (v ?? '');
                                if (value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                if (value.length < 6) {
                                  return 'อย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            if (_passwordCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _StrengthBar(
                                value: strength.score,
                                color: strength.color,
                                label: 'ความแข็งแรง: ${strength.label}',
                              ),
                            ],
                            const SizedBox(height: 12),

                            // ยืนยันรหัสผ่าน
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              decoration: _decoration(
                                label: 'ยืนยันรหัสผ่าน',
                                icon: Icons.lock_reset,
                                suffix: IconButton(
                                  onPressed: () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(_obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  tooltip: _obscureConfirm
                                      ? 'แสดงรหัสผ่าน'
                                      : 'ซ่อนรหัสผ่าน',
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? '').isEmpty) {
                                  return 'กรุณายืนยันรหัสผ่าน';
                                }
                                if (v != _passwordCtrl.text) {
                                  return 'รหัสผ่านไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ปุ่มสมัครสมาชิก (gradient)
                            SizedBox(
                              height: 50,
                              child: _GradientButton(
                                enabled: !_loading,
                                onPressed: _register,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.person_add_alt_1),
                                    const SizedBox(width: 8),
                                    Text(_loading
                                        ? 'กำลังสมัครสมาชิก...'
                                        : 'สมัครสมาชิก'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // กลับหน้าเข้าสู่ระบบ
                            TextButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.login),
                              label: const Text('กลับไปหน้าเข้าสู่ระบบ'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // วงกลมนุ่มๆ สำหรับพื้นหลัง
  Widget _softBall(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2.6,
            spreadRadius: size / 9,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // โลโก้แบบวงกลมไล่เฉด
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [cs.primary, cs.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(.32),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child:
              Icon(Icons.person_add_rounded, color: cs.onPrimary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'สร้างบัญชีใหม่',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'กรอกข้อมูลต่อไปนี้เพื่อสมัครสมาชิก',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(.65),
              ),
        ),
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value; // 0.0 - 1.0
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: cs.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.7),
              ),
        ),
      ],
    );
  }
}

// ปุ่ม Gradient รีโซลูชันสูง + เงานุ่ม
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.child,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? [cs.primary, cs.secondary]
              : [cs.surfaceVariant, cs.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: enabled ? cs.onPrimary : cs.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    );
  }
}
