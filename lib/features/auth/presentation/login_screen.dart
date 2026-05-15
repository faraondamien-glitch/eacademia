import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../shared/providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.getStoredUser();
    if (user != null && mounted) {
      ref.read(userProvider.notifier).setUser(user);
      context.go('/dashboard');
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user != null && mounted) {
        ref.read(userProvider.notifier).setUser(user);
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _errorMessage = _parseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 80 : 24,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Granions
                  Center(
                    child: Image.asset(
                      'assets/images/logo_granions.png',
                      height: 80,
                      errorBuilder: (context, err, stack) => Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'GRANIONS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'EACADEMIA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  Text(
                    'Connexion',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez à votre espace professionnel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email professionnel',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (v.length < 6) return 'Mot de passe trop court';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showPasswordReset,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),

                  // ── Bouton de seed (DEBUG uniquement) ─────────────────
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Mode développement',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.science_outlined, size: 16),
                      label: const Text('Créer compte test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        side: const BorderSide(color: Colors.deepOrange),
                      ),
                      onPressed: _isLoading ? null : _createTestAccount,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'test@eacademia.fr / Test1234!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.deepOrange.withValues(alpha: 0.7),
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  // ──────────────────────────────────────────────────────

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      '© 2024 Granions — Réservé aux professionnels de santé',
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Seed compte de test (DEBUG uniquement) ────────────────────────────────
  static const _testEmail = 'test@eacademia.fr';
  static const _testPassword = 'Test1234!';

  Future<void> _createTestAccount() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // 1. Créer ou récupérer l'utilisateur Firebase Auth
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _testEmail,
          password: _testPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Compte existe déjà → on se connecte directement
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _testEmail,
            password: _testPassword,
          );
        } else {
          rethrow;
        }
      }

      final uid = cred.user!.uid;

      // 2. Créer le document Firestore (si absent)
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'name': 'Dr. Test Pharmacien',
          'email': _testEmail,
          'role': 'pharmacien',
          'region': 'Île-de-France',
          'level': 'Expert',
          'createdAt': Timestamp.now(),
        });
      }

      // 3. Pré-remplir les champs et notifier
      if (mounted) {
        _emailController.text = _testEmail;
        _passwordController.text = _testPassword;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte test prêt — cliquez sur Se connecter'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        // Auto-login
        await FirebaseAuth.instance.signOut(); // on repasse par signIn normal
        setState(() => _isLoading = false);
        await _signIn();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur seed : ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _showPasswordReset() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre email pour recevoir un lien de réinitialisation.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(authRepositoryProvider);
              await repo.sendPasswordResetEmail(emailCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Email de réinitialisation envoyé')),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
