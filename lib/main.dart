import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OceanNotificationService.instance.init();
  runApp(const HanziTestApp());
}


class OceanNotificationService {
  OceanNotificationService._();
  static final OceanNotificationService instance = OceanNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    final iosOk = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final macOk = await mac?.requestPermissions(alert: true, badge: true, sound: true);
    return iosOk ?? macOk ?? true;
  }

  Future<void> scheduleDailyReminder() async {
    await requestPermission();
    await _plugin.cancel(1208);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hanzi_ocean_daily',
        'Ocean daily study',
        channelDescription: 'Nhắc học HSK mỗi ngày',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.periodicallyShow(
      1208,
      '🐳 Sóng biển gọi bạn học HSK!',
      'Làm 5 câu hôm nay để giữ streak nhé 🌊✨',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showCutePreview() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hanzi_ocean_preview',
        'Ocean preview',
        channelDescription: 'Thông báo thử',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _plugin.show(
      1209,
      '🦦 Nhắc học đã bật!',
      'Mỗi ngày mình sẽ nhắc bạn học tiếng Trung thật nhẹ nhàng 💙',
      details,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1208);
  }
}

class HanziTestApp extends StatelessWidget {
  const HanziTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanzi Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0077B6)),
        scaffoldBackgroundColor: const Color(0xFFEAF8FF),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.94),
          indicatorColor: const Color(0xFFCDEFFF),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainShell(),
    );
  }
}

class VocabWord {
  final String id;
  final String level;
  final String hanzi;
  final String pinyin;
  final String meaningVi;

  const VocabWord({required this.id, required this.level, required this.hanzi, required this.pinyin, required this.meaningVi});

  factory VocabWord.fromJson(Map<String, dynamic> json) => VocabWord(
        id: json['id'],
        level: json['level'],
        hanzi: json['hanzi'],
        pinyin: json['pinyin'],
        meaningVi: json['meaning_vi'],
      );
}

class GrammarPoint {
  final String id;
  final String level;
  final String title;
  final String pattern;
  final String meaningVi;
  final String nativeNote;
  final String commonMistake;
  final List<GrammarExample> examples;

  const GrammarPoint({required this.id, required this.level, required this.title, required this.pattern, required this.meaningVi, required this.nativeNote, required this.commonMistake, required this.examples});

  factory GrammarPoint.fromJson(Map<String, dynamic> json) => GrammarPoint(
        id: json['id'],
        level: json['level'],
        title: json['title'],
        pattern: json['pattern'],
        meaningVi: json['meaning_vi'],
        nativeNote: json['native_note'],
        commonMistake: json['common_mistake'],
        examples: (json['examples'] as List).map((e) => GrammarExample.fromJson(e)).toList(),
      );
}

class GrammarExample {
  final String zh;
  final String pinyin;
  final String vi;
  const GrammarExample({required this.zh, required this.pinyin, required this.vi});
  factory GrammarExample.fromJson(Map<String, dynamic> json) => GrammarExample(zh: json['zh'], pinyin: json['pinyin'], vi: json['vi']);
}

class DailySet {
  final int day;
  final List<SentenceTask> tasks;
  const DailySet({required this.day, required this.tasks});
  factory DailySet.fromJson(Map<String, dynamic> json) => DailySet(day: json['day'], tasks: (json['tasks'] as List).map((e) => SentenceTask.fromJson(e)).toList());
}

class SentenceTask {
  final String id;
  final String level;
  final String topic;
  final String viSentence;
  final String answerZh;
  final List<String> answerTokens;
  final List<String> options;
  final String grammarFocus;
  final String timeFocus;

  const SentenceTask({required this.id, required this.level, required this.topic, required this.viSentence, required this.answerZh, required this.answerTokens, required this.options, required this.grammarFocus, required this.timeFocus});

  factory SentenceTask.fromJson(Map<String, dynamic> json) => SentenceTask(
        id: json['id'],
        level: json['level'],
        topic: json['topic'],
        viSentence: json['vi_sentence'],
        answerZh: json['answer_zh'],
        answerTokens: (json['answer_tokens'] as List).map((e) => e.toString()).toList(),
        options: (json['options'] as List).map((e) => e.toString()).toList(),
        grammarFocus: json['grammar_focus'],
        timeFocus: json['time_focus'],
      );
}

