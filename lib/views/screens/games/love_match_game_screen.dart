import 'package:flutter/material.dart';
import 'package:person_app/theme/app_colors.dart';
import 'dart:math';

// --- DATA MODELS ---
class LoveMatchResult {
  final String normalizedName1;
  final String normalizedName2;
  final List<int> sequenceL;
  final List<List<int>> reductionSteps;
  final List<int> finalDigits;
  final int percentValue;

  LoveMatchResult({
    required this.normalizedName1,
    required this.normalizedName2,
    required this.sequenceL,
    required this.reductionSteps,
    required this.finalDigits,
    required this.percentValue,
  });
}

// --- LOGIC FUNCTIONS ---
String removeVietnameseDiacritics(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str;
}

String normalizeName(String input) {
  var s = removeVietnameseDiacritics(input);
  s = s.toUpperCase();
  s = s.replaceAll(RegExp(r'[^A-Z]'), '');
  return s;
}

List<int> buildMatchSequence(String name1, String name2) {
  List<int> sequence = [];
  List<bool> usedInName1 = List.filled(name1.length, false);
  List<bool> usedInName2 = List.filled(name2.length, false);

  // Lượt 1: Duyệt các chữ thuộc name1
  for (int i = 0; i < name1.length; i++) {
    bool matched = false;
    for (int j = 0; j < name2.length; j++) {
      if (!usedInName2[j] && name1[i] == name2[j]) {
        matched = true;
        usedInName2[j] = true;
        usedInName1[i] = true;
        break;
      }
    }
    sequence.add(matched ? 2 : 1);
  }

  // Lượt 2: Duyệt các chữ CÒN LẠI thuộc name2 tìm trong phần thừa của name1
  for (int j = 0; j < name2.length; j++) {
    if (usedInName2[j]) continue;
    
    bool matched = false;
    for (int i = 0; i < name1.length; i++) {
      if (!usedInName1[i] && name2[j] == name1[i]) {
        matched = true;
        usedInName1[i] = true;
        usedInName2[j] = true;
        break;
      }
    }
    sequence.add(matched ? 2 : 1);
  }

  return sequence;
}

List<int> reduceSequenceOnce(List<int> sequence) {
  if (sequence.length <= 2) return sequence;
  List<int> nextSeq = [];
  int left = 0;
  int right = sequence.length - 1;
  while (left < right) {
    nextSeq.add(sequence[left] + sequence[right]);
    left++;
    right--;
  }
  if (left == right) {
    nextSeq.add(sequence[left]);
  }
  return nextSeq;
}

LoveMatchResult calculateLoveMatch(String rawName1, String rawName2) {
  String n1 = normalizeName(rawName1);
  String n2 = normalizeName(rawName2);
  
  List<int> sequenceL = buildMatchSequence(n1, n2);
  
  List<List<int>> steps = [];
  List<int> current = List.from(sequenceL);
  
  while (current.length > 2) {
    current = reduceSequenceOnce(current);
    steps.add(current);
  }
  
  int percent = 0;
  if (current.isEmpty) {
    percent = 0;
  } else if (current.length == 1) {
    percent = current[0];
  } else {
    percent = int.tryParse(current.join('')) ?? 0;
  }

  return LoveMatchResult(
    normalizedName1: n1,
    normalizedName2: n2,
    sequenceL: sequenceL,
    reductionSteps: steps,
    finalDigits: current,
    percentValue: percent,
  );
}

// --- DASHBOARD WIDGET ---
class LoveMatchDashboardCard extends StatelessWidget {
  const LoveMatchDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.1)),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoveMatchGameTab()));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bói tình duyên', style: TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Nhập 2 cái tên để xem độ hợp nhau', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: AppColors.accentGold, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- GAME SCREEN ---
class LoveMatchGameTab extends StatefulWidget {
  const LoveMatchGameTab({super.key});

  @override
  State<LoveMatchGameTab> createState() => _LoveMatchGameTabState();
}

class _LoveMatchGameTabState extends State<LoveMatchGameTab> {
  final _name1Ctrl = TextEditingController();
  final _name2Ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  LoveMatchResult? _result;
  String? _randomWish;

  final List<String> _highWishes = [
    'Tình duyên chớm nở, Tết này hết ế rồi nha! 🌸',
    'Trời sinh một cặp! Năm mới triển luôn thôi chờ chi! 💖',
    'Nhân duyên trời định, đúng người, đúng thời điểm! 🥰',
    'Tết này trọn vẹn vì hai người sinh ra là dành cho nhau! 🧨',
    'Thiên thời địa lợi nhân hòa, cưới luôn năm nay đẹp! 🎆',
    'Quá hợp, dự là năm nay có bỉm sữa! 💍',
  ];

  final List<String> _midWishes = [
    'Tình trong như đã mặt ngoài còn e, chủ động xíu là đổ! 😏',
    'Trên tình bạn dưới tình yêu một chút, năm mới tiến tới nhé! 🌻',
    'Nhích thêm chút xíu nữa là thành đôi thôi! Cố lên nha! 💪',
    'Hợp nhau sương sương, chỉ cần chân thành là đủ! 🍀',
    'Năm mới mưa dầm thấm lâu, cứ từ từ rồi sẽ thành! 🧧',
  ];

  final List<String> _lowWishes = [
    'Hơi lệch pha xíu, nhưng tình yêu có sức mạnh kỳ diệu mà! 🔮',
    'Không sao, phần trăm thấp thì mình bù đắp bằng tình cảm thật nhé! 🫂',
    'Vạn sự khởi đầu nan, gian nan không nản! Đầu xuân tấn tới đi! 🚀',
    'Số phận nằm trong tay bạn! Hợp hay không do bản thân quyết định! ✨',
    'Chưa hợp lắm, nhưng biết đâu "ghét của nào trời trao của nấy"! 🤪',
    'Năm mới vui vẻ là chính! Người yêu chưa có nhưng tiền phải có nhé! 💸',
  ];

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _result = calculateLoveMatch(_name1Ctrl.text, _name2Ctrl.text);
        
        int percent = _result!.percentValue;
        if (percent >= 80) {
          _randomWish = _highWishes[Random().nextInt(_highWishes.length)];
        } else if (percent >= 50) {
          _randomWish = _midWishes[Random().nextInt(_midWishes.length)];
        } else {
          _randomWish = _lowWishes[Random().nextInt(_lowWishes.length)];
        }
      });
    }
  }

  void _clear() {
    _name1Ctrl.clear();
    _name2Ctrl.clear();
    setState(() {
      _result = null;
      _randomWish = null;
    });
  }

  @override
  void dispose() {
    _name1Ctrl.dispose();
    _name2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bói Tình Duyên', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentGold),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ô nhập tên
              TextFormField(
                controller: _name1Ctrl,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  labelText: 'Tên người thứ nhất',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name2Ctrl,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  labelText: 'Tên người thứ hai',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  prefixIcon: const Icon(Icons.favorite, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 24),
              
              // Nút bấm
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Xem kết quả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _clear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textMain,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
              
              // Kết quả
              if (_result != null) ...[
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                            ],
                            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Text(
                            '${_result!.percentValue}%',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.accentGold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_randomWish != null)
                        Text(
                          _randomWish!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: AppColors.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
