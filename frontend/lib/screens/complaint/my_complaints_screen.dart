import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/screens/complaint/complaint_detail_screen.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({
    super.key,
    required this.complaintRepository,
  });

  final ComplaintRepository complaintRepository;

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  bool _loading = true;
  String? _error;
  List<ComplaintModel> _complaints = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.complaintRepository.getMyComplaints();
      if (!mounted) return;
      setState(() => _complaints = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openComplaint(ComplaintModel complaint) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          complaint: complaint,
          complaintRepository: widget.complaintRepository,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Reports',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All complaints you have submitted.',
                      style: TextStyle(color: context.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_complaints.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.fill08,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports yet',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your submitted complaints will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final complaint = _complaints[index];
                      return Column(
                        children: [
                          _MyComplaintCard(
                            complaint: complaint,
                            onTap: () => _openComplaint(complaint),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                    childCount: _complaints.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MyComplaintCard extends StatelessWidget {
  const _MyComplaintCard({required this.complaint, this.onTap});

  final ComplaintModel complaint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final isResolved = complaint.isResolved;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: context.fill04,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isResolved
                ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                : context.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with emoji + title + status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.fill08,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(complaint.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                complaint.displayTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                _displayStatus(complaint.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.shortDescription,
                          style: TextStyle(
                            color: context.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Authority Fixed banner
            if (isResolved)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Authorities have fixed this issue',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Reaction counts row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  _reactionChip(
                    icon: Icons.thumb_up_outlined,
                    label: '${complaint.verificationCount} Confirmed fixed',
                    color: const Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 8),
                  _reactionChip(
                    icon: Icons.warning_amber_rounded,
                    label: '${complaint.notFixedCount} Still there',
                    color: const Color(0xFFFBBF24),
                  ),
                ],
              ),
            ),

            // Address
            if (complaint.location?.address != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: context.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.location!.address!,
                        style: TextStyle(
                          color: context.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: context.onSurfaceVariant),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reactionChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _displayStatus(String status) {
    const map = {
      'created': 'Created',
      'verified': 'Verified',
      'assigned': 'Assigned',
      'in_progress': 'In Progress',
      'fixed': 'Fixed ✅',
      'closed': 'Closed',
      'rejected': 'Rejected',
      'pending': 'Pending',
    };
    return map[status.toLowerCase()] ?? status;
  }

  Color _statusColor(String status) {
    final n = status.toLowerCase();
    if (n == 'fixed' || n == 'closed' || n == 'resolved') return const Color(0xFF4ADE80);
    if (n == 'in_progress' || n == 'assigned') return const Color(0xFF60A5FA);
    return const Color(0xFFFBBF24);
  }
}
