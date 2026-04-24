import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:map_project/mrt.dart';
import 'main.dart';

class PickPage extends StatelessWidget {
  const PickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFBEE1F6),
                    const Color(0xFFC7E4F3),
                    cs.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // วงกลมนุ่มๆ (soft blobs) เพิ่มความพรีเมียม
          const _FloatingBlobs(),

          // การ์ดกระจกฟรอสต์ + เนื้อหา
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(.55),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // หัวเรื่อง
                          Text(
                            'เลือกการเดินทาง',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color.fromARGB(255, 176, 13, 13),
                                  letterSpacing: .4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'แตะปุ่มเพื่อเลือกเส้นทางการเดินทาง',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(.7),
                                ),
                          ),
                          const SizedBox(height: 22),

                          // ปุ่มตัวเลือก (Responsive: แถวเดียวบนจอแคบ / 2 คอลัมน์บนจอกว้าง)
                          LayoutBuilder(
                            builder: (context, c) {
                              final twoCols = c.maxWidth >= 520;
                              final children = [
                                _ModeCard(
                                  title: 'BTS',
                                  subtitle: 'รถไฟฟ้าบีทีเอส',
                                  color: const Color(0xFF0D47A1),
                                  icon: Icons.directions_train_rounded,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RouteHomePage(),
                                      ),
                                    );
                                  },
                                ),
                                _ModeCard(
                                  title: 'MRT',
                                  subtitle: 'รถไฟฟ้าเอ็มอาร์ที',
                                  color: const Color.fromARGB(255, 176, 13, 13),
                                  icon: Icons.directions_subway_rounded,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFB10D0D), Color(0xFFE53935)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const Mrt(),
                                      ),
                                    );
                                  },
                                ),
                              ];

                              return twoCols
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(child: children[0]),
                                        const SizedBox(width: 20),
                                        Expanded(child: children[1]),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        children[0],
                                        const SizedBox(height: 16),
                                        children[1],
                                      ],
                                    );
                            },
                          ),
                        ],
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
}

/// ปุ่มตัวเลือกสวยๆ แบบการ์ดไล่เฉด + กดแล้วเด้งเบาๆ
class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.98 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // พื้นหลังการ์ดไล่เฉด
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              // ลวดลายวงกลมโปร่งนิดๆ
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.10),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                bottom: -16,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.08),
                  ),
                ),
              ),
              // เนื้อหา
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(.35),
                          ),
                        ),
                        child: Icon(widget.icon, size: 34, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .4,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white.withOpacity(.95)),
                    ],
                  ),
                ),
              ),
              // เคลือบไฮไลต์กระจก
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(.08),
                            Colors.white.withOpacity(.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// พื้นหลังวงกลมนุ่มๆ เคลื่อนไหวเบาๆ
class _FloatingBlobs extends StatefulWidget {
  const _FloatingBlobs();

  @override
  State<_FloatingBlobs> createState() => _FloatingBlobsState();
}

class _FloatingBlobsState extends State<_FloatingBlobs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _a;
  late final Animation<double> _b;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _a = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _b = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              top: 120 + _a.value,
              left: -40,
              child: _softBall(cs.primary.withOpacity(.25), 200),
            ),
            Positioned(
              bottom: 80 + _b.value,
              right: -30,
              child: _softBall(cs.tertiary.withOpacity(.22), 170),
            ),
            Positioned(
              bottom: 260 - _a.value,
              left: 40,
              child: _softBall(cs.secondary.withOpacity(.18), 130),
            ),
          ],
        );
      },
    );
  }

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