class AppData {
  final List<VocabWord> words;
  final List<GrammarPoint> grammar;
  final List<DailySet> dailySets;
  const AppData({required this.words, required this.grammar, required this.dailySets});
}

Future<AppData> loadData() async {
  final vocabRaw = await rootBundle.loadString('assets/data/hsk_vocab.json');
  final grammarRaw = await rootBundle.loadString('assets/data/grammar_hsk1_hsk2.json');
  final dailyRaw = await rootBundle.loadString('assets/data/daily_sentence_sets.json');
  return AppData(
    words: (jsonDecode(vocabRaw) as List).map((e) => VocabWord.fromJson(e)).toList(),
    grammar: (jsonDecode(grammarRaw) as List).map((e) => GrammarPoint.fromJson(e)).toList(),
    dailySets: (jsonDecode(dailyRaw) as List).map((e) => DailySet.fromJson(e)).toList(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final FlutterTts _tts = FlutterTts();
  late Future<AppData> _future;
  int _tab = 0;
  int _xp = 0;
  Set<String> _learnedWords = {};
  Set<String> _learnedGrammar = {};
  Set<String> _completedTasks = {};
  int _streak = 0;
  String _lastStudyDate = "";
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _future = loadData();
    _initTts();
    _load();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.43);
    await _tts.setPitch(1.0);
    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker, IosTextToSpeechAudioCategoryOptions.allowBluetooth, IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        IosTextToSpeechAudioMode.defaultMode,
      );
    } catch (_) {}
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _xp = p.getInt('xp') ?? 0;
      _learnedWords = (p.getStringList('learnedWords') ?? []).toSet();
      _learnedGrammar = (p.getStringList('learnedGrammar') ?? []).toSet();
      _completedTasks = (p.getStringList('completedTasks') ?? []).toSet();
      _streak = p.getInt('streak') ?? 0;
      _lastStudyDate = p.getString('lastStudyDate') ?? '';
      _remindersEnabled = p.getBool('remindersEnabled') ?? false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('xp', _xp);
    await p.setStringList('learnedWords', _learnedWords.toList());
    await p.setStringList('learnedGrammar', _learnedGrammar.toList());
    await p.setStringList('completedTasks', _completedTasks.toList());
    await p.setInt('streak', _streak);
    await p.setString('lastStudyDate', _lastStudyDate);
    await p.setBool('remindersEnabled', _remindersEnabled);
  }



  String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> touchStudyDay() async {
    final today = _dateKey(DateTime.now());
    if (_lastStudyDate == today) return;
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    setState(() {
      _streak = _lastStudyDate == yesterday ? _streak + 1 : 1;
      _lastStudyDate = today;
    });
    await _save();
  }

  Future<void> toggleReminder(bool value) async {
    if (value) {
      await OceanNotificationService.instance.scheduleDailyReminder();
      await OceanNotificationService.instance.showCutePreview();
    } else {
      await OceanNotificationService.instance.cancelDailyReminder();
    }
    setState(() => _remindersEnabled = value);
    await _save();
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    await touchStudyDay();
    setState(() => _xp += amount);
    await _save();
  }

  Future<void> markWord(String id) async {
    await touchStudyDay();
    setState(() {
      if (_learnedWords.contains(id)) {
        _learnedWords.remove(id);
      } else {
        _learnedWords.add(id);
        _xp += 2;
      }
    });
    await _save();
  }

  Future<void> markGrammar(String id) async {
    await touchStudyDay();
    setState(() {
      if (_learnedGrammar.contains(id)) {
        _learnedGrammar.remove(id);
      } else {
        _learnedGrammar.add(id);
        _xp += 5;
      }
    });
    await _save();
  }

  Future<void> markTask(String id, int xp) async {
    await touchStudyDay();
    setState(() {
      if (!_completedTasks.contains(id)) {
        _completedTasks.add(id);
        _xp += xp;
      }
    });
    await _save();
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    setState(() {
      _xp = 0;
      _learnedWords = {};
      _learnedGrammar = {};
      _completedTasks = {};
      _streak = 0;
      _lastStudyDate = "";
      _remindersEnabled = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!;
        final pages = [
          HomePage(data: data, xp: _xp, streak: _streak, remindersEnabled: _remindersEnabled, onToggleReminder: toggleReminder, learnedWords: _learnedWords, learnedGrammar: _learnedGrammar, completedTasks: _completedTasks, goTab: (i) => setState(() => _tab = i)),
          LearnWordsPage(words: data.words, learned: _learnedWords, onSpeak: speak, onMark: markWord, onXp: addXp),
          GrammarPage(grammar: data.grammar, learned: _learnedGrammar, onSpeak: speak, onMark: markGrammar),
          DailyFivePage(dailySets: data.dailySets, completed: _completedTasks, onSpeak: speak, onComplete: markTask),
          ProfilePage(words: data.words, grammar: data.grammar, learnedWords: _learnedWords, learnedGrammar: _learnedGrammar, completedTasks: _completedTasks, xp: _xp, streak: _streak, remindersEnabled: _remindersEnabled, onToggleReminder: toggleReminder, onReset: reset),
        ];
        return Scaffold(
          body: SafeArea(child: pages[_tab]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Ocean'),
              NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Học từ'),
              NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: 'Ngữ pháp'),
              NavigationDestination(icon: Icon(Icons.view_week_rounded), label: '5 câu'),
              NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Hồ sơ'),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final AppData data;
  final int xp;
  final int streak;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminder;
  final Set<String> learnedWords;
  final Set<String> learnedGrammar;
  final Set<String> completedTasks;
  final ValueChanged<int> goTab;
  const HomePage({super.key, required this.data, required this.xp, required this.streak, required this.remindersEnabled, required this.onToggleReminder, required this.learnedWords, required this.learnedGrammar, required this.completedTasks, required this.goTab});

  @override
  Widget build(BuildContext context) {
    final todaySet = todayDailySet(data.dailySets);
    final todayDone = todaySet.tasks.where((t) => completedTasks.contains(t.id)).length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFCDEFFF), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0077B6).withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8))]), child: const Center(child: Text('🐳', style: TextStyle(fontSize: 32)))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hanzi Ocean', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Học HSK mỗi ngày như một chuyến ra biển 🌊')])),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF00B4D8)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ocean Mission', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Hôm nay: $todayDone/5 câu • Streak: $streak ngày 🔥', style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 16),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0077B6)), onPressed: () => goTab(3), child: const Text('Lướt sóng 5 câu ngay 🌊')),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: todayDone / 5),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 12, borderRadius: BorderRadius.circular(99), backgroundColor: Colors.white24, color: Colors.white),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatCard(title: 'XP', value: '$xp', icon: Icons.bolt_rounded)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(title: 'Từ đã thuộc', value: '${learnedWords.length}/${data.words.length}', icon: Icons.check_circle_rounded)),
        ]),
        const SizedBox(height: 14),
        StreakOceanCard(streak: streak, completedToday: todayDone >= 5),
        const SizedBox(height: 10),
        ReminderOceanCard(enabled: remindersEnabled, onChanged: onToggleReminder),
        const SizedBox(height: 14),
        HomeActionCard(icon: Icons.school_rounded, title: 'Học thuộc từ kiểu Duolingo', subtitle: 'Bài ngắn, chọn nghĩa, nghe phát âm, cộng XP.', onTap: () => goTab(1)),
        HomeActionCard(icon: Icons.auto_stories_rounded, title: 'Ngữ pháp tách HSK 1 / HSK 2', subtitle: 'Có mẫu câu, lỗi hay sai và cách nói tự nhiên.', onTap: () => goTab(2)),
        HomeActionCard(icon: Icons.access_time_rounded, title: 'Nhấn mạnh thời gian', subtitle: 'Mỗi ngày có câu với 今天, 明天, 以前, 以后, 的时候...', onTap: () => goTab(3)),
      ],
    );
  }
}

