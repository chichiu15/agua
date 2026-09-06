import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

String verDate(DateTime? value, {bool time = false}) {
  if (value == null || value.millisecondsSinceEpoch == 0) return '-';
  String two(int v) => v.toString().padLeft(2, '0');
  final d = '${two(value.day)}/${two(value.month)}/${value.year}';
  if (!time) return d;
  return '$d ${two(value.hour)}:${two(value.minute)}';
}

String verDecimal(double? value, {int decimals = 4}) {
  if (value == null) return '-';
  return value.toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');
}

String? verNullable(String? value) =>
    (value == null || value.trim().isEmpty) ? null : value.trim();

class VerStatusChip extends StatelessWidget {
  const VerStatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l = label.toLowerCase();
    Color fg = const Color(0xFF4B5563), bg = const Color(0xFFF1F3F4), border = const Color(0xFFD7DCE0);
    if (l.contains('cumple') && !l.contains('no ')) {
      fg = const Color(0xFF08783F);
      bg = const Color(0xFFE8F7EE);
      border = const Color(0xFFB6E3C7);
    }
    if (l.contains('no cumple') || l.contains('error')) {
      fg = const Color(0xFFB42318);
      bg = const Color(0xFFFFEEEE);
      border = const Color(0xFFFFC7C2);
    }
    if (l.contains('indet')) {
      fg = const Color(0xFFB36B00);
      bg = const Color(0xFFFFF6E5);
      border = const Color(0xFFFFD591);
    }
    if (l.contains('pend')) {
      fg = const Color(0xFFB36B00);
      bg = const Color(0xFFFFF6E5);
      border = const Color(0xFFFFD591);
    }
    if (l.contains('curso') || l.contains('toma')) {
      fg = const Color(0xFF1D5FBF);
      bg = const Color(0xFFEDF4FF);
      border = const Color(0xFFBFD7FF);
    }
    if (l.contains('complet')) {
      fg = const Color(0xFF08783F);
      bg = const Color(0xFFE8F7EE);
      border = const Color(0xFFB6E3C7);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class VerMessageBar extends StatelessWidget {
  const VerMessageBar({super.key, this.error, this.success});

  final String? error;
  final String? success;

  @override
  Widget build(BuildContext context) {
    if (error == null && success == null) return const SizedBox.shrink();
    final isError = error != null;
    final color = isError ? AppColors.odecoRed : AppColors.successGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error ?? success ?? '',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class VerEmpty extends StatelessWidget {
  const VerEmpty(this.message, {super.key, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 45),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Color(0xFF68737D))),
        ],
      ),
    ),
  );
}

class VerSection extends StatelessWidget {
  const VerSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFD9E2E7)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class VerDataRow extends StatelessWidget {
  const VerDataRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}