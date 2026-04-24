import 'package:flutter/material.dart';
import 'mrtbook.dart';
import 'dart:ui';

class Mrt extends StatefulWidget {
  const Mrt({super.key});

  @override
  State<Mrt> createState() => _MrtState();
}

class _MrtState extends State<Mrt> {
  // ✅ แยกเลือกสายเป็นต้นทาง/ปลายทาง
  String selectedLineStart = 'เลือกสาย';
  String selectedLineEnd = 'เลือกสาย';

  List<String> get allLines => ['เลือกสาย', 'สายสีม่วง', 'สายสีน้ำเงิน'];

  Color? lineColor(String line) {
    switch (line) {
      case 'สายสีม่วง':
        return const Color.fromARGB(255, 105, 12, 129);
      case 'สายสีน้ำเงิน':
        return const Color.fromARGB(255, 24, 35, 130);
      default:
        return null;
    }
  }

  // ✅ dropdown ของสถานีต้นทาง/ปลายทาง กรองตามสายที่เลือก
  List<String> get filteredStationsStart {
    if (selectedLineStart == 'เลือกสาย') return allStations;
    if (selectedLineStart == 'สายสีม่วง') return purple;
    if (selectedLineStart == 'สายสีน้ำเงิน') return blue;
    return allStations;
  }

  List<String> get filteredStationsEnd {
    if (selectedLineEnd == 'เลือกสาย') return allStations;
    if (selectedLineEnd == 'สายสีม่วง') return purple;
    if (selectedLineEnd == 'สายสีน้ำเงิน') return blue;
    return allStations;
  }

  final List<String> purple = [
    'เตาปูน', // interchange
    'บางซ่อน',
    'วงศ์สว่าง',
    'แยกติวานนท์',
    'กระทรวงสาธารณสุข',
    'ศูนย์ราชการนนทบุรี', // interchange
    'บางกระสอ',
    'แยกนนทบุรี 1',
    'สะพานพระนั่งเกล้า',
    'ไทรม้า',
    'บางรักน้อยท่าอิฐ',
    'บางรักใหญ่',
    'บางพลู',
    'สามแยกบางใหญ่',
    'ตลาดบางใหญ่',
    'คลองบางไผ่',
  ];

  final List<String> blue = [
    'หลักสอง',
    'บางแค',
    'ภาษีเจริญ',
    'เพชรเกษม 48',
    'บางหว้า', // interchange
    'บางไผ่',
    'ท่าพระ',
    'อิสรภาพ',
    'ท่าเรือราชินี',
    'สนามไชย',
    'สามยอด',
    'วัดมังกร',
    'หัวลำโพง',
    'สามย่าน',
    'สีลม', // interchange
    'ลุมพินี',
    'คลองเตย',
    'ศูนย์การประชุมแห่งชาติสิริกิติ์',
    'สุขุมวิท', // interchange
    'เพชรบุรี',
    'พระราม 9',
    'ศูนย์วัฒนธรรมแห่งประเทศไทย',
    'ห้วยขวาง',
    'สุทธิสาร',
    'รัชดาภิเษก',
    'ลาดพร้าว', // interchange
    'พหลโยธิน', // interchange
    'สวนจตุจักร',
    'กำแพงเพชร',
    'บางซื่อ',
    'เตาปูน', // interchange
    'บางโพ',
    'บางอ้อ',
    'บางพลัด',
    'สิรินธร',
    'บางยี่ขัน',
    'บางขุนนนท์',
    'ไฟฉาย',
    'จรัญสนิทวงศ์ 13',
  ];

  late final Map<String, Set<String>> stationLines;
  late final Map<String, List<String>> graph;

  final Set<String> interchanges = {
    'เตาปูน',
    'ศูนย์ราชการนนทบุรี',
    'บางหว้า',
    'สีลม',
    'สุขุมวิท',
    'ลาดพร้าว',
    'พหลโยธิน',
  };

  String? start;
  String? end;

  List<String> path = [];
  int stopCount = 0;
  int lineChanges = 0;
  int fare = 0;
  int minutes = 0;
  int ticketCount = 1;
  final TextEditingController ticketController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();

    // mapping สายของแต่ละสถานี
    stationLines = {};
    void addLine(List<String> lineStations, String lineName) {
      for (final s in lineStations) {
        stationLines.putIfAbsent(s, () => <String>{});
        stationLines[s]!.add(lineName);
      }
    }

    addLine(purple, 'สายสีม่วง');
    addLine(blue, 'สายสีน้ำเงิน');

    // กราฟเชื่อมต่อ
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

