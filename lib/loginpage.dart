import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:map_project/pick.dart';
import 'package:map_project/registerpage.dart';
import 'authenticationService.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

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

    _float1 = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _float2 = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ctrl.dispose();
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final success = await AuthenticationService()
          .login(_emailCtrl.text.trim(), _passCtrl.text.trim());

      if (!mounted) return;

      if (success) {
        // เข้าสู่ระบบสำเร็จ → ไปหน้าเลือก (PickPage)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PickPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบล้มเหลว')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดระหว่างเข้าสู่ระบบ')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // ทำให้ AppBar โปร่ง + กลืนพื้นหลัง
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('เข้าสู่ระบบเพื่อจองตั๋ว'),
      ),
      body: Stack(
        children: [
          // พื้นหลังสวยแบบไล่เฉด + วงกลมนุ่มๆ
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withOpacity(0.55),
                    cs.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // วงกลมตกแต่งเคลื่อนไหวเบาๆ
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 120 + _float1.value,
                    left: -40,
                    child: _softBall(cs.primary.withOpacity(.25), 180),
                  ),
                  Positioned(
                    bottom: 80 + _float2.value,
                    right: -30,
                    child: _softBall(cs.tertiary.withOpacity(.22), 160),
                  ),
                  Positioned(
                    bottom: 280 - _float1.value,
                    left: 40,
                    child: _softBall(cs.secondary.withOpacity(.18), 120),
                  ),
                ],
              );
            },
          ),
          // การ์ดกระจกฟรอสต์ (glass)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // โลโก้/ไอคอนหัวข้อ
                            _Header(cs: cs),
                            const SizedBox(height: 18),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  _decoration(label: 'อีเมล', icon: Icons.email_rounded),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                final emailRegex =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (value.isEmpty) return 'กรุณากรอกอีเมล';
                                if (!emailRegex.hasMatch(value)) {
                                  return 'รูปแบบอีเมลไม่ถูกต้อง';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: _decoration(
                                label: 'รหัสผ่าน',
                                icon: Icons.lock_rounded,
                                suffix: IconButton(
                                  tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? '').isEmpty) return 'กรุณากรอกรหัสผ่าน';
                                if ((v ?? '').length < 6) {
                                  return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ปุ่ม Login (gradient)
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: _GradientButton(
                                enabled: !_loading,
                                onPressed: _handleLogin,
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
                                      const Icon(Icons.login_rounded),
                                    const SizedBox(width: 8),
                                    Text(_loading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // แถบคั่นสวยๆ
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: cs.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'หรือ',
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(.7),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: cs.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // สมัครสมาชิก
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ยังไม่มีบัญชี?',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterPage(),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.person_add_alt_1_rounded),
                                  label: const Text('ลงทะเบียน'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                              ],
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
            blurRadius: size / 2.8,
            spreadRadius: size / 10,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // วงกลมโลโก้แบบไล่เฉด + ไอคอนกุญแจ
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                cs.primary,
                cs.primaryContainer,
              ],
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
          child: Icon(Icons.lock_outline_rounded, color: cs.onPrimary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'ยินดีต้อนรับ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'กรอกอีเมลและรหัสผ่านเพื่อเข้าสู่ระบบ',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(.65),
              ),
        ),
      ],
    );
  }
}

// ปุ่ม Gradient พร้อมสภาพกด/ปิดใช้งาน
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
