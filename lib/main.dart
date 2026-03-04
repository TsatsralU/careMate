import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

// ── 서버 주소 설정 ──
// 에뮬레이터: http://10.0.2.2:8000
// 실제 기기:  http://본인PC_IP주소:8000  (ipconfig로 확인)
const String serverUrl = 'https://ornamented-jeramy-achromatically.ngrok-free.app';
const String userId = 'user_001';

void main() => runApp(const MaterialApp(
      home: PlantCareApp(),
      debugShowCheckedModeBanner: false,
    ));

class PlantCareApp extends StatefulWidget {
  const PlantCareApp({super.key});

  @override
  State<PlantCareApp> createState() => _PlantCareAppState();
}

class _PlantCareAppState extends State<PlantCareApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: '내 식물'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: '대화하기'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '복약 기록'),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────
// 홈 화면
// ────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int plantLevel = 3;
  int todayMedicine = 2;
  int totalMedicine = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('내 반려 식물'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text('🌱 나의 건강나무', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(_getPlantEmoji(plantLevel), style: const TextStyle(fontSize: 120)),
                  const SizedBox(height: 10),
                  Text('Lv. $plantLevel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: (totalMedicine % 10) / 10,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  Text('다음 레벨까지 ${10 - (totalMedicine % 10)}번 남았어요!', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_today, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    const Text('오늘의 복약 현황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusCard('오늘 복약', '$todayMedicine회', Icons.medication, Colors.blue),
                      _buildStatusCard('총 복약', '$totalMedicine회', Icons.favorite, Colors.red),
                      _buildStatusCard('연속 일수', '7일', Icons.local_fire_department, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showMedicineDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle, size: 24),
                    SizedBox(width: 10),
                    Text('약 먹었어요!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getPlantEmoji(int level) {
    switch (level) {
      case 1: return '🌱';
      case 2: return '🌿';
      case 3: return '🪴';
      case 4: return '🌳';
      case 5: return '🌲';
      default: return '🌱';
    }
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    );
  }

  void _showMedicineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복약 기록하기'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('어떤 약을 드셨나요?'),
          const SizedBox(height: 20),
          TextField(decoration: InputDecoration(hintText: '예) 혈압약, 소화제', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                todayMedicine++;
                totalMedicine++;
                if (totalMedicine % 10 == 0) plantLevel = (plantLevel % 5) + 1;
              });
              Navigator.pop(context);
              _showGrowthAnimation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('기록하기'),
          ),
        ],
      ),
    );
  }

  void _showGrowthAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          const Text('식물이 쑥쑥 자라고 있어요!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('건강 관리 잘하고 계세요!', style: TextStyle(color: Colors.grey.shade600)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }
}

// ────────────────────────────────────────
// 챗봇 화면 - 서버 연동 버전
// ────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "마이크 버튼을 눌러 말씀해주세요";
  List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _isLoading = false; // AI 답변 대기 중
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _messages.add(ChatMessage(
      text: "안녕하세요! 저는 새싹이예요 🌱 오늘 기분은 어떠세요?",
      isUser: false,
      time: DateTime.now(),
    ));
  }

  void _initSpeech() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    }
  }

  void _toggleRecording() async {
    if (!_speechEnabled) return;

    if (_isRecording) {
      HapticFeedback.lightImpact();
      await _speechToText.stop();
      setState(() => _isRecording = false);

      if (_wordsSpoken.isNotEmpty && _wordsSpoken != "마이크 버튼을 눌러 말씀해주세요") {
        await _sendMessage(_wordsSpoken);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isRecording = true;
        _wordsSpoken = "";
      });
      await _speechToText.listen(
        onResult: (result) => setState(() => _wordsSpoken = result.recognizedWords),
        localeId: "ko_KR",
        listenMode: ListenMode.confirmation,
      );
    }
  }

  // ── 핵심: 서버 호출 ──
  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _wordsSpoken = "마이크 버튼을 눌러 말씀해주세요";
    });

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/chat'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'user_id': userId, 'message': text}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add(ChatMessage(text: data['reply'], isUser: false, time: DateTime.now()));
        });
      } else {
        _addErrorMessage();
      }
    } catch (e) {
      _addErrorMessage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: '새싹이가 잠시 자리를 비웠어요. 서버가 켜져 있는지 확인해주세요 🌱',
        isUser: false,
        time: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('🌱 새싹이와 대화하기'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == 0) return _buildLoadingBubble();
                final msg = _messages[_messages.length - 1 - (index - (_isLoading ? 1 : 0))];
                return _buildChatBubble(msg);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isRecording ? Colors.red : Colors.grey.shade300, width: 3),
                  ),
                  child: Row(children: [
                    _isRecording
                        ? AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) => Icon(Icons.graphic_eq, color: Colors.red, size: 24 + (_animationController.value * 8)),
                          )
                        : Icon(Icons.mic_none, color: Colors.grey.shade600, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _isRecording ? "🎤 듣고 있어요..." : (_isLoading ? "새싹이가 생각 중..." : "준비 완료"),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isRecording ? Colors.red : Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _wordsSpoken.isEmpty ? "마이크 버튼을 눌러 말씀해주세요" : _wordsSpoken,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: _isLoading ? null : _toggleRecording,
                  borderRadius: BorderRadius.circular(50),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : _isRecording
                                ? [Colors.red.shade400, Colors.red.shade700]
                                : [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: _isRecording ? 15 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLoading ? Icons.hourglass_empty : (_isRecording ? Icons.stop : Icons.mic),
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isLoading ? '🌱 새싹이가 답변 중...' : (_isRecording ? '🛑 버튼을 다시 눌러 녹음 종료' : '🎤 버튼을 눌러 녹음 시작'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isRecording ? Colors.red.shade700 : Colors.green.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(message.text, style: TextStyle(fontSize: 16, color: message.isUser ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Text('새싹이가 생각 중... 🌱', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _animationController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

// ────────────────────────────────────────
// 복약 기록 화면
// ────────────────────────────────────────
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(title: const Text('복약 기록'), backgroundColor: Colors.green),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.medication, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('혈압약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('2026년 2월 ${12 - index}일', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ]),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ]),
          );
        },
      ),
    );
  }
}