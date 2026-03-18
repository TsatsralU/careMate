import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database/intake_repository.dart';
import 'database/models.dart';
import 'services/beacon_service.dart';
import 'screens/medication_list_screen.dart';

// ── 서버 주소 설정 ──
const String serverUrl = 'https://ornamented-jeramy-achromatically.ngrok-free.dev';
const String userId = 'user_001';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 비콘 서비스 초기화 (권한 요청 + 알림 설정)
  await BeaconService().initialize();
  runApp(const MaterialApp(
    home: PlantCareApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class PlantCareApp extends StatefulWidget {
  const PlantCareApp({super.key});

  @override
  State<PlantCareApp> createState() => _PlantCareAppState();
}

class _PlantCareAppState extends State<PlantCareApp> {
  int _currentIndex = 0;

  // ★ 기존 HistoryScreen → MedicationListScreen 으로 교체
  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const MedicationListScreen(), // ← 여기만 바뀐 거예요!
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
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), label: '대화하기'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: '복약 기록'),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────
// 홈 화면 (기존 그대로)
// ────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IntakeRepository _repo = IntakeRepository();
  int plantLevel = 1;
  int todayMedicine = 0;
  int totalMedicine = 0;
  int consecutiveDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tree = await _repo.getTreeState();
    final today = await _repo.getTodayIntakeCount();
    final total = await _repo.getTotalIntakeCount();
    if (tree != null) {
      setState(() {
        plantLevel = tree.growthLevel;
        consecutiveDays = tree.consecutiveDays;
      });
    }
    setState(() {
      todayMedicine = today;
      totalMedicine = total;
    });
  }

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
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  const Text('🌱 나의 건강나무',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(_getPlantEmoji(plantLevel),
                      style: const TextStyle(fontSize: 120)),
                  const SizedBox(height: 10),
                  Text('Lv. $plantLevel',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: (totalMedicine % 10) / 10,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  Text('다음 레벨까지 ${10 - (totalMedicine % 10)}번 남았어요!',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_today, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    const Text('오늘의 복약 현황',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusCard(
                          '오늘 복약', '$todayMedicine회', Icons.medication, Colors.blue),
                      _buildStatusCard(
                          '총 복약', '$totalMedicine회', Icons.favorite, Colors.red),
                      _buildStatusCard('연속 일수', '$consecutiveDays일',
                          Icons.local_fire_department, Colors.orange),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle, size: 24),
                    SizedBox(width: 10),
                    Text('약 먹었어요!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
          TextField(
              decoration: InputDecoration(
                  hintText: '예) 혈압약, 소화제',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                todayMedicine++;
                totalMedicine++;
                if (totalMedicine % 10 == 0) plantLevel = (plantLevel % 5) + 1;
              });
              Navigator.pop(context);
              _showGrowthAnimation();
              _repo
                  .recordIntake(
                    detectionMethod: DetectionMethod.manual,
                    note: '버튼으로 기록',
                  )
                  .then((_) => _loadData());
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
          const Text('식물이 쑥쑥 자라고 있어요!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('건강 관리 잘하고 계세요!',
              style: TextStyle(color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인'))
        ],
      ),
    );
  }
}

// ────────────────────────────────────────
// 챗봇 화면 (기존 그대로)
// ────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final IntakeRepository _repo = IntakeRepository();
  bool _speechEnabled = false;
  String _wordsSpoken = "마이크 버튼을 눌러 말씀해주세요";
  List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _isLoading = false;
  bool _showTextInput = false;
  final TextEditingController _textController = TextEditingController();
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

      if (_wordsSpoken.isNotEmpty &&
          _wordsSpoken != "마이크 버튼을 눌러 말씀해주세요") {
        await _sendMessage(_wordsSpoken);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isRecording = true;
        _wordsSpoken = "";
      });
      await _speechToText.listen(
        onResult: (result) =>
            setState(() => _wordsSpoken = result.recognizedWords),
        localeId: "ko_KR",
        listenMode: ListenMode.confirmation,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages
          .add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _wordsSpoken = "마이크 버튼을 눌러 말씀해주세요";
    });

    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/chat'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'ngrok-skip-browser-warning': 'true'
            },
            body: jsonEncode({'user_id': userId, 'message': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add(
              ChatMessage(text: data['reply'], isUser: false, time: DateTime.now()));
        });
        if (_isMedicineTaken(text)) {
          await _repo.recordIntake(
            detectionMethod: DetectionMethod.voice,
            note: text,
          );
        }
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

  bool _isMedicineTaken(String text) {
    final keywords = ['약 먹었', '약먹었', '복용했', '먹었어', '먹었습니다', '챙겨먹었', '약 챙겼'];
    return keywords.any((keyword) => text.contains(keyword));
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
                final msg = _messages[_messages.length -
                    1 -
                    (index - (_isLoading ? 1 : 0))];
                return _buildChatBubble(msg);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isRecording
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: 3),
                  ),
                  child: Row(children: [
                    _isRecording
                        ? AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) => Icon(
                                Icons.graphic_eq,
                                color: Colors.red,
                                size: 24 + (_animationController.value * 8)),
                          )
                        : Icon(Icons.mic_none,
                            color: Colors.grey.shade600, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRecording
                                  ? "🎤 듣고 있어요..."
                                  : (_isLoading ? "새싹이가 생각 중..." : "준비 완료"),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _wordsSpoken.isEmpty
                                  ? "마이크 버튼을 눌러 말씀해주세요"
                                  : _wordsSpoken,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
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
                                : [
                                    Colors.green.shade400,
                                    Colors.green.shade700
                                  ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.green)
                              .withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: _isRecording ? 15 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLoading
                          ? Icons.hourglass_empty
                          : (_isRecording ? Icons.stop : Icons.mic),
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isLoading
                        ? '🌱 새싹이가 답변 중...'
                        : (_isRecording
                            ? '🛑 버튼을 다시 눌러 녹음 종료'
                            : '🎤 버튼을 눌러 녹음 시작'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isRecording
                            ? Colors.red.shade700
                            : Colors.green.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showTextInput = !_showTextInput),
                  icon: Icon(
                      _showTextInput ? Icons.mic : Icons.keyboard,
                      color: Colors.green),
                  label: Text(
                    _showTextInput ? '음성으로 전환' : '타이핑으로 전환',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                if (_showTextInput)
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: '메시지를 입력하세요...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage(text.trim());
                            _textController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              final text = _textController.text.trim();
                              if (text.isNotEmpty) {
                                _sendMessage(text);
                                _textController.clear();
                              }
                            },
                      icon: const Icon(Icons.send,
                          color: Colors.green, size: 30),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(message.text,
            style: TextStyle(
                fontSize: 16,
                color: message.isUser ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: const Text('새싹이가 생각 중... 🌱',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage(
      {required this.text, required this.isUser, required this.time});
}
