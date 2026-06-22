import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/contest_entry.dart';
import '../services/sheets_service.dart';
import 'scoreboard_screen.dart';

enum _PresenterMode { video, scoreboard }

// Typed bag of everything the settings screen collected.
// Passing it as a constructor arg keeps PresenterScreen free of SharedPreferences.
class PresenterConfig {
  final String videoPath;
  final String credentialsPath;
  final String sheetId;
  final int scoreboardDuration;
  final int prizeCount;

  const PresenterConfig({
    required this.videoPath,
    required this.credentialsPath,
    required this.sheetId,
    required this.scoreboardDuration,
    required this.prizeCount,
  });
}

class PresenterScreen extends StatefulWidget {
  final PresenterConfig config;

  const PresenterScreen({super.key, required this.config});

  @override
  State<PresenterScreen> createState() => _PresenterScreenState();
}

class _PresenterScreenState extends State<PresenterScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _videoError;
  // Guards against the listener firing twice at video end (e.g. during seek).
  bool _transitioning = false;
  _PresenterMode _mode = _PresenterMode.video;
  // Pre-fetched while the video plays so the scoreboard appears without delay.
  Future<List<ContestEntry>>? _scoresFuture;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.file(
        File(widget.config.videoPath),
      );

      // initialize() reads the file header and makes value.size / value.duration
      // available. Nothing plays yet.
      await _controller.initialize();

      // Attach the listener before play() so we never miss the completion event.
      _controller.addListener(_onVideoUpdate);

      if (!mounted) return;
      setState(() => _initialized = true);

      // Kick off the first scores fetch now — the video will play for long
      // enough that the result is ready before the scoreboard needs it.
      _scoresFuture = SheetsService.fetchTopTen(
        credentialsPath: widget.config.credentialsPath,
        sheetId: widget.config.sheetId,
      );

      await _controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _videoError = e.toString());
    }
  }

  void _onVideoUpdate() {
    if (_transitioning) return;
    if (_controller.value.isCompleted) {
      _transitioning = true;
      _onVideoComplete();
    }
  }

  void _onVideoComplete() {
    setState(() => _mode = _PresenterMode.scoreboard);
  }

  void _onScoreboardComplete() {
    // Fire-and-forget: the async work inside updates state when ready.
    _resumeVideo();
  }

  Future<void> _resumeVideo() async {
    // Seek while the scoreboard is still visible so the first video frame is
    // ready the instant we switch back — no flash of the last frame.
    await _controller.seekTo(Duration.zero);
    if (!mounted) return;
    // Start the next fetch immediately so data is ready for the next cycle.
    _scoresFuture = SheetsService.fetchTopTen(
      credentialsPath: widget.config.credentialsPath,
      sheetId: widget.config.sheetId,
    );
    setState(() {
      _mode = _PresenterMode.video;
      _transitioning = false;
    });
    await _controller.play();
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _PresenterMode.scoreboard) {
      return ScoreboardScreen(
        config: widget.config,
        scoresFuture: _scoresFuture,
        onComplete: _onScoreboardComplete,
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoError != null
          ? _buildError()
          : _initialized
              ? _buildVideo()
              : _buildLoading(),
    );
  }

  Widget _buildVideo() {
    return SizedBox.expand(
      child: FittedBox(
        // BoxFit.contain keeps the full frame visible (letterboxed).
        // Use BoxFit.cover if you'd rather fill the screen and crop edges.
        fit: BoxFit.contain,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading video…', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Could not load video',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _videoError ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to settings'),
          ),
        ],
      ),
    );
  }
}
