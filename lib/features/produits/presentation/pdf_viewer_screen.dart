import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String? _error;
  double _downloadProgress = 0;
  bool _isDownloading = true;

  // Contrôleur PDF pour navigation pages
  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _downloadProgress = 0;
    });

    try {
      final dir = await getTemporaryDirectory();
      // Nom de fichier dérivé de l'URL pour cache local
      final fileName =
          'eacademia_${widget.url.hashCode.abs()}.pdf';
      final file = File('${dir.path}/$fileName');

      // Si déjà en cache → pas de re-téléchargement
      if (!file.existsSync()) {
        await Dio().download(
          widget.url,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _downloadProgress = received / total);
            }
          },
        );
      }

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le PDF.\n${e.toString()}';
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_localPath == null) return;
    await Share.shareXFiles(
      [XFile(_localPath!)],
      subject: widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Partager',
              onPressed: _sharePdf,
            ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      // Navigation pages en bas si > 1 page
      bottomNavigationBar: _totalPages > 1 ? _pageNavBar() : null,
    );
  }

  Widget _buildBody() {
    // Téléchargement en cours
    if (_isDownloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('Chargement de la fiche…',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.12),
                color: AppColors.primary,
              ),
              if (_downloadProgress > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${(_downloadProgress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Erreur
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Affichage PDF
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        if (mounted) setState(() => _totalPages = pages ?? 0);
      },
      onViewCreated: (controller) {
        _pdfController = controller;
      },
      onPageChanged: (page, total) {
        if (mounted) {
          setState(() {
            _currentPage = page ?? 0;
            _totalPages = total ?? 0;
          });
        }
      },
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  Widget _pageNavBar() {
    return Container(
      height: 56 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0
                ? () => _pdfController?.setPage(0)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentPage > 0
                ? () => _pdfController?.setPage(_currentPage - 1)
                : null,
          ),
          Text(
            '${_currentPage + 1} / $_totalPages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentPage < _totalPages - 1
                ? () => _pdfController?.setPage(_currentPage + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages - 1
                ? () => _pdfController?.setPage(_totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }
}
