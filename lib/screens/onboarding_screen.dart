import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _primary = Color(0xFF1A5C52);
  static const _cream = Color(0xFFF2E4CF);

  final List<_PageData> _pages = const [
    _PageData(
      emoji: '✈️',
      badge: 'Korea → Uzbekistan',
      title: 'Koreyadan\nO\'zbekistonga',
      subtitle:
          'Eng sifatli koreya kosmetikasi,\nvitaminlari va ginsengi to\'g\'ridan-to\'g\'ri\nsizning eshigingizga yetkaziladi.',
      bg: Color(0xFF1A5C52),
      dotColor: Color(0xFFF2E4CF),
    ),
    _PageData(
      emoji: '🎁',
      badge: 'Yaqinlaringiz uchun',
      title: 'Eng yaxshi\nHadiyalar',
      subtitle:
          'Ona, opa, do\'st yoki Oilangizga —\nhaqiqiy koreya mahsulotlari bilan\nsevgingizni ifodalang.',
      bg: Color(0xFF14504A),
      dotColor: Color(0xFFF2E4CF),
    ),
    _PageData(
      emoji: '🌿',
      badge: '100% Original',
      title: 'Hammasi sizning\nqulingizda',
      subtitle:
          'Telefoningizdan buyurtma bering,\nchekni yuboring — biz qolganini\nhalol va tez yetkazib beramiz.',
      bg: Color(0xFF0F3D35),
      dotColor: Color(0xFFF2E4CF),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/country');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: page.bg,
        child: SafeArea(
          child: Column(
            children: [
              // Skip tugmasi
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'O\'tkazib yuborish',
                      style: TextStyle(
                        color: _cream.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
                ),
              ),

              // Dots + Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? _cream : _cream.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Next / Boshlash button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cream,
                          foregroundColor: _primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Boshlash 🚀'
                              : 'Davom etish',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page Widget ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              data.badge,
              style: const TextStyle(
                color: Color(0xFFF2E4CF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF2E4CF),
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF2E4CF).withOpacity(0.75),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _PageData {
  final String emoji;
  final String badge;
  final String title;
  final String subtitle;
  final Color bg;
  final Color dotColor;

  const _PageData({
    required this.emoji,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.dotColor,
  });
}