class LearnWordsPage extends StatefulWidget {
  final List<VocabWord> words;
  final Set<String> learned;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String) onMark;
  final Future<void> Function(int) onXp;
  const LearnWordsPage({super.key, required this.words, required this.learned, required this.onSpeak, required this.onMark, required this.onXp});

  @override
  State<LearnWordsPage> createState() => _LearnWordsPageState();
}

class _LearnWordsPageState extends State<LearnWordsPage> {
  String level = 'HSK1';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final levelWords = widget.words.where((w) => w.level == level).toList();
    final units = chunk(levelWords, 15);
    final filtered = widget.words.where((w) => query.isEmpty || w.hanzi.contains(query) || w.pinyin.toLowerCase().contains(query.toLowerCase()) || w.meaningVi.toLowerCase().contains(query.toLowerCase())).toList();
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, 8), child: PageTitle(title: 'Học từ', subtitle: 'Đường học ngắn kiểu Duolingo + tra từ')),
        const TabBar(tabs: [Tab(icon: Icon(Icons.route_rounded), text: 'Đường học'), Tab(icon: Icon(Icons.search_rounded), text: 'Tra từ')]),
        Expanded(child: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(18), children: [
            LevelSelector(value: level, onChanged: (v) => setState(() => level = v)),
            const SizedBox(height: 14),
            for (int i = 0; i < units.length; i++) UnitCard(index: i + 1, words: units[i], learned: widget.learned, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => WordLessonSession(words: units[i], allWords: widget.words, onSpeak: widget.onSpeak, onMark: widget.onMark, onXp: widget.onXp)));
            }),
          ]),
          Column(children: [
            Padding(padding: const EdgeInsets.all(18), child: SearchBox(hint: 'Tìm chữ Hán, pinyin, nghĩa...', onChanged: (v) => setState(() => query = v))),
            Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), itemCount: filtered.length, itemBuilder: (context, i) {
              final w = filtered[i];
              return WordListTile(word: w, learned: widget.learned.contains(w.id), onSpeak: widget.onSpeak, onMark: widget.onMark);
            })),
          ]),
        ])),
      ]),
    );
  }
}

