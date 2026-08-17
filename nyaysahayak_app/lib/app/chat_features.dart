import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// StructuredReportView - Matches website StructuredReport.tsx
// ─────────────────────────────────────────────────────────────

class StructuredReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  final Function(String)? onChecklistSelect;

  const StructuredReportView({
    super.key,
    required this.report,
    this.onChecklistSelect,
  });

  @override
  Widget build(BuildContext context) {
    final incidentType = report['incident_type'] ?? 'Incident Report';
    final riskLevel = report['risk_level'] ?? 'Medium';
    final summary = report['summary'] ?? '';
    final statutorySections = report['statutory_sections'] ?? report['applicable_sections'] ?? [];
    final checklist = report['checklist'] ?? [];

    final isHighRisk = riskLevel.toLowerCase() == 'high';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighRisk ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHighRisk ? Colors.red[200]! : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: isHighRisk ? Colors.red[400] : Colors.blue[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidentType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isHighRisk ? Colors.red[700] : Colors.blue[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Risk Level: ${riskLevel.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHighRisk ? Colors.red[600] : Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Summary Section
          if (summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        summary,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Grid for Laws & Checklist
          if ((statutorySections is List && statutorySections.isNotEmpty) ||
              (checklist is List && checklist.isNotEmpty))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statutory Sections
                if (statutorySections is List && statutorySections.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel_outlined, size: 16, color: Colors.purple[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Relevant Laws',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: statutorySections.map<Widget>((section) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.purple[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            section.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (statutorySections is List &&
                    statutorySections.isNotEmpty &&
                    checklist is List &&
                    checklist.isNotEmpty)
                  const SizedBox(width: 12),

                // Action Checklist
                if (checklist is List && checklist.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Action Checklist',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.green[800],
                                ),
                              ),
                              if (onChecklistSelect != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ADD',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Divider(height: 16, color: Colors.green[200]),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: checklist.map<Widget>((item) {
                                  return onChecklistSelect != null
                                      ? _buildChecklistItemClickable(item.toString())
                                      : _buildChecklistItem(item.toString());
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItemClickable(String item) {
    return GestureDetector(
      onTap: () => onChecklistSelect?.call(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF86EFAC)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[500],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[800],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ActionButtons
// ─────────────────────────────────────────────────────────────

class ActionButtons extends StatelessWidget {
  final List<dynamic> actions;
  final Function(String) onSelect;

  const ActionButtons({super.key, required this.actions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map<Widget>((action) {
          final label = action['label'] ?? action['payload'] ?? 'Action';
          final payload = action['payload'] ?? label;
          return ActionChip(
            label: Text(label),
            onPressed: () => onSelect(payload),
            backgroundColor: const Color(0xFFE6F0ED),
            labelStyle: const TextStyle(color: Color(0xFF13694F), fontWeight: FontWeight.bold),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LawyerPanel  (card list → tapping opens a profile modal)
// ─────────────────────────────────────────────────────────────

class LawyerPanel extends StatelessWidget {
  final List<dynamic> lawyers;
  const LawyerPanel({super.key, required this.lawyers});

  void _showProfile(BuildContext context, Map<String, dynamic> l) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _LawyerProfileDialog(lawyer: l),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lawyers.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Suggested Lawyers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: lawyers.length,
              itemBuilder: (context, index) {
                final l = lawyers[index] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => _showProfile(context, l),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatar(l),
                        const SizedBox(height: 12),
                        Text(
                          l['name'] ?? 'Lawyer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l['specialization'] ?? l['specialty'] ?? l['title'] ?? 'Legal Expert',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (l['rating'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, size: 13, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                '${(l['rating'] as num).toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _showProfile(context, l),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13694F),
                            minimumSize: const Size(double.infinity, 36),
                          ),
                          child: const Text('View Profile',
                              style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> l) {
    final avatarUrl = l['avatar'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[200],
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFE6F0ED),
      child: Icon(Icons.person, size: 36, color: Colors.grey[500]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lawyer Profile Dialog  (mirrors web LawyerBrowserPanel modal)
// ─────────────────────────────────────────────────────────────

class _LawyerProfileDialog extends StatefulWidget {
  final Map<String, dynamic> lawyer;
  const _LawyerProfileDialog({required this.lawyer});

  @override
  State<_LawyerProfileDialog> createState() => _LawyerProfileDialogState();
}

class _LawyerProfileDialogState extends State<_LawyerProfileDialog> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.lawyer;
    final name = l['name'] ?? 'Lawyer';
    final spec = l['specialization'] ?? l['specialty'] ?? l['title'] ?? 'Legal Expert';
    final location = l['location'] as String?;
    final bio = l['bio'] as String?;
    final rating = l['rating'];
    final experience = l['experience'];
    final hourlyRate = l['hourly_rate'];
    final barReg = l['bar_registration_number'] as String?;
    final contact = l['contact_number'] as String?;
    final lawyerType = l['lawyer_type'] as String?;
    final verified = l['verified'] == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5EDE9))),
              ),
              child: Row(
                children: [
                  const Text('Lawyer Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00634B),
                          fontSize: 15)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Basic info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lawyerAvatar(l, 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                  if (verified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        border: Border.all(
                                            color: Colors.green[200]!),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_user,
                                              size: 10, color: Colors.green),
                                          SizedBox(width: 3),
                                          Text('Verified',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              Text(spec,
                                  style: const TextStyle(
                                      color: Color(0xFF00634B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              if (location != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(location,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500])),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stat cards
                    Row(
                      children: [
                        if (rating != null)
                          Expanded(
                              child: _statCard(
                                  Icons.star, 'Rating',
                                  '${(rating as num).toStringAsFixed(1)} ⭐',
                                  Colors.amber)),
                        if (rating != null) const SizedBox(width: 8),
                        if (experience != null)
                          Expanded(
                              child: _statCard(
                                  Icons.work, 'Experience',
                                  '${experience} Yrs',
                                  Colors.blue)),
                        if (experience != null) const SizedBox(width: 8),
                        Expanded(
                            child: _statCard(
                                Icons.access_time, 'Rate',
                                hourlyRate != null
                                    ? '₹$hourlyRate/hr'
                                    : 'On request',
                                Colors.purple)),
                      ],
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ABOUT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[500],
                                    letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text(bio,
                                style: const TextStyle(
                                    fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    if (barReg != null) ...[
                      const SizedBox(height: 12),
                      _detailRow(Icons.military_tech, 'Bar Registration', barReg),
                    ],
                    if (contact != null) ...[
                      const SizedBox(height: 8),
                      _detailRow(Icons.phone, 'Contact', contact,
                          onTap: () => launchUrl(Uri.parse('tel:$contact'))),
                    ],
                    if (lawyerType != null) ...[
                      const SizedBox(height: 8),
                      _detailRow(Icons.work_outline, 'Type', lawyerType),
                    ],
                    const SizedBox(height: 20),
                    // CTA
                    if (_requested)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Request Sent!',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                                Text('Awaiting lawyer confirmation',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _requested = true),
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                              label: Text(
                                  'Connect with ${name.split(' ').first}',
                                  style:
                                      const TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00634B),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.cancel_outlined,
                                  color: Colors.grey[600]),
                              label: Text('Not a good fit',
                                  style: TextStyle(color: Colors.grey[600])),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lawyerAvatar(Map<String, dynamic> l, double radius) {
    final avatarUrl = l['avatar'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey[200]);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE6F0ED),
      child: Icon(Icons.person, size: radius, color: const Color(0xFF00634B)),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.7),
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    final content = Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[400],
                    letterSpacing: 0.8)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─────────────────────────────────────────────────────────────
// SahayakPanel  (same treatment as LawyerPanel)
// ─────────────────────────────────────────────────────────────

class SahayakPanel extends StatelessWidget {
  final List<dynamic> sahayaks;
  const SahayakPanel({super.key, required this.sahayaks});

  void _showProfile(BuildContext context, Map<String, dynamic> s) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SahayakProfileDialog(sahayak: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sahayaks.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Nyay Guides Found',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF13694F))),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sahayaks.length,
              itemBuilder: (context, index) {
                final s = sahayaks[index] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => _showProfile(context, s),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.volunteer_activism,
                              size: 30, color: Colors.green[700]),
                        ),
                        const SizedBox(height: 12),
                        Text(s['name'] ?? 'Guide',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                            s['location'] ??
                                s['occupation'] ??
                                'Community Helper',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _showProfile(context, s),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            minimumSize: const Size(double.infinity, 36),
                          ),
                          child: const Text('View Profile',
                              style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _SahayakProfileDialog extends StatefulWidget {
  final Map<String, dynamic> sahayak;
  const _SahayakProfileDialog({required this.sahayak});

  @override
  State<_SahayakProfileDialog> createState() => _SahayakProfileDialogState();
}

class _SahayakProfileDialogState extends State<_SahayakProfileDialog> {
  bool _connected = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sahayak;
    final name = s['name'] ?? 'Guide';
    final location = s['location'] as String?;
    final occupation = s['occupation'] as String?;
    final bio = s['bio'] as String?;
    final contact = s['contact_number'] as String?;
    final email = s['email'] as String?;
    final rating = s['rating'];
    final casesResolved = s['cases_resolved'];
    final languages = s['languages'];
    final availability = s['availability'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE5EDE9))),
              ),
              child: Row(
                children: [
                  const Text('Nyay Guide Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF13694F),
                          fontSize: 15)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.green[100],
                              child: Icon(Icons.volunteer_activism,
                                  size: 44, color: Colors.green[700]),
                            ),
                            if (availability != null)
                              Positioned(
                                bottom: 3,
                                right: 3,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: availability == 'Available'
                                        ? Colors.green
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900)),
                              if (occupation != null)
                                Text(occupation,
                                    style: const TextStyle(
                                        color: Color(0xFF13694F),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              if (location != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(location,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500])),
                                    ),
                                  ],
                                ),
                              ],
                              if (rating != null || casesResolved != null) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    if (rating != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 13, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                              '${(rating as num).toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber)),
                                        ],
                                      ),
                                    if (casesResolved != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.history,
                                              size: 13,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 2),
                                          Text('$casesResolved cases',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500])),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(bio,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5)),
                    ],
                    if (contact != null || email != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (contact != null)
                            GestureDetector(
                              onTap: () =>
                                  launchUrl(Uri.parse('tel:$contact')),
                              child: _contactChip(Icons.phone, contact),
                            ),
                          if (email != null)
                            GestureDetector(
                              onTap: () =>
                                  launchUrl(Uri.parse('mailto:$email')),
                              child: _contactChip(Icons.email, 'Email'),
                            ),
                        ],
                      ),
                    ],
                    if (languages is List && languages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.language, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Wrap(
                            spacing: 6,
                            children: (languages)
                                .map<Widget>((lang) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(lang.toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700])),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nyay Guides provide free community legal support. '
                              'Your guide can visit your location if needed.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_connected)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Connected! $name will contact you shortly.',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _connected = true),
                          icon: const Icon(Icons.volunteer_activism,
                              color: Colors.white),
                          label: const Text('Ask for Help',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.green[700]),
          const SizedBox(width: 5),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: Colors.green[700])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NodalGuidePanel  (shows a rich overlay modal like the web)
// ─────────────────────────────────────────────────────────────

class NodalGuidePanel extends StatelessWidget {
  final List<dynamic> profiles;
  const NodalGuidePanel({super.key, required this.profiles});

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.account_balance,
                    color: Color(0xFF13694F), size: 18),
                SizedBox(width: 8),
                Text('Gram Nyayalaya Guides Found',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF13694F))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final p = profiles[index] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => _showNodalGuideModal(context, profiles),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.teal[200]!),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal[100],
                          child: Icon(Icons.support_agent,
                              size: 24, color: Colors.teal[700]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p['name'] ?? 'Nodal Guide',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['location'] ?? 'Gram Nyayalaya',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.teal[600],
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNodalGuideModal(
      BuildContext context, List<dynamic> profiles) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _NodalGuideModal(profiles: profiles),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NodalGuide Modal  (mirrors web NodalGuideBrowserPanel)
// ─────────────────────────────────────────────────────────────

class _NodalGuideModal extends StatefulWidget {
  final List<dynamic> profiles;
  const _NodalGuideModal({required this.profiles});

  @override
  State<_NodalGuideModal> createState() => _NodalGuideModalState();
}

class _NodalGuideModalState extends State<_NodalGuideModal> {
  bool _connected = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final guide = widget.profiles.isNotEmpty
        ? widget.profiles.first as Map<String, dynamic>
        : null;

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      backgroundColor: const Color(0xFF1A2E28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0x1AFFFFFF))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2D8A5E), Color(0xFF1D6044)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance,
                        color: Color(0xFFA8F0D0), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gram Nyayalaya',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE8F5F0),
                              fontSize: 16)),
                      Text('Free Local Legal Assistance',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6DB890))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Color(0xFF8BA99E), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (guide == null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance,
                        size: 48, color: Color(0xFF2D5A4E)),
                    const SizedBox(height: 16),
                    const Text(
                      'No Nodal Guide available in your area right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF6B8F80), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check back later or contact your district court.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF4A6B5E), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0x1AFFFFFF)),
                        foregroundColor: const Color(0xFF8BA99E),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guide card
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                _buildGuideAvatar(guide),
                                if (guide['availability'] != null)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            guide['availability'] ==
                                                    'Available'
                                                ? Colors.green
                                                : Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF1A2E28),
                                            width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(guide['name'] ?? 'Nodal Guide',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFE8F5F0))),
                                  Text(
                                      guide['occupation'] ??
                                          'Gram Nyayalaya Officer',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6DB890))),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      if (guide['location'] != null)
                                        _metaItem(
                                            Icons.location_on,
                                            guide['location']),
                                      if (guide['rating'] != null &&
                                          (guide['rating'] as num) > 0)
                                        _metaItem(
                                            Icons.star,
                                            '${(guide['rating'] as num).toStringAsFixed(1)}',
                                            color: Colors.amber),
                                      if (guide['cases_resolved'] != null &&
                                          (guide['cases_resolved'] as num) > 0)
                                        _metaItem(
                                            Icons.history,
                                            '${guide['cases_resolved']} cases'),
                                    ],
                                  ),
                                  if (guide['bio'] != null &&
                                      (guide['bio'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(guide['bio'],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFA0C4B4),
                                            height: 1.5),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (guide['contact_number'] != null)
                                        GestureDetector(
                                          onTap: () => launchUrl(Uri.parse(
                                              'tel:${guide['contact_number']}')),
                                          child: _contactChipDark(
                                              Icons.phone,
                                              guide['contact_number']),
                                        ),
                                      if (guide['email'] != null)
                                        GestureDetector(
                                          onTap: () => launchUrl(Uri.parse(
                                              'mailto:${guide['email']}')),
                                          child: _contactChipDark(
                                              Icons.email, 'Email'),
                                        ),
                                    ],
                                  ),
                                  if (guide['languages'] is List &&
                                      (guide['languages'] as List)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.language,
                                            size: 13,
                                            color: Color(0xFF6B8F80)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            children:
                                                (guide['languages'] as List)
                                                    .map<Widget>((l) =>
                                                        Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal:
                                                                  8,
                                                              vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.06),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.1)),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                              l.toString(),
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      10,
                                                                  color: Color(
                                                                      0xFF8BA99E))),
                                                        ))
                                                    .toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Info banner
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          border: Border.all(
                              color: Colors.teal.withOpacity(0.18)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.account_balance,
                                size: 15, color: Color(0xFF4EAD7E)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  'Gram Nyayalayas provide free legal assistance at the grassroots level. '
                                  'Your guide can visit your location if needed.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8DBBAA),
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      // CTA
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: _connected
                            ? Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  border: Border.all(
                                      color: Colors.green
                                          .withOpacity(0.25)),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF86EFAC),
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                          'Connected! ${guide['name'] ?? 'Guide'} will contact you shortly.',
                                          style: const TextStyle(
                                              color: Color(0xFF86EFAC),
                                              fontSize: 14)),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          setState(
                                              () => _loading = true);
                                          await Future.delayed(
                                              const Duration(
                                                  milliseconds: 800));
                                          if (mounted) {
                                            setState(() {
                                              _loading = false;
                                              _connected = true;
                                            });
                                          }
                                        },
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.account_balance,
                                          color: Color(0xFFC8F0DE)),
                                  label: Text(
                                      _loading
                                          ? 'Connecting...'
                                          : 'Connect with Nodal Guide',
                                      style: const TextStyle(
                                          color: Color(0xFFC8F0DE),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF2D8A5E),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _buildGuideAvatar(Map<String, dynamic> guide) {
    final avatarUrl = guide['avatar'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(avatarUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _defaultGuideAvatar()),
      );
    }
    return _defaultGuideAvatar();
  }

  Widget _defaultGuideAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.support_agent,
          size: 40, color: Color(0xFFA8F0D0)),
    );
  }

  Widget _metaItem(IconData icon, String text,
      {Color color = const Color(0xFF8BA99E)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _contactChipDark(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF7EC9A6)),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF7EC9A6))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AgentChip
