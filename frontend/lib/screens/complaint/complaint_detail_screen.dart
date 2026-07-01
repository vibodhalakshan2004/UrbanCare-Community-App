import 'package:flutter/material.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';

class ComplaintDetailScreen extends StatefulWidget{
  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    required this.complaintRepository,
  });

  final ComplaintModel complaint;
  final ComplaintRepository complaintRepository;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen>{
  late ComplaintModel _complaint;
  bool _loading = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    try{
      final fresh=
        await widget.complaintRepository.getComplaintById(_complaint.complaintId);

      if(!mounted) return;
      setState((){
        _complaint = ComplaintModel(
          complaintId: fresh.complaintId,
          issueType: fresh.issueType.isEmpty ? _complaint.issueType : fresh.issueType,
          description: fresh.description.isEmpty
              ? _complaint.description
              : fresh.description,
          status: fresh.status,
          citizenId: fresh.citizenId ?? _complaint.citizenId,
          locationId: fresh.locationId ?? _complaint.locationId,
          location: _complaint.location ?? fresh.location,
          distanceMeters: _complaint.distanceMeters ?? fresh.distanceMeters,
          primaryImageUrl: fresh.primaryImageUrl ?? _complaint.primaryImageUrl,
        );
      });  
    }catch (_) {
      // keep existing data on detail if fetch fails.
    }finally {
      if(mounted) {
        setState(()=>_loading = false);
      }
    }
  }

  Future<void> _verify({
    required bool isFixed,
    required String successMessage,
  }) async {
    if (_verifying) {
      return;
    }

    setState(()=> _verifying = true);
    try {
      final updated = await widget.complaintRepository.verifyComplaint(
        complaintId: _complaint.complaintId,
        isFixed: isFixed,
      );

      if(!mounted) return;
      setState((){
        _complaint = ComplaintModel(
          complaintId: updated.complaintId,
          issueType:
              updated.issueType.isEmpty ? _complaint.issueType : updated.issueType,
          description:
              updated.description.isEmpty ? _complaint.description : updated.description,
          status: updated.status,
          citizenId: updated.citizenId ?? _complaint.citizenId,
          locationId: updated.locationId ?? _complaint.locationId,
          location: _complaint.location,
          distanceMeters: _complaint.distanceMeters,
          primaryImageUrl: _complaint.primaryImageUrl,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );   
    }catch(e){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );  
    }finally {
      if(mounted){
        setState(()=> _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_complaint.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: _complaint.primaryImageUrl == null
                      ? Text(
                          _complaint.emoji,
                          style: const TextStyle(fontSize: 56),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            _complaint.primaryImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Text(
                              _complaint.emoji,
                              style: const TextStyle(fontSize: 56),
                            ),
                          ),
                       ),  
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _complaint.displayTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _complaint.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _complaint.description,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    _complaint.location?.address ??
                        '📍 ${_complaint.location?.latitude.toStringAsFixed(5) ?? '-'}, '
                            '${_complaint.location?.longitude.toStringAsFixed(5) ?? '-'}',
                    style: const TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Confirm current status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: '😐 Still There',
                  loading: _verifying,
                  isSecondary: true,
                  onPressed: () => _verify(
                    isFixed: false,
                    successMessage: 'Marked as still there.',
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: '✅ It\'s Fixed!',
                  loading: _verifying,
                  onPressed: () => _verify(
                    isFixed: true,
                    successMessage: 'Marked as fixed. Thanks!',
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: '⚠️ Got Worse',
                  loading: _verifying,
                  isSecondary: true,
                  onPressed: () => _verify(
                    isFixed: false,
                    successMessage: 'Marked as getting worse.',
                  ),
                ),
              ],
          ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'fixed' || normalized == 'closed' || normalized == 'resolved'){
      return const Color(0xFF4ADE80);
    }
    if(normalized == 'in_progress' || normalized == 'assigned'){
      return const Color(0xFF60A5FA);
    }
    return const Color(0xFFFBBF24);
  }
}