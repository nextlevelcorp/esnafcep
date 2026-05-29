import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final box = HiveService.settingsBox;
    _nameCtrl.text = box.get('ownerName', defaultValue: '');
    _businessCtrl.text = box.get('businessName', defaultValue: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final box = HiveService.settingsBox;
    box.put('ownerName', _nameCtrl.text.trim());
    box.put('businessName', _businessCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kaydedildi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EsnafCep', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      Text('Kasa & Veresiye Takip', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(text: 'İşletme Bilgileri'),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Column(
                children: [
                  _FieldRow(
                    icon: Icons.person_rounded,
                    label: 'Adınız',
                    child: TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Ahmet Yılmaz',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                  const Divider(),
                  _FieldRow(
                    icon: Icons.storefront_rounded,
                    label: 'İşletme Adı',
                    child: TextField(
                      controller: _businessCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Yılmaz Bakkal',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(text: 'Uygulama Hakkında'),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Column(
                children: const [
                  _InfoRow(icon: Icons.info_outline_rounded, label: 'Versiyon', value: '1.0.0'),
                  Divider(),
                  _InfoRow(icon: Icons.offline_bolt_rounded, label: 'Veri Depolama', value: 'Cihazda (offline)'),
                  Divider(),
                  _InfoRow(icon: Icons.code_rounded, label: 'Yapımcı', value: 'EsnafCep'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(text: 'Geliştirici'),
            const SizedBox(height: 12),
            _SettingsCard(
              child: _TapRow(
                icon: Icons.replay_rounded,
                label: 'Karşılama Ekranını Göster',
                color: AppColors.warning,
                onTap: () {
                  HiveService.settingsBox.put('onboardingDone', false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Uygulamayı kapatıp açın'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5),
  );
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _FieldRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TapRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