// ─────────────────────────────────────────────────────────────

class AgentChip extends StatelessWidget {
  final String agent;
  const AgentChip({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey[100]!;
    Color text = Colors.grey[700]!;
    Color border = Colors.grey[300]!;

    final a = agent.toLowerCase();
    if (a.contains('scam')) {
      bg = Colors.red[50]!; text = Colors.red[700]!; border = Colors.red[200]!;
    } else if (a.contains('civil')) {
      bg = Colors.blue[50]!; text = Colors.blue[700]!; border = Colors.blue[200]!;
    } else if (a.contains('cyber')) {
      bg = Colors.cyan[50]!; text = Colors.cyan[700]!; border = Colors.cyan[200]!;
    } else if (a.contains('domestic')) {
      bg = Colors.purple[50]!; text = Colors.purple[700]!; border = Colors.purple[200]!;
    } else if (a.contains('nodal') || a.contains('nodal_guide')) {
      bg = Colors.teal[50]!; text = Colors.teal[700]!; border = Colors.teal[200]!;
    } else if (a.contains('sahayak')) {
      bg = Colors.green[50]!; text = Colors.green[700]!; border = Colors.green[200]!;
    } else if (a.contains('moderator')) {
      bg = Colors.orange[50]!; text = Colors.orange[700]!; border = Colors.orange[200]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: text, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(agent.toUpperCase(),
              style: TextStyle(
                  color: text,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
