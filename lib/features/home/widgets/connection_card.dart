import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/esp32_service.dart';

class ConnectionCard extends StatefulWidget {
  final Esp32Service service;

  const ConnectionCard({
    super.key,
    required this.service,
  });

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard> {
  late TextEditingController _ipController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.service.currentIp);
  }

  @override
  void didUpdateWidget(covariant ConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ipController.text != widget.service.currentIp &&
        widget.service.currentIp.isNotEmpty) {
      _ipController.text = widget.service.currentIp;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      widget.service.connect(_ipController.text.trim());
    }
  }

  void _handleDisconnect() {
    FocusScope.of(context).unfocus();
    widget.service.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.service.isOnline;
    final isConnecting = widget.service.isConnecting;
    final errorMessage = widget.service.errorMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.router_outlined,
                      size: 18,
                      color: AppColors.tealPrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Koneksi ESP32',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Mode Demo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 24,
                      width: 40,
                      child: Switch(
                        value: widget.service.isSimulationMode,
                        activeThumbColor: AppColors.tealPrimary,
                        activeTrackColor: AppColors.tealLight,
                        onChanged: (val) {
                          widget.service.toggleSimulation(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ipController,
              enabled: !isOnline && !isConnecting,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Alamat IP ESP32',
                hintText: 'Contoh: 192.168.1.10',
                prefixIcon: const Icon(
                  Icons.settings_ethernet_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _ipController.text.isNotEmpty && !isOnline
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _ipController.clear(),
                      )
                    : null,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan alamat IP ESP32';
                }
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (!isOnline) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnecting ? null : _handleConnect,
                      icon: isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link_rounded, size: 18),
                      label: Text(
                        isConnecting ? 'Menghubungkan...' : 'Connect',
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleDisconnect,
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => widget.service.refresh(),
                    tooltip: 'Perbarui Data',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.tealLight,
                      foregroundColor: AppColors.tealDark,
                      minimumSize: const Size(46, 46),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
