import 'package:flutter/material.dart';

import '../ui/resource_paths.dart';
import '../ui/visual_tokens.dart';
import '../services/audio_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ResourcePaths.startBg, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButton(onTap: () {
                        AudioService.instance.playSfx(Sfx.buttonClick);
                        Navigator.of(context).pop();
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Shop',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title(size: 36),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 28),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.accent,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Coming Soon',
                              style: AppTextStyles.title(size: 42),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We\'re building something great.\nCheck back soon!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                  size: 16,
                                  color: AppColors.text
                                      .withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded,
              color: AppColors.text, size: 26),
        ),
      ),
    );
  }
}
