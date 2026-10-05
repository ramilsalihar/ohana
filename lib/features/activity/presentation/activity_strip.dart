import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/supabase_activity_repository.dart';
import '../domain/partner_activity.dart';

/// Override in tests with a fake.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => SupabaseActivityRepository(Supabase.instance.client),
);

final partnerActivityProvider = FutureProvider<List<PartnerActivity>>(
  (ref) => ref.watch(activityRepositoryProvider).getPartnerActivity(),
  retry: (_, _) => null,
);

/// A small strip of the partner's recent positive actions. Shows nothing at
/// all when there is nothing to show: an empty strip must never read as
/// "your partner has not done anything".
class ActivityStrip extends ConsumerWidget {
  const ActivityStrip({super.key});

  /// How many of the most recent items are shown.
  static const maxItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(partnerActivityProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items.take(maxItems))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                item.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
