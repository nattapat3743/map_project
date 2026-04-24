import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:map_project/receipt_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool booked = false;

  // ✅ แยกเลือกสายเป็นต้นทาง/ปลายทาง
  String selectedLineStart = 'เลือกสาย';
  String selectedLineEnd = 'เลือกสาย';

  String? start;
  String? end;
  List<String> path = [];
  int stopCount = 0;
  int lineChanges = 0;
  int fare = 0;
  int minutes = 0;
  int ticketCount = 1;
  final TextEditingController ticketController = TextEditingController(text: '1');

  final List<String> sukhumvit = [
    'คูคต','แยก คปอ.','พิพิธภัณฑ์กองทัพอากาศ','โรงพยาบาลภูมิพลอดุลยเดช','สะพานใหม่','สายหยุด','พหลโยธิน 59',
    'วัดพระศรีมหาธาตุ','กรมทหารารบที่ 11','บางบัว','กรมป่าไม้','มหาวิทยลัยเกษตรศาสตร์','เสนานิคม','รัชโยธิน',
    'พหลโยธิน 24','ห้าแยกลาดพร้าว','หมอชิต','สะพานควาย','อารีย์','สนามเป้า','อนุสาวรีย์ชัยสมรภูมิ','พญาไท',
    'ราชเทวี','สยาม','ชิดลม','เพลินจิต','นานา','อโศก','พร้อมพงษ์','ทองหล่อ','เอกมัย','พระโขนง','อ่อนนุช','บางจาก',
    'ปุณณวิถี','อุดมสุข','บางนา','แบริ่ง','สำโรง','ปู่เจ้า','ช้างเอราวัณ','โรงเรียนนายเรือ','ปากน้ำ','ศรีนครินทร์',
    'แพรกษา','สายลวด','เคหะฯ',
  ];
  final List<String> silom = [
    'บางหว้า','วุฒากาศ','ตลาดพลู','โพธิ์นิมิตร','วงเวียนใหญ่','กรุงธนบุรี','สะพานตากสิน','สุรศักดิ์','เซนต์หลุยส์',
    'ช่องนนทรี','ศาลาแดง','ราชดำริ','สยาม','สนามกีฬาแห่งชาติ',
  ];
  final List<String> gold = ['กรุงธนบุรี','เจริญนคร','คลองสาน'];
  final List<String> pink = [
    'มีนบุรี','ตลาดมีนบุรี','เศรษฐบุตรบำเพ็ญ','บางชัน','นพรัตน์','วงแหวนรามอินทรา','รามอินทรา กม.9','คู้บอน',
    'รามอินทรา กม.6','วัชรพล','มัยลาภ','รามอินทรา กม.4','ลาดปลาเค้า','รามอินทรา 3','วัดพระศรีมหาธาตุ','ราชภัฏพระนคร',
    'หลักสี่','โทรคมนาคมแห่งชาติ','ศูนย์ราชการเฉลิมพระเกียรติ','แจ้งวัฒนะ','เมืองทองธานี','ศรีรัช','แจ้งวัฒนะ-ปากเกร็ด 28',
    'เลี่ยงเมืองปากเกร็ด','แยกปากเกร็ด','กรมชลประทาน','สามัคคี','สนามบินน้ำ','แคราย','ศูนย์ราชการนนทบุรี',
  ];
  final List<String> yellow = [
    'ลาดพร้าว','ภาวนา','โชคชัย 4','ลาดพร้าว 71','ลาดพร้าว 83','มหาดไทย','ลาดพร้าว 101','บางกะปิ','แยกลำสาลี',
    'ศรีกรีฑา','หัวหมาก','กลันตัน','ศรีนุช','ศรีนครินทร์ 38','สวนหลวง ร.9','ศรีอุดม','ศรีเอี่ยม','ศรีลาซาล',
    'ศรีแบริ่ง','ศรีด่าน','ศรีเทพา','ทิพวัล','สำโรง',
  ];

  late final Map<String, Set<String>> stationLines;
  late final Map<String, List<String>> graph;

  final Set<String> interchanges = {
    'สยาม','กรุงธนบุรี','วัดพระศรีมหาธาตุ','ห้าแยกลาดพร้าว','สำโรง',
  };

  List<String> get allLines => [
    'เลือกสาย','สายสุขุมวิท','สายสีลม','สายสีทอง','สายสีชมพู','สายสีเหลือง',
  ];

  Color? lineColor(String line) {
    switch (line) {
      case 'สายสุขุมวิท': return const Color.fromARGB(255, 78, 189, 84);
      case 'สายสีลม':   return const Color.fromARGB(255, 59, 123, 104);
      case 'สายสีทอง':  return const Color.fromARGB(255, 192, 168, 51);
      case 'สายสีชมพู': return const Color.fromARGB(255, 232, 84, 108);
      case 'สายสีเหลือง': return const Color.fromARGB(255, 255, 223, 0);
      default: return null;
    }
  }

  List<String> get allStations {
    final set = <String>{...sukhumvit, ...silom, ...gold, ...pink, ...yellow};
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // ✅ ตัวกรองสถานีของ “ต้นทาง/ปลายทาง” แยกกัน
  List<String> get filteredStationsStart {
    switch (selectedLineStart) {
      case 'สายสุขุมวิท': return sukhumvit;
      case 'สายสีลม': return silom;
      case 'สายสีทอง': return gold;
      case 'สายสีชมพู': return pink;
      case 'สายสีเหลือง': return yellow;
      default: return allStations;
    }
  }
  List<String> get filteredStationsEnd {
    switch (selectedLineEnd) {
      case 'สายสุขุมวิท': return sukhumvit;
      case 'สายสีลม': return silom;
      case 'สายสีทอง': return gold;
      case 'สายสีชมพู': return pink;
      case 'สายสีเหลือง': return yellow;
      default: return allStations;
    }
  }

  @override
  void initState() {
    super.initState();
    stationLines = {};
    void addLine(List<String> lineStations, String lineName) {
      for (final s in lineStations) {
        stationLines.putIfAbsent(s, () => <String>{});
        stationLines[s]!.add(lineName);
      }
    }
    addLine(sukhumvit, 'สายสุขุมวิท');
    addLine(silom, 'สายสีลม');
    addLine(gold, 'สายสีทอง');
    addLine(pink, 'สายสีชมพู');
    addLine(yellow, 'สายสีเหลือง');

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
    addEdge(pink);
    addEdge(yellow);
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
    if (stations == 0) price = 17;
    else if (stations >= 1 && stations <= 3) price = 30;
    else if (stations >= 4 && stations <= 7) price = 40;
    else if (stations >= 8) price = 47;
    else price = 17;
    return price * ticketCount;
  }

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
      final tmp = start; start = end; end = tmp;

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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ตกลง'))],
      ),
    );
  }

  void _goToReceipt() {
    final bookingId = 'BTS-${DateTime.now().millisecondsSinceEpoch}';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          startStation: start ?? '-',
          endStation: end ?? '-',
          stopCount: stopCount,
          lineChanges: lineChanges,
          minutes: minutes,
          fare: fare,
          passengerName: 'ผู้โดยสาร',
          paymentMethod: 'PromptPay',
          paymentRef: 'REF-$bookingId',
        ),
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
        title: const Text('BTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.account_circle, size: 30, color: Colors.white), tooltip: 'โปรไฟล์',
            onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color.fromARGB(255, 9, 48, 106), Color.fromARGB(255, 5, 25, 54)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/mrtbg.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: Container(color: Colors.black.withOpacity(0)))),
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
                              Text('จองตั๋ว BTS',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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
                                items: allLines.map((line) => DropdownMenuItem(
                                  value: line,
                                  child: Row(children: [
                                    if (line != 'เลือกสาย')
                                      Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(color: lineColor(line), borderRadius: BorderRadius.circular(4))),
                                    Text(line),
                                  ]),
                                )).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedLineStart = v ?? 'เลือกสาย';
                                    if (!filteredStationsStart.contains(start)) start = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // สถานีต้นทาง
                              DropdownButtonFormField<String>(
                                value: start,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'สถานีต้นทาง',
                                  prefixIcon: const Icon(Icons.place),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: filteredStationsStart.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                                onChanged: (v) => setState(() => start = v),
                              ),
                              const SizedBox(height: 12),

                              IconButton.filledTonal(
                                onPressed: swapStations,
                                icon: const Icon(Icons.compare_arrows),
                                tooltip: "สลับสถานี",
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
                                items: allLines.map((line) => DropdownMenuItem(
                                  value: line,
                                  child: Row(children: [
                                    if (line != 'เลือกสาย')
                                      Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(color: lineColor(line), borderRadius: BorderRadius.circular(4))),
                                    Text(line),
                                  ]),
                                )).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedLineEnd = v ?? 'เลือกสาย';
                                    if (!filteredStationsEnd.contains(end)) end = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // สถานีปลายทาง
                              DropdownButtonFormField<String>(
                                value: end,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'สถานีปลายทาง',
                                  prefixIcon: const Icon(Icons.place),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: filteredStationsEnd.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
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
                                  setState(() => ticketCount = (val != null && val > 0) ? val : 1);
                                },
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.confirmation_num),
                                  label: const Text('จองตั๋ว'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: const Color.fromARGB(255, 176, 13, 13),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    calculate();
                                    if (start != null && end != null && path.isNotEmpty && !booked) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Row(
                                            children: const [
                                              Icon(Icons.qr_code_2, color: Colors.green, size: 32),
                                              SizedBox(width: 12),
                                              Text('ชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 8),
                                              Container(
                                                width: 160, height: 160,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey[400]!, width: 1),
                                                ),
                                                child: Center(
                                                  child: Image.asset('assets/images/qr.jpg', width: 120, height: 120, fit: BoxFit.contain),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text('ยอดชำระ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                              Text('$fare บาท',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.green)),
                                              const SizedBox(height: 8),
                                              Text('โปรดสแกนคิวอาร์โค้ดเพื่อชำระเงิน', style: TextStyle(color: Colors.grey[700])),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                setState(() => booked = true);
                                                if (!mounted) return;
                                                _goToReceipt();
                                              },
                                              child: const Text('ยืนยันการจองตั๋ว'),
                                            ),
                                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
                                          ],
                                        ),
                                      );
                                    }
                                  },
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
                                    booked = false;
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
                      const SizedBox(height: 12),
                      if (path.isNotEmpty)
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
                      const SizedBox(height: 24),
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.path,
    required this.stopCount,
    required this.lineChanges,
    required this.fare,
    required this.minutes,
    required this.stationLines,
    required this.interchanges,
    required this.ticketCount,
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
              spacing: 12, runSpacing: 8, children: [
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18), const SizedBox(width: 8),
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
      currentLine = stepLine;
      continue;
    }

    if (stepLine != currentLine) {
      changeStartIndexToLine[i] = stepLine.isEmpty ? '-' : stepLine;
      currentLine = stepLine;
    }
  }

    return Column(
      children: List.generate(path.length, (i) {
        final s = path[i];
        final lines = stationLines[s]?.join(' / ') ?? '-';
        final isChangeStart = changeStartIndexToLine.containsKey(i);
        // ignore: unused_local_variable
        final isInterchange = interchanges.contains(s);

        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor:
                isChangeStart ? cs.primary : cs.secondaryContainer,
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
                      'จุดเปลี่ยนสาย\n(เริ่มใช้: ${changeStartIndexToLine[i]})',
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
