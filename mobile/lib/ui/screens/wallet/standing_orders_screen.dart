import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/recurring_transfer_model.dart';
import '../../../core/services/recurring_transfer_service.dart';

class StandingOrdersScreen extends StatelessWidget {
  const StandingOrdersScreen({Key? key}) : super(key: key);

  void _showCreateScheduleModal(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    RecurringFrequency selectedFreq = RecurringFrequency.fortnightly;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Standing Order',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Recipient Name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Recipient Name (e.g. Mom, Landlord, Helper)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF101726),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Recipient Identifier (Email / Handle)
                TextField(
                  controller: idController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Recipient Email or Kivo ID',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF101726),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount (JMD)
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount (JMD \$)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixText: 'JMD \$ ',
                    prefixStyle: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF101726),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Frequency Selector (Daily, Weekly, Fortnightly, Monthly)
                const Text('Transfer Frequency:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FrequencyChip(
                      label: 'Daily',
                      isSelected: selectedFreq == RecurringFrequency.daily,
                      onTap: () => setModalState(() => selectedFreq = RecurringFrequency.daily),
                    ),
                    _FrequencyChip(
                      label: 'Weekly',
                      isSelected: selectedFreq == RecurringFrequency.weekly,
                      onTap: () => setModalState(() => selectedFreq = RecurringFrequency.weekly),
                    ),
                    _FrequencyChip(
                      label: 'Fortnightly (Every 2 Wks)',
                      isSelected: selectedFreq == RecurringFrequency.fortnightly,
                      onTap: () => setModalState(() => selectedFreq = RecurringFrequency.fortnightly),
                    ),
                    _FrequencyChip(
                      label: 'Monthly',
                      isSelected: selectedFreq == RecurringFrequency.monthly,
                      onTap: () => setModalState(() => selectedFreq = RecurringFrequency.monthly),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Note
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Memo / Reference (Optional)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF101726),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final id = idController.text.trim();
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    if (name.isEmpty || id.isEmpty || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    await context.read<RecurringTransferService>().createSchedule(
                      recipientIdentifier: id,
                      recipientName: name,
                      amount: amt,
                      frequency: selectedFreq,
                      startDate: selectedDate,
                      note: noteController.text.trim(),
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF00C853),
                        content: Text('Standing Order for \$${amt.toStringAsFixed(0)} JMD scheduled! 🇯🇲'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Schedule Standing Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecurringTransferService>();
    final schedules = service.schedules;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        title: const Text(
          'Standing Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateScheduleModal(context),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_alarm),
        label: const Text('New Standing Order', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: schedules.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, i) {
                final s = schedules[i];
                return _StandingOrderCard(schedule: s);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141E33), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_send, color: Color(0xFFFFD700), size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Automatic Standing Orders 🇯🇲',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Set up recurring payments that execute automatically from your Kivo Wallet or Lynk Jam-Dex rail.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateScheduleModal(context),
                  icon: const Icon(Icons.add_alarm, color: Colors.black),
                  label: const Text('Create Standing Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Common Standing Order Presets',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPresetTile(
            title: 'Fortnightly Family Allowance',
            subtitle: 'Auto-transfer to family every two weeks',
            icon: Icons.family_restroom,
            color: const Color(0xFF00E676),
            onTap: () => _showCreateScheduleModal(context),
          ),
          _buildPresetTile(
            title: 'Monthly Rent / Landlord',
            subtitle: 'Scheduled apartment rent on the 1st of every month',
            icon: Icons.home_work,
            color: const Color(0xFF00B0FF),
            onTap: () => _showCreateScheduleModal(context),
          ),
          _buildPresetTile(
            title: 'Weekly Helper / Staff Wages',
            subtitle: 'Automatic wage payments every Friday',
            icon: Icons.badge,
            color: Colors.amberAccent,
            onTap: () => _showCreateScheduleModal(context),
          ),
          _buildPresetTile(
            title: 'Utility & Internet Bills',
            subtitle: 'Scheduled recurring JPS / Flow / Digicel bill pay',
            icon: Icons.receipt_long,
            color: Colors.purpleAccent,
            onTap: () => _showCreateScheduleModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101726),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700), size: 20),
          ],
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF101726),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StandingOrderCard extends StatelessWidget {
  final RecurringTransferModel schedule;
  const _StandingOrderCard({Key? key, required this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = schedule.status == RecurringStatus.active;
    final isPaused = schedule.status == RecurringStatus.paused;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFFFD700).withOpacity(0.3) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                schedule.recipientName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'JMD \$${schedule.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            schedule.recipientIdentifier,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (schedule.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Memo: ${schedule.note}',
              style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const Divider(color: Colors.white12, height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.frequencyLabel,
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Paused',
                  style: TextStyle(color: isActive ? Colors.greenAccent : Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                'Next: ${_formatDate(schedule.nextExecutionDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.read<RecurringTransferService>().toggleScheduleStatus(schedule.scheduleId),
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 16, color: Colors.white70),
                label: Text(isPaused ? 'Resume' : 'Pause', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF141E33),
                      title: const Text('Cancel Standing Order?', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'Are you sure you want to cancel automatic recurring transfers of \$${schedule.amount.toStringAsFixed(0)} JMD to ${schedule.recipientName}?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Keep', style: TextStyle(color: Colors.white60))),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dCtx);
                            context.read<RecurringTransferService>().cancelSchedule(schedule.scheduleId);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Cancel Order'),
                        )
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
