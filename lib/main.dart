import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// แอพคำนวณเส้นทาง BTS แบบออฟไลน์ (หาทางสั้นสุดตามจำนวนสถานี)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map',
      theme: ThemeData(useMaterial3: true, colorScheme: scheme),
      home: const RouteHomePage(),
    );
  }
}

class RouteHomePage extends StatefulWidget {
  const RouteHomePage({super.key});

  @override
  State<RouteHomePage> createState() => _RouteHomePageState();
}

class _RouteHomePageState extends State<RouteHomePage> {
  // ----------------------------- ข้อมูลเครือข่ายสถานี -----------------------------

  /// สายหลักที่รองรับ (ตัวอย่างชุดสถานีที่ใช้บ่อย)
  /// หมายเหตุ: ข้อมูลนี้ย่อ/สรุปเพื่อเดโม ถ้าต้องการครบทุกสถานีสามารถขยายเพิ่มภายหลังได้
  final List<String> sukhumvit = [
    'Khu Khot',
    'Ha Yaek Lat Phrao',
    'Mo Chit',
    'Saphan Khwai',
    'Ari',
    'Sanam Pao',
    'Victory Monument',
    'Phaya Thai',
    'Ratchathewi',
    'Siam', // interchange (Sukhumvit <-> Silom)
    'Chit Lom',
    'Phloen Chit',
    'Nana',
    'Asok',
    'Phrom Phong',
    'Thong Lo',
    'Ekkamai',
    'Phra Khanong',
    'On Nut',
    'Bang Chak',
    'Punnawithi',
    'Udom Suk',
    'Bang Na',
    'Bearing',
    'Samrong',
    'Chang Erawan',
    'Royal Thai Naval Academy',
    'Pak Nam',
    'Srinagarindra',
    'Phraek Sa',
    'Sai Luat',
    'Kheha',
  ];

  final List<String> silom = [
    'Bang Wa',
    'Wutthakat',
    'Talat Phlu',
    'Pho Nimit',
    'Wongwian Yai',
    'Krung Thon Buri', // interchange (Silom <-> Gold)
    'Saphan Taksin',
    'Surasak',
    'Chong Nonsi',
    'Sala Daeng',
    'Ratchadamri',
    'Siam', // interchange (Silom <-> Sukhumvit)
    'National Stadium',
  ];

  final List<String> gold = [
    'Krung Thon Buri', // interchange (Silom <-> Gold)
    'Charoen Nakhon',
    'Khlong San',
  ];

  /// ระบุว่าสถานีอยู่สายไหน (กรณีซ้ำได้หลายสาย เช่น Siam, Krung Thon Buri)
  late final Map<String, Set<String>> stationLines;

  /// กราฟเชื่อมต่อ (สถานี -> เพื่อนบ้าน)
  late final Map<String, List<String>> graph;

  /// สถานีที่ใช้เปลี่ยนสาย
  final Set<String> interchanges = {'Siam', 'Krung Thon Buri'};

  String? start;
  String? end;

  List<String> path = [];
  int stopCount = 0;
  int lineChanges = 0;
  int fare = 0; // THB (ประมาณการ)
  int minutes = 0; // เวลาเดินทางโดยประมาณ

  @override
  void initState() {
    super.initState();
    // สร้าง mapping สายของแต่ละสถานี
    stationLines = {};
    void addLine(List<String> lineStations, String lineName) {
      for (final s in lineStations) {
        stationLines.putIfAbsent(s, () => <String>{});
        stationLines[s]!.add(lineName);
      }
    }

    addLine(sukhumvit, 'Sukhumvit');
    addLine(silom, 'Silom');
    addLine(gold, 'Gold');

    // สร้างกราฟเชื่อมต่อ (ต่อกันแบบข้างเคียง)
    graph = {};
    void addEdge(List<String> lineStations) {
      for (int i = 0; i < lineStations.length; i++) {
        final u = lineStations[i];
        graph.putIfAbsent(u, () => []);
        if (i > 0) {
          final v = lineStations[i - 1];
          graph[u]!.add(v);
        }
        if (i < lineStations.length - 1) {
          final v = lineStations[i + 1];
          graph[u]!.add(v);
        }
      }
    }

    addEdge(sukhumvit);
    addEdge(silom);
    addEdge(gold);

    // รวมรายชื่อสถานีทั้งหมด
    // (สำหรับ dropdown ให้เรียงตามตัวอักษรเพื่อหาได้ง่าย)
  }

