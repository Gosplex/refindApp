import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import '../../../core/theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _androidVersionController = TextEditingController();
  final _iosVersionController = TextEditingController();

  final HtmlEditorController _androidHtmlController = HtmlEditorController();
  final HtmlEditorController _iosHtmlController = HtmlEditorController();

  bool _forceUpdate = false;
  bool _isSaving = false;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _firestore
        .collection('app_config')
        .doc('update_config')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    _androidVersionController.text = data['android_version'].toString() ?? '';
    _iosVersionController.text = data['ios_version'].toString() ?? '';
    _forceUpdate = data['force_update'] ?? false;

    _androidHtmlController.setText(data['android_update_note'] ?? '');
    _iosHtmlController.setText(data['ios_update_note'] ?? '');

    setState(() {});
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final androidNote = await _androidHtmlController.getText();
      final iosNote = await _iosHtmlController.getText();

      await _firestore.collection('app_config').doc('update_config').set({
        'android_version': int.parse(_androidVersionController.text.trim()),
        'ios_version': int.parse(_iosVersionController.text.trim()),
        'android_update_note': androidNote,
        'ios_update_note': iosNote,
        'force_update': _forceUpdate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),

        const SizedBox(height: 16),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// ANDROID
                  _card(context, 'Android', [
                    _textField(_androidVersionController, 'Version'),

                    const SizedBox(height: 12),

                    HtmlEditor(
                      controller: _androidHtmlController,
                      htmlEditorOptions: const HtmlEditorOptions(
                        hint: "Android update note...",
                      ),
                      htmlToolbarOptions: const HtmlToolbarOptions(
                        defaultToolbarButtons: [
                          FontButtons(),
                          ColorButtons(),
                          ListButtons(),
                          ParagraphButtons(),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  /// IOS
                  _card(context, 'iOS', [
                    _textField(_iosVersionController, 'Version'),

                    const SizedBox(height: 12),

                    HtmlEditor(
                      controller: _iosHtmlController,
                      htmlEditorOptions: const HtmlEditorOptions(
                        hint: "iOS update note...",
                      ),
                      htmlToolbarOptions: const HtmlToolbarOptions(
                        defaultToolbarButtons: [
                          FontButtons(),
                          ColorButtons(),
                          ListButtons(),
                          ParagraphButtons(),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  /// GENERAL
                  _card(context, 'General', [
                    Row(
                      children: [
                        const Text('Force Update'),
                        const Spacer(),
                        Switch(
                          value: _forceUpdate,
                          onChanged: (val) {
                            setState(() => _forceUpdate = val);
                          },
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Settings'),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: double.infinity, // 🔥 FULL WIDTH
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}
