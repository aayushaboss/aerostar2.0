import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/v2.dart';

/// Search appearances: how often recruiters found the student this week, who searched, and the
/// keywords that matched. Sample data.
class SearchAppearancesScreen extends StatelessWidget {
  const SearchAppearancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const values = [4, 9, 6, 11, 8, 5, 5];
    final max = values.reduce((a, b) => a > b ? a : b);
    const who = [('Zerodha', 'FinTech · 3 searches'), ('CRED', 'FinTech · 2 searches'), ('Swiggy', 'Food delivery · 2 searches')];
    const keywords = ['Content writing', 'Marketing intern', 'Canva', 'B.Com'];
    return PageFrame(
      title: 'Search appearances',
      backLabel: 'Profile',
      backFallback: '/tabs/profile',
      maxWidth: 720,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('This week', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 2),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('48', style: AppTextStyles.display.copyWith(fontSize: 44, letterSpacing: -1.76, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('+12 vs last week', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.successDark))),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 96,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(width: 24, height: 12 + 60.0 * values[i] / max, decoration: BoxDecoration(color: i == 3 ? AppColors.blue : AppColors.offWhite, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Text(days[i], style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Who searched', style: AppTextStyles.h3),
        V2List(top: 16, side: 0, gap: 18, children: [for (final w in who) V2Row(mark: Mark8(w.$1[0]), title: w.$1, subtitle: w.$2)]),
        const SizedBox(height: 32),
        Text('Keywords that found you', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final k in keywords) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(6)), child: Text(k, style: AppTextStyles.label.copyWith(color: AppColors.body)))]),
      ]),
    );
  }
}