class WordLessonSession extends StatefulWidget {
  final List<VocabWord> words;
  final List<VocabWord> allWords;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String) onMark;
  final Future<void> Function(int) onXp;
  const WordLessonSession({super.key, required this.words, required this.allWords, required this.onSpeak, required this.onMark, required this.onXp});

  @override
  State<WordLessonSession> createState() => _WordLessonSessionState();
}

class _WordLessonSessionState extends State<WordLessonSession> {
  int index = 0;
  int score = 0;
  String? selected;
  bool checked = false;
  late List<VocabWord> sessionWords;

  @override
  void initState() {
    super.initState();
    sessionWords = widget.words.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final finished = index >= sessionWords.length;
    if (finished) {
      return Scaffold(
        backgroundColor: const Color(0xFFEAF8FF),
        appBar: AppBar(backgroundColor: const Color(0xFFEAF8FF), title: const Text('Hoàn thành')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          Text('Đúng $score/${sessionWords.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () async { await widget.onXp(score * 3); if (context.mounted) Navigator.pop(context); }, child: Text('Nhận ${score * 3} XP')),
        ]))),
      );
    }
    final w = sessionWords[index];
    final options = makeMeaningOptions(w, widget.allWords);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FF),
      appBar: AppBar(backgroundColor: const Color(0xFFEAF8FF), title: Text('Bài ${index + 1}/${sessionWords.length}')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        LinearProgressIndicator(value: (index + 1) / sessionWords.length, minHeight: 10, borderRadius: BorderRadius.circular(99)),
        const SizedBox(height: 18),
        CardBox(child: Column(children: [
          Text(w.hanzi, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
          Text(w.pinyin, style: const TextStyle(color: Color(0xFF0077B6), fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          IconButton.filledTonal(onPressed: () => widget.onSpeak(w.hanzi), icon: const Icon(Icons.volume_up_rounded)),
        ])),
        const SizedBox(height: 14),
        const Text('Chọn nghĩa đúng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final opt in options) Padding(padding: const EdgeInsets.only(bottom: 10), child: ChoiceTile(text: opt, selected: selected == opt, correct: checked && opt == w.meaningVi, wrong: checked && selected == opt && opt != w.meaningVi, onTap: checked ? null : () => setState(() => selected = opt))),
        const SizedBox(height: 12),
        FilledButton(onPressed: selected == null ? null : () async {
          if (!checked) {
            setState(() { checked = true; if (selected == w.meaningVi) score++; });
            if (selected == w.meaningVi) await widget.onMark(w.id);
          } else {
            setState(() { index++; selected = null; checked = false; });
          }
        }, child: Text(checked ? 'Tiếp tục' : 'Kiểm tra')),
      ]),
    );
  }
}

