import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/admin_provider.dart';

class AdminKYCVerificationScreen extends StatefulWidget {
  const AdminKYCVerificationScreen({super.key});

  @override
  State<AdminKYCVerificationScreen> createState() => _AdminKYCVerificationScreenState();
}

class _AdminKYCVerificationScreenState extends State<AdminKYCVerificationScreen> {
  String _selectedFilter = 'pending'; // 'pending', 'approved', 'rejected', 'all'

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allSubmissions = admin.kycSubmissions;
    final filtered = _selectedFilter == 'all'
        ? allSubmissions
        : allSubmissions.where((k) => k.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('KYC Compliance & Verification', style: TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary)),
        backgroundColor: KivoDarkTheme.surface,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: KivoDarkTheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('pending', 'Pending (${admin.pendingKYCs.length})', Icons.pending_actions, KivoDarkTheme.accentAmber),
                  const SizedBox(width: 8),
                  _buildTabChip('approved', 'Approved', Icons.verified, KivoDarkTheme.primaryEmerald),
                  const SizedBox(width: 8),
                  _buildTabChip('rejected', 'Rejected', Icons.cancel, KivoDarkTheme.accentRose),
                  const SizedBox(width: 8),
                  _buildTabChip('all', 'All Submissions (${allSubmissions.length})', Icons.folder, KivoDarkTheme.accentCyan),
                ],
              ),
            ),
          ),

          // Submissions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text('No $_selectedFilter KYC submissions', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _KYCCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label, IconData icon, Color activeColor) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : KivoDarkTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : KivoDarkTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : KivoDarkTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : KivoDarkTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KYCCard extends StatelessWidget {
  final KYCSubmission item;
  const _KYCCard({required this.item});

  void _showDocumentViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.documentType, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.documentUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    height: 200,
                    color: Colors.white10,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Submitted: ${item.submittedAt.toLocal()}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = item.accountType == 'business';
    final isPending = item.status == 'pending';
    final isApproved = item.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KivoDarkTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? KivoDarkTheme.accentAmber.withOpacity(0.4)
              : (isApproved ? KivoDarkTheme.primaryEmerald.withOpacity(0.3) : KivoDarkTheme.accentRose.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Account Type Badge, Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBusiness ? KivoDarkTheme.accentCyan.withOpacity(0.15) : KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isBusiness ? Icons.business : Icons.person, color: isBusiness ? KivoDarkTheme.accentCyan : KivoDarkTheme.primaryEmerald, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBusiness ? (item.businessName ?? item.userName) : item.userName,
                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      isBusiness ? 'Business Account • ${item.userName}' : 'Individual Citizen Account',
                      style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? KivoDarkTheme.primaryEmerald.withOpacity(0.2)
                      : (isPending ? KivoDarkTheme.accentAmber.withOpacity(0.2) : KivoDarkTheme.accentRose.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: isApproved ? KivoDarkTheme.primaryEmerald : (isPending ? KivoDarkTheme.accentAmber : KivoDarkTheme.accentRose),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Details Matrix
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildRow('Taxpayer Reg. Number (TRN):', item.trnNumber),
                if (isBusiness && item.businessRegNumber != null) ...[
                  const SizedBox(height: 6),
                  _buildRow('COJ Registration Number:', item.businessRegNumber!),
                ],
                const SizedBox(height: 6),
                _buildRow('Applicant Email:', item.userEmail),
                const SizedBox(height: 6),
                _buildRow('Document Provided:', item.documentType),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Document Preview Button
          OutlinedButton.icon(
            onPressed: () => _showDocumentViewer(context),
            icon: const Icon(Icons.description, size: 16, color: KivoDarkTheme.accentCyan),
            label: const Text('View Uploaded Certificates & Government ID', style: TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KivoDarkTheme.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AdminProvider>().reviewKYC(kycId: item.id, approve: false, note: 'Documentation mismatch - please re-upload.'),
                    icon: const Icon(Icons.close, color: KivoDarkTheme.accentRose, size: 18),
                    label: const Text('Reject KYC', style: TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KivoDarkTheme.accentRose),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<AdminProvider>().reviewKYC(kycId: item.id, approve: true, note: 'Verified by Administrator'),
                    icon: const Icon(Icons.verified, color: Colors.black, size: 18),
                    label: const Text('Approve KYC', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KivoDarkTheme.primaryEmerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
