import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contest_entry.dart';
import '../services/sheets_service.dart';
import 'presenter_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  final PresenterConfig config;
  final VoidCallback onComplete;
  // Pre-fetched by PresenterScreen while the video was playing.
  // Awaiting an already-completed future returns instantly.
  final Future<List<ContestEntry>>? scoresFuture;

  const ScoreboardScreen({
    super.key,
    required this.config,
    required this.onComplete,
    this.scoresFuture,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  List<ContestEntry>? _entries;
  String? _error;
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.config.scoreboardDuration;
    _fetchData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final entries = await (widget.scoresFuture ??
          SheetsService.fetchTopTen(
            credentialsPath: widget.config.credentialsPath,
            sheetId: widget.config.sheetId,
          ));
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        _countdownTimer?.cancel();
        widget.onComplete();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
            _buildCountdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: Color(0xFFFF9100), size: 36),
        const SizedBox(width: 16),
        Text(
          'LEADERBOARD',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        Text(
          'Fastest Lego Builders',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load scores',
              style: TextStyle(color: Colors.white38, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries!.isEmpty) {
      return const Center(
        child: Text(
          'No entries yet',
          style: TextStyle(color: Colors.white38, fontSize: 24),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < _entries!.length; i++)
          _buildRow(i, _entries![i]),
      ],
    );
  }

  Widget _buildRow(int index, ContestEntry entry) {
    final rankColor = switch (index) {
      0 => const Color(0xFFFFD700), // gold
      1 => const Color(0xFFC0C0C0), // silver
      2 => const Color(0xFFCD7F32), // bronze
      _ => Colors.white38,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: rankColor,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 30),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.formattedTime,
            style: const TextStyle(
              color: Color(0xFF00CEFF), // Dash Aqua
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final progress = _secondsRemaining / widget.config.scoreboardDuration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 16),
        Text(
          'Resuming in $_secondsRemaining s',
          style: const TextStyle(color: Colors.white24, fontSize: 13),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0031EA)),
          ),
        ),
      ],
    );
  }
}
