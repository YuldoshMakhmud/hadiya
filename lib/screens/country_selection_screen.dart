import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/hadiya_logo.dart';

class CountrySelectionScreen extends StatelessWidget {
  const CountrySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const HadiyaLogo(size: 90),
              const SizedBox(height: 48),
              const Text(
                'Siz qayerdasiz?',
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Narxlar shu mamlakatga mos valyutada ko\'rsatiladi',
                style: TextStyle(
                  color: AppColors.cream.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _CountryButton(
                flag: '🇰🇷',
                label: 'Koreya',
                subtitle: 'Narxlar Won (₩) da',
                onTap: () => _select(context, true),
              ),
              const SizedBox(height: 16),
              _CountryButton(
                flag: '🇺🇿',
                label: 'O\'zbekiston',
                subtitle: 'Narxlar So\'m da',
                onTap: () => _select(context, false),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, bool isKorea) async {
    await context.read<AppProvider>().setCountry(isKorea);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class _CountryButton extends StatelessWidget {
  final String flag;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _CountryButton({
    required this.flag,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