    addEdge(purple);
    addEdge(blue);
  }

  List<String> get allStations {
    final set = <String>{...purple, ...blue};
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

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
    return [];
  }

  int estimateFare(int stations) {
    int price;
    if (stations == 0)
      price = 17;
    else if (stations >= 1 && stations <= 2)
      price = 21;
    else if (stations >= 3 && stations <= 5)
      price = 28;
    else if (stations >= 6 && stations <= 9)
      price = 37;
    else if (stations >= 10)
      price = 42;
    else
      price = 17;
    return price * ticketCount;
  }

  /// 2.5 นาที/สถานี + 5 นาที/ครั้งที่เปลี่ยนสาย
  int estimateMinutes(int stations, int changes) {
    final ride = (stations - 1) * 2.5;
    final transfer = changes * 5.0;
    return (ride + transfer).round();
  }

  int countLineChangesOnPath(List<String> p) {
    if (p.length <= 1) return 0;
    int changes = 0;
    String? currentLine;

    for (int i = 0; i < p.length - 1; i++) {
      final a = p[i];
      final b = p[i + 1];
      final linesA = stationLines[a] ?? {};
      final linesB = stationLines[b] ?? {};
      final common = linesA.intersection(linesB);

      String stepLine;
      if (common.isNotEmpty) {
        if (currentLine != null && common.contains(currentLine)) {
          stepLine = currentLine;
        } else {
          stepLine = common.first;
        }
      } else {
        stepLine = (linesB.isNotEmpty ? linesB.first : (linesA.isNotEmpty ? linesA.first : ''));
      }

      if (currentLine == null) {
        currentLine = stepLine;
      } else if (stepLine != currentLine) {
        if (interchanges.contains(a) || interchanges.contains(b)) {
          changes++;
          currentLine = stepLine;
        } else {
          currentLine = stepLine;
        }
      }
    }
    return changes;
  }

  void calculate() {
    if (start == null || end == null) {
      _showDialog('กรุณาเลือกสถานีต้นทางและปลายทาง');
      return;
    }
    if (start == end) {
      _showDialog('กรุณาเลือกสถานีต้นทางและปลายทางที่ต่างกัน');
      return;
    }

    final p = shortestPath(start!, end!);
    if (p.isEmpty) {
      _showDialog('ไม่พบเส้นทางระหว่าง $start และ $end');
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
      final tmpS = start;
      start = end;
      end = tmpS;

      // ✅ สลับสายด้วย
      final tmpLine = selectedLineStart;
      selectedLineStart = selectedLineEnd;
      selectedLineEnd = tmpLine;

      // ถ้าสถานีไม่อยู่ในรายการของสายใหม่ ให้เคลียร์
      if (!filteredStationsStart.contains(start)) start = null;
      if (!filteredStationsEnd.contains(end)) end = null;
    });
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แจ้งเตือน'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ตกลง')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: const Text(
            'MRT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(1, 2))],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Colors.white),
            tooltip: 'โปรไฟล์',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFF9E79F), Color(0xFFFFC300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IconButton(
                icon: const Icon(Icons.confirmation_num, size: 28, color: Color.fromARGB(255, 125, 130, 45)),
                tooltip: 'จองตั๋ว',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MrtBooking()));
                },
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 161, 13, 13), Color.fromARGB(255, 133, 18, 18), Color.fromARGB(255, 71, 11, 11)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/mrtbg.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: Container(color: Colors.black.withOpacity(0))),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset('assets/images/icons.png', height: 120, fit: BoxFit.contain),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'คำนวณเส้นทางรถไฟฟ้า MRT',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 161, 13, 13),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              // ✅ เลือกสาย (ต้นทาง)
                              DropdownButtonFormField<String>(
                                value: selectedLineStart,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'เลือกสาย (ต้นทาง)',
                                  prefixIcon: const Icon(Icons.subway),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: allLines
                                    .map((line) => DropdownMenuItem(
                                          value: line,
                                          child: Row(children: [
                                            if (line != 'เลือกสาย')
                                              Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration:
                                                    BoxDecoration(color: lineColor(line), borderRadius: BorderRadius.circular(4)),
                                              ),
                                            Text(line),
                                          ]),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedLineStart = v ?? 'เลือกสาย';
                                    if (!filteredStationsStart.contains(start)) start = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              _StationDropdown(
                                label: 'สถานีต้นทาง',
                                value: start,
                                items: filteredStationsStart,
                                onChanged: (v) => setState(() => start = v),
                              ),
                              const SizedBox(height: 12),

                              IconButton.filledTonal(
                                onPressed: swapStations,
                                icon: const Icon(Icons.compare_arrows),
                                tooltip: "สลับสถานี",
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 176, 13, 13),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ✅ เลือกสาย (ปลายทาง)
                              DropdownButtonFormField<String>(
                                value: selectedLineEnd,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'เลือกสาย (ปลายทาง)',
                                  prefixIcon: const Icon(Icons.subway_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: allLines
                                    .map((line) => DropdownMenuItem(
                                          value: line,
                                          child: Row(children: [
                                            if (line != 'เลือกสาย')
                                              Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration:
                                                    BoxDecoration(color: lineColor(line), borderRadius: BorderRadius.circular(4)),
                                              ),
                                            Text(line),
                                          ]),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedLineEnd = v ?? 'เลือกสาย';
                                    if (!filteredStationsEnd.contains(end)) end = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              _StationDropdown(
                                label: 'สถานีปลายทาง',
                                value: end,
                                items: filteredStationsEnd,
                                onChanged: (v) => setState(() => end = v),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: ticketController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'จำนวนตั๋ว',
                                  prefixIcon: const Icon(Icons.confirmation_num),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  setState(() {
                                    ticketCount = (val != null && val > 0) ? val : 1;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: calculate,
                                  icon: const Icon(Icons.route),
                                  label: const Text("คำนวณเส้นทาง"),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 176, 13, 13),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedLineStart = 'เลือกสาย';
                                    selectedLineEnd = 'เลือกสาย';
                                    start = null;
                                    end = null;
                                    path = [];
                                    stopCount = 0;
                                    lineChanges = 0;
                                    fare = 0;
                                    minutes = 0;
                                    ticketCount = 1;
                                    ticketController.text = '1';
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('ล้างข้อมูล'),
                              ),
                              const Divider(height: 28),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      IconButton.filled(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 16,
                              backgroundColor: Colors.white,
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: Offset(0, 8))],
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE3F2FD), Color(0xFFF9E79F), Color(0xFFFFFDE7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("แผนที่และเส้นทาง",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0D47A1))),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: 400,
                                      height: 400,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 2,
                                          maxScale: 6,
                                          child: Image.asset('assets/images/map.jpg', fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 176, 13, 13),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('ปิด', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map),
                        tooltip: "ดูแผนที่",
                        style: IconButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 176, 13, 13),
                          foregroundColor: Colors.white,
                        ),
                      ),

                      if (path.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _ResultCard(
                          path: path,
                          stopCount: stopCount,
                          lineChanges: lineChanges,
                          fare: fare,
                          minutes: minutes,
                          ticketCount: ticketCount,
                          stationLines: stationLines,
                          interchanges: interchanges,
                        ),
                      ],
                    ],
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
        prefixIcon: const Icon(Icons.place),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
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
    required this.ticketCount,
    required this.stationLines,
    required this.interchanges,
  });

  final List<String> path;
  final int stopCount;
  final int lineChanges;
  final int fare;
  final int minutes;
  final int ticketCount;
  final Map<String, Set<String>> stationLines;
  final Set<String> interchanges;

  @override
  Widget build(BuildContext context) {
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
                _Chip(icon: Icons.confirmation_num, label: 'จำนวนตั๋ว', value: '$ticketCount ใบ'),
              ],
            ),
            const Divider(height: 24),
            Text('เส้นทาง', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _PathList(path: path, stationLines: stationLines, interchanges: interchanges),
            const SizedBox(height: 8),
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
      decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
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

    // index -> ชื่อสายใหม่ ที่ต้องเปลี่ยนไปขึ้นต่อ (mark ที่สถานีเดิมก่อนเปลี่ยน)
    final changeStartIndexToLine = <int, String>{};
    String? currentLine;

    String _resolveStepLine(String a, String b, {String? prefer}) {
      final linesA = stationLines[a] ?? {};
      final linesB = stationLines[b] ?? {};
      final common = linesA.intersection(linesB);
      if (common.isNotEmpty) {
        if (prefer != null && common.contains(prefer)) return prefer;
        return common.first;
      }
      if (linesB.isNotEmpty) return linesB.first;
      if (linesA.isNotEmpty) return linesA.first;
      return '';
    }

    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final stepLine = _resolveStepLine(a, b, prefer: currentLine);

      if (currentLine == null) {
        currentLine = stepLine; // ตั้งสายเริ่มต้น
        continue;
      }
      if (stepLine != currentLine) {
        // เปลี่ยนสายเกิดขึ้นที่สถานี a (index i)
        changeStartIndexToLine[i] = stepLine.isEmpty ? '-' : stepLine;
        currentLine = stepLine;
      }
    }

    return Column(
      children: List.generate(path.length, (i) {
        final s = path[i];
        final lines = stationLines[s]?.join(' / ') ?? '-';
        final isChangeStart = changeStartIndexToLine.containsKey(i);

        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: isChangeStart ? cs.primary : cs.secondaryContainer,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: isChangeStart ? cs.onPrimary : cs.onSecondaryContainer,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(s),
          subtitle: Text('สาย: $lines'),
          trailing: isChangeStart
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.change_circle, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'จุดเปลี่ยนสาย\n(ไปขึ้น: ${changeStartIndexToLine[i]})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : null,
        );
      }),
    );
  }
}