  List<String> get allStations {
    final set = <String>{
      ...sukhumvit,
      ...silom,
      ...gold,
    };
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // ----------------------------- อัลกอริทึมหาเส้นทาง -----------------------------

  /// หาเส้นทางสั้นที่สุดด้วย BFS (นับจำนวนสถานี)
  List<String> shortestPath(String src, String dst) {
    if (src == dst) return [src];
    final queue = <String>[src];
    final visited = <String>{src};
    final parent = <String, String>{};

    int qIndex = 0;
    while (qIndex < queue.length) {
      final u = queue[qIndex++];
      for (final v in graph[u] ?? const []) {
        if (visited.contains(v)) continue;
        visited.add(v);
        parent[v] = u;
        if (v == dst) {
          // สร้าง path ย้อนกลับ
          final path = <String>[];
          String cur = dst;
          while (true) {
            path.add(cur);
            if (cur == src) break;
            cur = parent[cur]!;
          }
          return path.reversed.toList();
        }
        queue.add(v);
      }
    }
    return []; // ไม่เจอเส้นทาง
  }

  /// ประมาณค่าโดยสารจากจำนวนสถานี (นโยบายค่าโดยสารจริงอาจเปลี่ยนแปลงได้)
  /// สูตรเดโม: เริ่มต้น 17 บาท + 3 บาท/สถานี (ไม่นับสถานีต้น), เพดาน 65 บาท, ขั้นต่ำ 17
  int estimateFare(int stations) {
    if (stations <= 1) return 17;
    final cost = 17 + (stations - 1) * 3;
    return cost.clamp(17, 65);
  }

  /// ประมาณเวลา: 2.5 นาที/สถานี + 5 นาที/ครั้งที่เปลี่ยนสาย
  int estimateMinutes(int stations, int changes) {
    final ride = (stations - 1) * 2.5; // เวลาวิ่ง
    final transfer = changes * 5.0; // เดินเปลี่ยนชานชาลา
    return (ride + transfer).round();
  }

  /// คำนวณจำนวนครั้งเปลี่ยนสายบน path ที่ได้
  int countLineChangesOnPath(List<String> p) {
    if (p.length <= 1) return 0;
    // ถ้าสถานีมีหลายสาย เราจะนับเป็นการเปลี่ยนก็ต่อเมื่อ "ก่อน-หลัง" อยู่กันคนละสาย
    // และสถานีนั้นเป็น interchange
    int changes = 0;

    // พยายามกำหนดสายที่ "สอดคล้อง" กันมากที่สุด
    // วิธีง่าย: เดินตาม path แล้วเลือกสายที่สถานีทั้งคู่มีร่วมกันก่อน
    String? currentLine;

    for (int i = 0; i < p.length - 1; i++) {
      final a = p[i];
      final b = p[i + 1];
      final linesA = stationLines[a] ?? {};
      final linesB = stationLines[b] ?? {};
      final common = linesA.intersection(linesB);

      String stepLine;
      if (common.isNotEmpty) {
        // เลือกสายร่วม (ถ้ามี currentLine และอยู่ใน common ให้คงสายเดิม)
        if (currentLine != null && common.contains(currentLine)) {
          stepLine = currentLine;
        } else {
          stepLine = common.first;
        }
      } else {
        // เผื่อกรณีไม่มีสายร่วม (แทบไม่เกิดใน BTS หลัก ๆ)
        stepLine = (linesB.isNotEmpty ? linesB.first : (linesA.isNotEmpty ? linesA.first : ''));
      }

      if (currentLine == null) {
        currentLine = stepLine;
      } else if (stepLine != currentLine) {
        // นับเปลี่ยนสายเมื่ออยู่ที่สถานี interchange
        if (interchanges.contains(a) || interchanges.contains(b)) {
          changes++;
          currentLine = stepLine;
        } else {
          // ไม่ใช่จุดเปลี่ยนสายทางการ แต่อัลกอริทึมจำใจเปลี่ยน (กันพลาด)
          currentLine = stepLine;
        }
      }
    }
    return changes;
  }

  void calculate() {
    if (start == null || end == null) {
      _showSnack('กรุณาเลือกสถานีต้นทางและปลายทาง');
      return;
    }
    if (start == end) {
      setState(() {
        path = [start!];
        stopCount = 1;
        lineChanges = 0;
        fare = estimateFare(stopCount);
        minutes = estimateMinutes(stopCount, lineChanges);
      });
      return;
    }

    final p = shortestPath(start!, end!);
    if (p.isEmpty) {
      _showSnack('ไม่พบเส้นทางระหว่าง $start และ $end');
      return;
    }
    final changes = countLineChangesOnPath(p);
    final stations = p.length;

    setState(() {
      path = p;
      stopCount = stations;
      lineChanges = changes;
      fare = estimateFare(stations);
      minutes = estimateMinutes(stations, changes);
    });
  }

  void swapStations() {
    if (start == null && end == null) return;
    setState(() {
      final tmp = start;
      start = end;
      end = tmp;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ----------------------------- UI -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('MAP Navigator')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StationDropdown(
                                  label: 'สถานีต้นทาง',
                                  value: start,
                                  items: allStations,
                                  onChanged: (v) => setState(() => start = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'สลับ',
                                onPressed: swapStations,
                                icon: const Icon(Icons.compare_arrows),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StationDropdown(
                                  label: 'สถานีปลายทาง',
                                  value: end,
                                  items: allStations,
                                  onChanged: (v) => setState(() => end = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: calculate,
                                  icon: const Icon(Icons.train),
                                  label: const Text('คำนวณเส้นทาง'),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                                onPressed: () {
                                  setState(() {
                                    start = null;
                                    end = null;
                                    path = [];
                                    stopCount = 0;
                                    lineChanges = 0;
                                    fare = 0;
                                    minutes = 0;
                                  });
                                },
                                child: const Text('ล้างข้อมูล'),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    tooltip: 'ดูแผนที่',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: SizedBox(
                            width: 400,
                            child: Image.asset(
                              'assets/images/map.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('ปิด'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                  ),
                  if (path.isNotEmpty) _ResultCard(
                    path: path,
                    stopCount: stopCount,
                    lineChanges: lineChanges,
                    fare: fare,
                    minutes: minutes,
                    stationLines: stationLines,
                    interchanges: interchanges,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StationDropdown extends StatelessWidget {
  const _StationDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items
          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.path,
    required this.stopCount,
    required this.lineChanges,
    required this.fare,
    required this.minutes,
    required this.stationLines,
    required this.interchanges,
  });

  final List<String> path;
  final int stopCount;
  final int lineChanges;
  final int fare;
  final int minutes;
  final Map<String, Set<String>> stationLines;
  final Set<String> interchanges;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ผลการคำนวณ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Chip(icon: Icons.route, label: 'จำนวนสถานี', value: '$stopCount'),
                _Chip(icon: Icons.swap_calls, label: 'เปลี่ยนสาย', value: '$lineChanges ครั้ง'),
                _Chip(icon: Icons.schedule, label: 'เวลาโดยประมาณ', value: '$minutes นาที'),
                _Chip(icon: Icons.payments, label: 'ค่าโดยสาร (ประมาณ)', value: '$fare บาท'),
              ],
            ),
            const Divider(height: 24),
            Text('เส้นทาง', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _PathList(
              path: path,
              stationLines: stationLines,
              interchanges: interchanges,
            ),
            const SizedBox(height: 8),
            Text(
              'หมายเหตุ: ค่าโดยสารและเวลาเป็นการประมาณเพื่อการศึกษา—อัตราจริงอาจเปลี่ยนแปลงตามนโยบายผู้ให้บริการ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ]),
    );
  }
}

class _PathList extends StatelessWidget {
  const _PathList({
    required this.path,
    required this.stationLines,
    required this.interchanges,
  });

  final List<String> path;
  final Map<String, Set<String>> stationLines;
  final Set<String> interchanges;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(path.length, (i) {
        final s = path[i];
        final isInterchange = interchanges.contains(s);
        final lines = stationLines[s]?.join(' / ') ?? '-';
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: isInterchange ? cs.primary : cs.secondaryContainer,
            child: Text('${i + 1}', style: TextStyle(color: isInterchange ? cs.onPrimary : cs.onSecondaryContainer, fontSize: 12)),
          ),
          title: Text(s),
          subtitle: Text('สาย: $lines'),
          trailing: isInterchange
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.change_circle, size: 18),
                    SizedBox(width: 6),
                    Text('จุดเปลี่ยนสาย'),
                  ],
                )
              : null,
        );
      }),
    );
  }
}
