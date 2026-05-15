import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../data/pubs_repository.dart';
import '../domain/pub_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class PubPlayerScreen extends ConsumerStatefulWidget {
  final String pubId;
  const PubPlayerScreen({super.key, required this.pubId});

  @override
  ConsumerState<PubPlayerScreen> createState() => _PubPlayerScreenState();
}

class _PubPlayerScreenState extends ConsumerState<PubPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  PubModel? _pub;

  // États
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPub();
  }

  Future<void> _loadPub() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(pubsRepositoryProvider);
      final pub = await repo.getPub(widget.pubId);
      if (!mounted) return;

      if (pub == null) {
        setState(() {
          _error = 'Publicité introuvable.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _pub = pub);

      if (pub.videoUrl.isEmpty) {
        setState(() {
          _error = 'Aucune vidéo associée à cette publicité.';
          _isLoading = false;
        });
        return;
      }

      // Initialise le player vidéo
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(pub.videoUrl));
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      _videoController = controller;
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        showOptions: false,
        // Retour en portrait après plein écran
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        // Autorise landscape en plein écran
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, msg) => _VideoError(
          message: msg,
          onRetry: _reloadVideo,
        ),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la vidéo.\n${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadVideo() async {
    _disposeControllers();
    await _loadPub();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    // Restaure l'orientation portrait à la fermeture
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _pub?.title ?? 'Publicité',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_pub != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Partager',
              onPressed: _share,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone vidéo 16/9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayer(),
          ),

          // Infos de la pub
          if (_pub != null)
            Expanded(
              child: _PubInfoPanel(pub: _pub!),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Chargement de la vidéo…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _VideoError(message: _error!, onRetry: _reloadVideo);
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const SizedBox.shrink();
  }

  void _share() {
    if (_pub == null) return;
    final text = [
      _pub!.title,
      if (_pub!.channels.isNotEmpty)
        'Diffusé sur ${_pub!.channels.join(', ')}',
      'Depuis ${Formatters.formatDate(_pub!.broadcastDate)}',
    ].join('\n');
    Share.share(text, subject: _pub!.title);
  }
}

// ── Panneau d'infos ───────────────────────────────────────────────────────────

class _PubInfoPanel extends StatelessWidget {
  final PubModel pub;
  const _PubInfoPanel({required this.pub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + badge diffusion
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(pub.title, style: theme.textTheme.headlineSmall),
                ),
                if (pub.isActive) ...[
                  const SizedBox(width: 10),
                  _LiveBadge(),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Chaînes
            if (pub.channels.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.tv_outlined,
                label: 'Chaînes de diffusion',
                value: pub.channels.join(' · '),
              ),
              const SizedBox(height: 12),
            ],

            // Date de diffusion
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Depuis le',
              value: Formatters.formatDate(pub.broadcastDate),
            ),
            const SizedBox(height: 20),

            // Bouton partager
            OutlinedButton.icon(
              onPressed: () {
                final text = [
                  pub.title,
                  if (pub.channels.isNotEmpty)
                    'Diffusé sur ${pub.channels.join(', ')}',
                ].join('\n');
                Share.share(text, subject: pub.title);
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Partager cette publicité'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'EN DIFFUSION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Erreur vidéo ──────────────────────────────────────────────────────────────

class _VideoError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _VideoError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined,
                  size: 56, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
