import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/contest_entry.dart';
import '../services/sheets_service.dart';
import 'presenter_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  final PresenterConfig config;
  final VoidCallback onComplete;
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

  List<bool> _rowVisible = [];

  static const _rankColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  // Codemagic brand palette
  static const _blue = Color(0xFF0031EA);
  static const _cyan = Color(0xFF00CEFF);
  static const _orange = Color(0xFFFF9100);
  static const _red = Color(0xFFEC0C43);

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
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _rowVisible = List.filled(entries.length, false);
      });
      _animateRows(entries.length);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _animateRows(int count) async {
    for (int i = 0; i < count; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() => _rowVisible[i] = true);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          _buildHeader(context),
          _buildDivider(),
          Expanded(child: _buildContent()),
          _buildCountdown(),
        ],
      ),
    );
  }

  // 4px gradient bar — the brand signature red-to-orange stripe
  Widget _buildTopBar() {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_red, _orange]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEADERBOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'FASTEST LEGO BUILDERS',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          SvgPicture.asset(
            'assets/images/codemagic_logo.svg',
            height: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue, _cyan, _blue],
        ),
      ),
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(48, 14, 48, 8),
      itemCount: _entries!.length,
      itemBuilder: (_, i) => _buildRow(i, _entries![i]),
    );
  }

  Widget _buildRow(int index, ContestEntry entry) {
    final visible = index < _rowVisible.length && _rowVisible[index];

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0.04, 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: index < 3
              ? _buildTop3Row(index, entry)
              : _buildRegularRow(index, entry),
        ),
      ),
    );
  }

  Widget _buildTop3Row(int index, ContestEntry entry) {
    final rankColor = _rankColors[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: rankColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: rankColor, width: 3)),
      ),
      child: Row(
        children: [
          _RankBadge(rank: index + 1, color: rankColor, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.formattedTime,
            style: const TextStyle(
              color: _cyan,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularRow(int index, ContestEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _RankBadge(rank: index + 1, color: Colors.white24, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.formattedTime,
            style: const TextStyle(
              color: _cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final progress = _secondsRemaining / widget.config.scoreboardDuration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 10, 48, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Resuming in $_secondsRemaining s',
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 3,
              color: Colors.white12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_blue, _cyan]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  final double size;

  const _RankBadge({required this.rank, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // ignore: deprecated_member_use
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontSize: size * 0.42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
