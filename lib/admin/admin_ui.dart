import 'package:flutter/material.dart';
import '../core/theme.dart';

Color segColor(String s) {
  switch (s) {
    case 'Baru':
      return const Color(0xFF2F6FDE);
    case 'Setia':
      return const Color(0xFFC99700);
    case 'Tidur':
      return const Color(0xFF8A93A6);
    default:
      return const Color(0xFF1E9E5A);
  }
}

Color statusColor(String s) {
  switch (s) {
    case 'Selesai':
      return const Color(0xFF1E9E5A);
    case 'Diproses':
      return const Color(0xFF2F6FDE);
    default:
      return const Color(0xFFE07B00);
  }
}

String initialOf(String name) {
  final t = name.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          return ChoiceChip(
            label: Text(o),
            selected: o == selected,
            showCheckmark: false,
            selectedColor: AppColors.yellow,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.line),
            onSelected: (_) => onSelected(o),
          );
        },
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class LoadError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const LoadError(this.error, this.onRetry, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('Gagal memuat: $error',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}