class GrammarPage extends StatefulWidget {
  final List<GrammarPoint> grammar;
  final Set<String> learned;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String) onMark;
  const GrammarPage({super.key, required this.grammar, required this.learned, required this.onSpeak, required this.onMark});

  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  String level = 'HSK1';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.grammar.where((g) => g.level == level && (query.isEmpty || g.title.toLowerCase().contains(query.toLowerCase()) || g.pattern.toLowerCase().contains(query.toLowerCase()))).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle(title: 'Ngữ pháp', subtitle: 'HSK 1 và HSK 2 tách riêng, phân tích để nói tự nhiên'),
        const SizedBox(height: 12),
        LevelSelector(value: level, onChanged: (v) => setState(() => level = v)),
        const SizedBox(height: 12),
        SearchBox(hint: 'Tìm: de, 的时候, 比, 了...', onChanged: (v) => setState(() => query = v)),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), itemCount: list.length, itemBuilder: (context, i) {
        final g = list[i];
        final learned = widget.learned.contains(g.id);
        return GrammarExpansion(point: g, learned: learned, onSpeak: widget.onSpeak, onMark: widget.onMark);
      })),
    ]);
  }
}

class DailyFivePage extends StatefulWidget {
  final List<DailySet> dailySets;
  final Set<String> completed;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String, int) onComplete;
  const DailyFivePage({super.key, required this.dailySets, required this.completed, required this.onSpeak, required this.onComplete});

  @override
  State<DailyFivePage> createState() => _DailyFivePageState();
}

class _DailyFivePageState extends State<DailyFivePage> {
  int taskIndex = 0;
  List<String> chosen = [];
  bool checked = false;
  bool correct = false;

  @override
  Widget build(BuildContext context) {
    final set = todayDailySet(widget.dailySets);
    final task = set.tasks[taskIndex];
    final done = set.tasks.where((t) => widget.completed.contains(t.id)).length;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const PageTitle(title: '5 câu mỗi ngày', subtitle: 'Ghép câu tiếng Trung từ câu tiếng Việt, nhấn mạnh thời gian'),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: done / 5, minHeight: 10, borderRadius: BorderRadius.circular(99)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: LevelChip(text: 'Câu ${taskIndex + 1}/5 • ${task.level}')),
        const SizedBox(width: 8),
        LevelChip(text: 'Thời gian: ${task.timeFocus}'),
      ]),
      const SizedBox(height: 12),
      CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task.topic, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0077B6))),
        const SizedBox(height: 8),
        Text(task.viSentence, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.25)),
        const SizedBox(height: 10),
        Text('Ngữ pháp: ${task.grammarFocus}', style: const TextStyle(color: Colors.black54)),
      ])),
      const SizedBox(height: 12),
      CardBox(child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (int i = 0; i < chosen.length; i++) InputChip(label: Text(chosen[i]), onDeleted: checked ? null : () => setState(() => chosen.removeAt(i))),
        if (chosen.isEmpty) const Text('Bấm các từ bên dưới để ghép câu...', style: TextStyle(color: Colors.black54)),
      ])),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final opt in task.options) ActionChip(label: Text(opt), onPressed: checked ? null : () => setState(() => chosen.add(opt))),
      ]),
      const SizedBox(height: 16),
      FilledButton(onPressed: chosen.isEmpty ? null : () async {
        if (!checked) {
          final ok = listEqualsTrim(chosen, task.answerTokens);
          setState(() { checked = true; correct = ok; });
          if (ok) {
            final willFinishToday = !widget.completed.contains(task.id) && done + 1 >= 5;
            await widget.onComplete(task.id, 5);
            if (willFinishToday && context.mounted) showOceanCelebration(context);
          }
        } else {
          setState(() { taskIndex = (taskIndex + 1) % 5; chosen = []; checked = false; correct = false; });
        }
      }, child: Text(checked ? 'Câu tiếp' : 'Kiểm tra')),
      const SizedBox(height: 12),
      if (checked) CardBox(color: correct ? const Color(0xFFD7F9F4) : const Color(0xFFFFE7EF), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(correct ? 'Đúng rồi!' : 'Chưa đúng, xem câu tự nhiên:', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: Text(task.answerZh, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton.filledTonal(onPressed: () => widget.onSpeak(task.answerZh), icon: const Icon(Icons.volume_up_rounded))]),
        const SizedBox(height: 6),
        Text('Mẹo: đặt cụm thời gian trước động từ; khi dùng 的时候, mệnh đề thời gian đứng trước câu chính.'),
      ])),
    ]);
  }
}

