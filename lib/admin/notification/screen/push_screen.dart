import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class PushScreen extends StatefulWidget {
  const PushScreen({super.key});

  @override
  State<PushScreen> createState() => _PushScreenState();
}

class _PushScreenState extends State<PushScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _audience = 'all';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Push Notification',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),

                const SizedBox(height: 16),

                /// Body
                TextField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                  ),
                ),

                const SizedBox(height: 20),

                /// Audience
                Text(
                  'Audience',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _audienceChip('all', 'All Users'),
                    const SizedBox(width: 10),
                    _audienceChip('anonymous', 'Anonymous'),
                    const SizedBox(width: 10),
                    _audienceChip('real', 'Real Users'),
                  ],
                ),

                const Spacer(),

                /// Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendNotification,
                    child: _isSending
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Send Notification'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _audienceChip(String value, String label) {
    final isSelected = _audience == value;

    return GestureDetector(
      onTap: () {
        setState(() => _audience = value);
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and body')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // TODO: Implement actual push logic
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent')),
      );

      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send')),
      );
    }

    setState(() => _isSending = false);
  }
}