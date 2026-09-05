import 'package:flutter/material.dart';

import 'admin_shell.dart';

String adminDate(DateTime? value, {bool time = false}) {
  if (value == null) return '-';
  String two(int v) => v.toString().padLeft(2, '0');
  final d = '${two(value.day)}/${two(value.month)}/${value.year}';
  return time ? '$d ${two(value.hour)}:${two(value.minute)}' : d;
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({super.key, required this.label, required this.value, required this.icon, this.detail, this.tone = const Color(0xFF0A7A45)});
  final String label, value;
  final String? detail;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 215,
    child: AdminCard(
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: tone.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: tone)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF68737D), fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF17212B))),
          if (detail != null) Text(detail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ])),
      ]),
    ),
  );
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = label.toLowerCase();
    Color fg = const Color(0xFF4B5563), bg = const Color(0xFFF1F3F4), border = const Color(0xFFD7DCE0);
    if (l.contains('cumple') && !l.contains('no ')) { fg = const Color(0xFF08783F); bg = const Color(0xFFE8F7EE); border = const Color(0xFFB6E3C7); }
    if (l == 'activo') { fg = const Color(0xFF08783F); bg = const Color(0xFFE8F7EE); border = const Color(0xFFB6E3C7); }
    if (l == 'inactivo') { fg = const Color(0xFF6B7280); bg = const Color(0xFFF1F3F4); border = const Color(0xFFD7DCE0); }
    if (l.contains('no cumple') || l.contains('error') || l.contains('venc')) { fg = const Color(0xFFB42318); bg = const Color(0xFFFFEEEE); border = const Color(0xFFFFC7C2); }
    if (l.contains('pend') || l.contains('revisar') || l.contains('sin actividad')) { fg = const Color(0xFFB36B00); bg = const Color(0xFFFFF6E5); border = const Color(0xFFFFD591); }
    if (l.contains('curso') || l.contains('asign') || l.contains('planif')) { fg = const Color(0xFF1D5FBF); bg = const Color(0xFFEDF4FF); border = const Color(0xFFBFD7FF); }
    if (l.contains('complet') || l.contains('sincron') || l.contains('al dia')) { fg = const Color(0xFF08783F); bg = const Color(0xFFE8F7EE); border = const Color(0xFFB6E3C7); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(999)),
      child: Text(label.isEmpty ? '-' : label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class AdminPager extends StatelessWidget {
  const AdminPager({super.key, required this.page, required this.totalPages, required this.totalItems, required this.onPage});
  final int page, totalPages, totalItems;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$totalItems registros', style: const TextStyle(color: Color(0xFF68737D), fontSize: 12)),
    const Spacer(),
    IconButton(onPressed: page > 1 ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left)),
    Text(totalPages == 0 ? '0 / 0' : '$page / $totalPages', style: const TextStyle(fontWeight: FontWeight.w700)),
    IconButton(onPressed: page < totalPages ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right)),
  ]);
}

class AdminFilterBox extends StatelessWidget {
  const AdminFilterBox({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AdminCard(padding: const EdgeInsets.all(14), child: child);
}

class AdminBarList extends StatelessWidget {
  const AdminBarList({super.key, required this.title, required this.items, this.emptyText = 'Sin datos'});
  final String title;
  final List<(String, int)> items;
  final String emptyText;
  @override
  Widget build(BuildContext context) {
    final max = items.isEmpty ? 1 : items.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    return AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      if (items.isEmpty) Text(emptyText, style: const TextStyle(color: Color(0xFF68737D)))
      else ...items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(width: 125, child: Text(e.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: e.$2 / max, minHeight: 10, backgroundColor: const Color(0xFFE8ECEA), valueColor: const AlwaysStoppedAnimation(Color(0xFF1677FF))))),
          const SizedBox(width: 8),
          SizedBox(width: 38, child: Text('${e.$2}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      )),
    ]));
  }
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 45),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42, color: Colors.grey.shade400), const SizedBox(height: 10), Text(message, style: const TextStyle(color: Color(0xFF68737D)))])),
  );
}
