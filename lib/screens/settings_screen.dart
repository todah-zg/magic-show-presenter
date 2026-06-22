import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presenter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Keys used to read/write values in SharedPreferences
  static const _keyVideoPath = 'video_path';
  static const _keyCredentials = 'credentials_path';
  static const _keySheetId = 'sheet_id';
  static const _keyDuration = 'scoreboard_duration';

  // Controllers bridge text fields to our state.
  // They are created once and disposed when the widget leaves the tree.
  final _sheetIdController = TextEditingController();
  final _durationController = TextEditingController();

  String? _videoPath;
  String? _credentialsPath;
  bool _loading = true;

  // initState() is Flutter's equivalent of a constructor for State objects.
  // It runs once, right after the widget is inserted into the widget tree.
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // dispose() is the destructor — called when the widget leaves the tree.
  // Controllers must be disposed here or they will leak memory.
  @override
  void dispose() {
    _sheetIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // SharedPreferences.getInstance() is asynchronous — it reads from disk.
  // We await it, then call setState() so Flutter re-renders with the loaded data.
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _videoPath = prefs.getString(_keyVideoPath);
      _credentialsPath = prefs.getString(_keyCredentials);
      _sheetIdController.text = prefs.getString(_keySheetId) ?? '';
      _durationController.text =
          (prefs.getInt(_keyDuration) ?? 30).toString();
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_videoPath != null) await prefs.setString(_keyVideoPath, _videoPath!);
    if (_credentialsPath != null) {
      await prefs.setString(_keyCredentials, _credentialsPath!);
    }
    await prefs.setString(_keySheetId, _sheetIdController.text.trim());
    await prefs.setInt(
      _keyDuration,
      int.tryParse(_durationController.text) ?? 30,
    );
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _videoPath = result.files.single.path);
    }
  }

  Future<void> _pickCredentialsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _credentialsPath = result.files.single.path);
    }
  }

  // The Start button is only enabled when all four fields have valid values.
  bool get _canStart {
    return _videoPath != null &&
        _credentialsPath != null &&
        _sheetIdController.text.trim().isNotEmpty &&
        (int.tryParse(_durationController.text) ?? 0) > 0;
  }

  Future<void> _start() async {
    await _savePreferences();
    // mounted check is required after any await — the user might have closed
    // the window while the prefs write was in flight.
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresenterScreen(
          config: PresenterConfig(
            videoPath: _videoPath!,
            credentialsPath: _credentialsPath!,
            sheetId: _sheetIdController.text.trim(),
            scoreboardDuration: int.tryParse(_durationController.text) ?? 30,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 520,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildFileField(
                  label: 'Demo video',
                  path: _videoPath,
                  onPick: _pickVideoFile,
                ),
                const SizedBox(height: 16),
                _buildFileField(
                  label: 'Service account credentials (JSON)',
                  path: _credentialsPath,
                  onPick: _pickCredentialsFile,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _sheetIdController,
                  label: 'Google Sheet ID',
                  hint: 'Paste the long ID from the sheet URL',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _durationController,
                  label: 'Scoreboard duration (seconds)',
                  hint: '30',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: _canStart ? _start : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Magic Show Presenter',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure before starting',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildFileField({
    required String label,
    required String? path,
    required VoidCallback onPick,
  }) {
    final hasFile = path != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasFile
                        ? const Color(0xFF0031EA)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  path != null ? path.split('/').last : 'No file selected',
                  style: TextStyle(
                    color: hasFile ? Colors.white : Colors.white38,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onPick,
              child: const Text('Browse'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          // Rebuild the screen whenever text changes so _canStart recomputes.
          onChanged: (_) => setState(() {}),
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0031EA)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
