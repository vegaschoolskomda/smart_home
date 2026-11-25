import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';

class NotificationHistorySection extends StatefulWidget {
  const NotificationHistorySection({super.key});

  @override
  State<NotificationHistorySection> createState() =>
      _NotificationHistorySectionState();
}

class _NotificationHistorySectionState extends State<NotificationHistorySection> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await AppDatabase.instance.getAllNotifications(limit: 50);
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await AppDatabase.instance.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus seluruh riwayat notifikasi lokal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.instance.clearAllNotifications();
      _loadNotifications();
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationService.instance.triggerAlert(
      title: 'Uji Coba Notifikasi',
      message: 'Sistem notifikasi lokal Smart Home berfungsi dengan baik.',
      type: 'system',
      force: true,
    );
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi uji coba berhasil dikirim.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: AppColors.tealPrimary),
                SizedBox(width: 8),
                Text(
                  '4. Notification History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Uji Notifikasi',
                  icon: const Icon(Icons.notification_add_outlined, size: 20),
                  onPressed: _sendTestNotification,
                ),
                if (_notifications.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (val) {
                      if (val == 'read_all') _markAllAsRead();
                      if (val == 'clear_all') _clearAll();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'read_all',
                        child: Text('Tandai Semua Dibaca'),
                      ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Text(
                          'Hapus Semua',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_notifications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 36,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 8),
                Text(
                  'Belum ada riwayat notifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Peringatan otomatis sensor dan tamu akan tersimpan di sini',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _notifications[index];
              return _buildNotificationItem(item);
            },
          ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item.type) {
      case 'visitor':
        icon = Icons.person_pin_circle_outlined;
        iconColor = AppColors.warning;
        iconBg = AppColors.warningLight;
        break;
      case 'temperature':
        icon = Icons.thermostat_rounded;
        iconColor = AppColors.danger;
        iconBg = AppColors.dangerLight;
        break;
      case 'gas':
        icon = Icons.local_fire_department_outlined;
        iconColor = AppColors.danger;
        iconBg = AppColors.dangerLight;
        break;
      case 'rain':
        icon = Icons.thunderstorm_outlined;
        iconColor = AppColors.tealDark;
        iconBg = AppColors.tealLight;
        break;
      case 'system':
      default:
        icon = Icons.notifications_active_outlined;
        iconColor = AppColors.tealDark;
        iconBg = AppColors.tealLight;
        break;
    }

    final date = DateFormatter.parseIso(item.createdAt);
    final timeStr = date != null ? DateFormatter.formatRelative(date) : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead == 1 ? AppColors.surface : AppColors.tealLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead == 1 ? AppColors.cardBorder : AppColors.tealPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.isRead == 1
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (item.isRead == 0) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 16),
              tooltip: 'Tandai Dibaca',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                if (item.id != null) {
                  await AppDatabase.instance.markAsRead(item.id!);
                  _loadNotifications();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
