import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: '👋',
      title: 'EsnafCep\'e\nHoş Geldiniz',
      subtitle: 'Kasa takibi ve veresiye yönetimini\nkolaylaştırmak için buradayız.',
      color: AppColors.primary,
    ),
    _OnboardPage(
      emoji: '💰',
      title: 'Kasanızı\nTakip Edin',
      subtitle: 'Nakit, kart ve veresiye satışlarınızı\nsaniyeler içinde kaydedin.',
      color: Color(0xFF4A90D9),
    ),
    _OnboardPage(
      emoji: '🤝',
      title: 'Veresiyeyi\nKontrol Altında Tutun',
      subtitle: 'Müşteri borçlarını takip edin,\nWhatsApp ile makbuz gönderin.',
      color: Color(0xFFBA7517),
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    final name = _nameCtrl.text.trim();
    final business = _businessCtrl.text.trim();
    if (business.isEmpty) return;

    final box = HiveService.settingsBox;
    box.put('ownerName', name);
    box.put('businessName', business);
    box.put('onboardingDone', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          ..._pages.asMap().entries.map((e) => _PageView(
            page: e.value,
            isLast: e.key == _pages.length - 1,
            currentIndex: e.key,
            total: _pages.length,
            onNext: _next,
          )),
          _SetupPage(
            nameCtrl: _nameCtrl,
            businessCtrl: _businessCtrl,
            onFinish: _finish,
            currentIndex: _pages.length,
            total: _pages.length + 1,
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji, title, subtitle;
  final Color color;
  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _PageView extends StatelessWidget {
  final _OnboardPage page;
  final bool isLast;
  final int currentIndex, total;
  final VoidCallback onNext;

  const _PageView({
    required this.page,
    required this.isLast,
    required this.currentIndex,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Dots
            _Dots(current: currentIndex, total: total),
            const Spacer(),
            // Emoji illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(page.emoji, style: const TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 40),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const Spacer(),
            // Next button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: page.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: onNext,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Hadi Başlayalım' : 'Devam',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SetupPage extends StatefulWidget {
  final TextEditingController nameCtrl, businessCtrl;
  final VoidCallback onFinish;
  final int currentIndex, total;

  const _SetupPage({
    required this.nameCtrl,
    required this.businessCtrl,
    required this.onFinish,
    required this.currentIndex,
    required this.total,
  });

  @override
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  @override
  void initState() {
    super.initState();
    widget.businessCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = widget.businessCtrl.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 28, right: 28, top: 28,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Dots(current: widget.currentIndex, total: widget.total),
            const SizedBox(height: 32),
            const Text(
              'İşletmenizi\nTanıtalım',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Makbuzlarda ve raporlarda görünecek.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            // Business name (required)
            _InputLabel(text: 'İşletme Adı *', icon: Icons.storefront_rounded),
            const SizedBox(height: 8),
            TextField(
              controller: widget.businessCtrl,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'ör. Ahmet\'in Bakkalı',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            // Owner name (optional)
            _InputLabel(text: 'Adınız (opsiyonel)', icon: Icons.person_rounded),
            const SizedBox(height: 8),
            TextField(
              controller: widget.nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'ör. Ahmet Yılmaz',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canFinish ? AppColors.primary : AppColors.border,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: canFinish ? widget.onFinish : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Uygulamayı Aç', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.check_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int current, total;
  const _Dots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InputLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }
}
