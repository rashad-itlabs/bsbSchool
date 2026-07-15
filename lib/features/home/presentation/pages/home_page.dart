import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../balance/presentation/cubit/balance_cubit.dart';
import '../../../balance/presentation/pages/balance_page.dart';
import '../../../buffet_cart/presentation/pages/buffet_page.dart';
import '../../../examination/presentation/pages/examination_page.dart';
import '../../../homework/presentation/pages/homework_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../weekly_plan/presentation/pages/weekly_plan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature('Ev tapşırığı', Icons.assignment, AppColors.primary,
          const HomeworkPage()),
      _Feature('Kitabxana', Icons.local_library, Colors.teal,
          const LibraryPage()),
      _Feature('İmtahanlar', Icons.school, Colors.deepPurple,
          const ExaminationPage()),
      _Feature('Həftəlik plan', Icons.calendar_month, Colors.orange,
          const WeeklyPlanPage()),
      _Feature('Bufet', Icons.fastfood, Colors.redAccent, const BuffetPage()),
      _Feature('Balans', Icons.account_balance_wallet, Colors.green,
          const BalancePage()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BSB School'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceBanner(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BalancePage()),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Bölmələr',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: features
                .map((f) => _FeatureTile(
                      feature: f,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => f.page),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  const _Feature(this.title, this.icon, this.color, this.page);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final VoidCallback onTap;
  const _FeatureTile({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: feature.color.withValues(alpha: 0.15),
              child: Icon(feature.icon, color: feature.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(feature.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _BalanceBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balans',
                    style: TextStyle(color: Colors.white70)),
                BlocBuilder<BalanceCubit, BalanceState>(
                  builder: (context, state) => Text(
                    '${state.amount.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.add_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}
