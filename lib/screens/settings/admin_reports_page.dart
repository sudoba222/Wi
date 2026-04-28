// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';

const String kAdminEmail = 'sudobamirzozoda78@gmail.com';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  Stream<QuerySnapshot> get _stream {
    Query q = FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('createdAt', descending: true);
    return q.snapshots();
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      if (_typeFilter != 'all' && data['type'] != _typeFilter) return false;
      if (_statusFilter != 'all' && data['status'] != _statusFilter) return false;
      return true;
    }).toList();
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('feedback').doc(docId).update({'status': status});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sunglow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.sunglow)),
            ),
            const SizedBox(width: 8),
            Text('Reports', style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.wisteria, strokeWidth: 2));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final filtered = _applyFilters(allDocs);

          final bugCount = allDocs.where((d) => (d.data() as Map)['type'] == 'bug').length;
          final feedbackCount = allDocs.where((d) => (d.data() as Map)['type'] == 'feedback').length;
          final featureCount = allDocs.where((d) => (d.data() as Map)['type'] == 'feature').length;
          final openCount = allDocs.where((d) => (d.data() as Map)['status'] == 'open').length;

          return Column(
            children: [
              // Stats row
              Container(
                color: isDark ? AppColors.darkCard : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    _StatBadge(count: bugCount, label: 'Bugs', color: Colors.redAccent),
                    const SizedBox(width: 8),
                    _StatBadge(count: feedbackCount, label: 'Feedback', color: AppColors.sunglow),
                    const SizedBox(width: 8),
                    _StatBadge(count: featureCount, label: 'Features', color: AppColors.wisteria),
                    const SizedBox(width: 8),
                    _StatBadge(count: openCount, label: 'Open', color: const Color(0xFF10B981)),
                  ],
                ),
              ),

              // Filters
              Container(
                color: isDark ? AppColors.darkCard : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    _ChipRow(
                      label: 'Type:',
                      options: const {'all': 'All', 'bug': 'Bugs', 'feedback': 'Feedback', 'feature': 'Features'},
                      selected: _typeFilter,
                      onSelect: (v) => setState(() => _typeFilter = v),
                    ),
                    const SizedBox(height: 6),
                    _ChipRow(
                      label: 'Status:',
                      options: const {'all': 'All', 'open': 'Open', 'in_progress': 'In Progress', 'resolved': 'Resolved'},
                      selected: _statusFilter,
                      onSelect: (v) => setState(() => _statusFilter = v),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 52, color: AppColors.mutedText.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No reports', style: TextStyle(fontSize: 16, color: text, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Matching reports will appear here', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReportCard(
                          doc: filtered[i],
                          isDark: isDark,
                          text: text,
                          onStatusChange: (s) => _updateStatus(filtered[i].id, s),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
            ],
          ),
        ),
      );
}

class _ChipRow extends StatelessWidget {
  final String label;
  final Map<String, String> options;
  final String selected;
  final void Function(String) onSelect;
  const _ChipRow({required this.label, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.entries.map((e) {
                  final isSel = selected == e.key;
                  return GestureDetector(
                    onTap: () => onSelect(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.darkPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.25),
                        ),
                      ),
                      child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? AppColors.sunglow : AppColors.mutedText)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
}

class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isDark;
  final Color text;
  final void Function(String) onStatusChange;
  const _ReportCard({required this.doc, required this.isDark, required this.text, required this.onStatusChange});

  Color _typeColor(String type) {
    switch (type) {
      case 'bug': return Colors.redAccent;
      case 'feedback': return AppColors.sunglow;
      default: return AppColors.wisteria;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bug': return Icons.bug_report_rounded;
      case 'feedback': return Icons.lightbulb_rounded;
      default: return Icons.auto_awesome_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return const Color(0xFF10B981);
      case 'in_progress': return AppColors.sunglow;
      default: return AppColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] as String? ?? 'bug';
    final title = data['title'] as String? ?? '';
    final desc = data['description'] as String? ?? '';
    final priority = data['priority'] as String?;
    final status = data['status'] as String? ?? 'open';
    final userName = data['userName'] as String? ?? '';
    final userEmail = data['userEmail'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? _formatTime(ts.toDate()) : '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _typeColor(type), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_typeIcon(type), size: 16, color: _typeColor(type)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                ),
                _StatusPill(status: status, color: _statusColor(status), onStatusChange: onStatusChange),
              ],
            ),
            const SizedBox(height: 10),
            Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.mutedText, height: 1.5)),

            if (imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                if (priority != null) ...[
                  _Tag(label: priority.toUpperCase(), color: priority == 'high' ? Colors.redAccent : priority == 'medium' ? AppColors.sunglow : const Color(0xFF10B981)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    userName.isNotEmpty ? '$userName · $time' : '$userEmail · $time',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;
  final void Function(String) onStatusChange;
  const _StatusPill({required this.status, required this.color, required this.onStatusChange});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _StatusSheet(current: status, onSelect: onStatusChange),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(_label(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 3),
              Icon(Icons.expand_more_rounded, size: 12, color: color),
            ],
          ),
        ),
      );

  String _label(String s) {
    switch (s) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      default: return 'Resolved';
    }
  }
}

class _StatusSheet extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;
  const _StatusSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = [
      ('open', 'Open', const Color(0xFF10B981), Icons.radio_button_on_rounded),
      ('in_progress', 'In Progress', AppColors.sunglow, Icons.pending_rounded),
      ('resolved', 'Resolved', AppColors.mutedText, Icons.check_circle_rounded),
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.mutedText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ...statuses.map((s) => ListTile(
            leading: Icon(s.$4, color: s.$3),
            title: Text(s.$2, style: TextStyle(fontWeight: current == s.$1 ? FontWeight.w700 : FontWeight.w500)),
            trailing: current == s.$1 ? Icon(Icons.check_rounded, color: s.$3) : null,
            onTap: () { onSelect(s.$1); Navigator.pop(context); },
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
      );
}