class ProfilePage extends StatelessWidget {
  final List<VocabWord> words;
  final List<GrammarPoint> grammar;
  final Set<String> learnedWords;
  final Set<String> learnedGrammar;
  final Set<String> completedTasks;
  final int xp;
  final int streak;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminder;
  final Future<void> Function() onReset;
  const ProfilePage({super.key, required this.words, required this.grammar, required this.learnedWords, required this.learnedGrammar, required this.completedTasks, required this.xp, required this.streak, required this.remindersEnabled, required this.onToggleReminder, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(18), children: [
      const PageTitle(title: 'Hồ sơ', subtitle: 'Tiến độ học kiểu nhỏ gọn'),
      const SizedBox(height: 18),
      CardBox(child: Column(children: [
        const Text('🐳', style: TextStyle(fontSize: 64)),
        const Text('Ocean learner HSK 1–2', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: StatCard(title: 'XP', value: '$xp', icon: Icons.bolt_rounded)), const SizedBox(width: 10), Expanded(child: StatCard(title: 'Streak', value: '$streak ngày', icon: Icons.local_fire_department_rounded))]),
        const SizedBox(height: 10),
        ReminderOceanCard(enabled: remindersEnabled, onChanged: onToggleReminder),
        const SizedBox(height: 18),
        ProgressLabel(title: 'Từ vựng', value: learnedWords.length / words.length, text: '${learnedWords.length}/${words.length}'),
        const SizedBox(height: 12),
        ProgressLabel(title: 'Ngữ pháp', value: learnedGrammar.length / grammar.length, text: '${learnedGrammar.length}/${grammar.length}'),
      ])),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () async { await onReset(); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Xóa tiến độ')),
    ]);
  }
}

// ---------- Widgets ----------

class UnitCard extends StatelessWidget {
  final int index;
  final List<VocabWord> words;
  final Set<String> learned;
  final VoidCallback onTap;
  const UnitCard({super.key, required this.index, required this.words, required this.learned, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final done = words.where((w) => learned.contains(w.id)).length;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: CardBox(child: InkWell(onTap: onTap, child: Row(children: [
      CircleAvatar(radius: 26, backgroundColor: const Color(0xFFCDEFFF), child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w900))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Unit $index', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('${words.length} từ • đã thuộc $done/${words.length}'), const SizedBox(height: 8), LinearProgressIndicator(value: done / words.length, minHeight: 8, borderRadius: BorderRadius.circular(99))])),
      const Icon(Icons.chevron_right_rounded),
    ]))));
  }
}

class GrammarExpansion extends StatelessWidget {
  final GrammarPoint point;
  final bool learned;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String) onMark;
  const GrammarExpansion({super.key, required this.point, required this.learned, required this.onSpeak, required this.onMark});

  @override
  Widget build(BuildContext context) {
    final ex = point.examples.first;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(
      elevation: 0,
      color: learned ? const Color(0xFFD7F9F4) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(point.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(point.pattern),
        leading: CircleAvatar(backgroundColor: const Color(0xFFCDEFFF), child: Icon(learned ? Icons.check_rounded : Icons.auto_stories_rounded, color: const Color(0xFF0077B6))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          InfoBlock(title: '1. Cách hiểu', text: point.meaningVi),
          InfoBlock(title: '2. Nói tự nhiên như người bản địa', text: point.nativeNote),
          InfoBlock(title: '3. Lỗi hay sai', text: point.commonMistake),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ex.zh, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(ex.pinyin, style: const TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.w800)), Text(ex.vi)])), IconButton.filledTonal(onPressed: () => onSpeak(ex.zh), icon: const Icon(Icons.volume_up_rounded))]),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: () => onMark(point.id), icon: Icon(learned ? Icons.undo_rounded : Icons.check_rounded), label: Text(learned ? 'Bỏ đã học' : 'Đánh dấu đã học')),
        ],
      ),
    ));
  }
}

class WordListTile extends StatelessWidget {
  final VocabWord word;
  final bool learned;
  final Future<void> Function(String) onSpeak;
  final Future<void> Function(String) onMark;
  const WordListTile({super.key, required this.word, required this.learned, required this.onSpeak, required this.onMark});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: CardBox(color: learned ? const Color(0xFFD7F9F4) : Colors.white, child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(word.hanzi, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), Text(word.pinyin, style: const TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.w800)), Text(word.meaningVi)])),
      IconButton.filledTonal(onPressed: () => onSpeak(word.hanzi), icon: const Icon(Icons.volume_up_rounded)),
      IconButton(onPressed: () => onMark(word.id), icon: Icon(learned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: learned ? Colors.green : Colors.grey)),
    ])));
  }
}

class HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const HomeActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: CardBox(child: ListTile(onTap: onTap, leading: CircleAvatar(backgroundColor: const Color(0xFFCDEFFF), child: Icon(icon, color: const Color(0xFF0077B6))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded))));
}

class ChoiceTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;
  const ChoiceTile({super.key, required this.text, required this.selected, required this.correct, required this.wrong, required this.onTap});
  @override
  Widget build(BuildContext context) {
    Color color = selected ? const Color(0xFFCDEFFF) : Colors.white;
    if (correct) color = const Color(0xFFD7F9F4);
    if (wrong) color = const Color(0xFFFFD6E5);
    return Card(elevation: 0, color: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: ListTile(onTap: onTap, title: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))));
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final Color color;
  const CardBox({super.key, required this.child, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(16), child: child));
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const StatCard({super.key, required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF0077B6)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(title)]));
}

class PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const PageTitle({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))]);
}

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBox({super.key, required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(onChanged: onChanged, decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)));
}

class LevelSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const LevelSelector({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SegmentedButton<String>(segments: const [ButtonSegment(value: 'HSK1', label: Text('HSK 1')), ButtonSegment(value: 'HSK2', label: Text('HSK 2'))], selected: {value}, onSelectionChanged: (s) => onChanged(s.first));
}

class LevelChip extends StatelessWidget {
  final String text;
  const LevelChip({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFCDEFFF), borderRadius: BorderRadius.circular(999)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)));
}

class InfoBlock extends StatelessWidget {
  final String title;
  final String text;
  const InfoBlock({super.key, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(text)]));
}

class ProgressLabel extends StatelessWidget {
  final String title;
  final double value;
  final String text;
  const ProgressLabel({super.key, required this.title, required this.value, required this.text});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), LinearProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), minHeight: 10, borderRadius: BorderRadius.circular(99)), const SizedBox(height: 6), Text(text)]);
}


class StreakOceanCard extends StatelessWidget {
  final int streak;
  final bool completedToday;
  const StreakOceanCard({super.key, required this.streak, required this.completedToday});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: CardBox(
        color: const Color(0xFFD7F9F4),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 42)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chuỗi streak: $streak ngày', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text(completedToday ? 'Tuyệt vời! Hôm nay bạn đã giữ sóng học tập 🌊' : 'Học ít nhất 1 bài để giữ streak hôm nay nhé.'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderOceanCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const ReminderOceanCard({super.key, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      color: Colors.white,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(enabled ? '🦦' : '🐚', key: ValueKey(enabled), style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nhắc học dễ thương', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text('Bật thông báo để mỗi ngày có một lời nhắc học HSK nhẹ nhàng.'),
            ]),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

Future<void> showOceanCelebration(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFEAF8FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('🐳 Hoàn thành hôm nay!'),
      content: const Text('Bạn đã làm đủ 5 câu. Sóng streak hôm nay đã được giữ lại 🌊✨'),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tiếp tục học')),
      ],
    ),
  );
}

// ---------- Helpers ----------

List<List<T>> chunk<T>(List<T> list, int size) {
  final out = <List<T>>[];
  for (int i = 0; i < list.length; i += size) {
    out.add(list.sublist(i, min(i + size, list.length)));
  }
  return out;
}

List<String> makeMeaningOptions(VocabWord correct, List<VocabWord> all) {
  final r = Random(correct.id.hashCode);
  final wrong = all.where((w) => w.meaningVi != correct.meaningVi).toList()..shuffle(r);
  final opts = [correct.meaningVi, ...wrong.take(3).map((w) => w.meaningVi)]..shuffle(r);
  return opts;
}

DailySet todayDailySet(List<DailySet> sets) {
  final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays.abs();
  return sets[dayIndex % sets.length];
}

bool listEqualsTrim(List<String> a, List<String> b) {
  final aa = a.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final bb = b.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (aa.length != bb.length) return false;
  for (int i = 0; i < aa.length; i++) {
    if (aa[i] != bb[i]) return false;
  }
  return true;
}
