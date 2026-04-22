import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_callback_parser.dart';
import '../../core/navigation/web_redirect.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/build_wca_login_uri.dart';
import '../../domain/usecases/clear_auth_session.dart';
import '../../domain/usecases/complete_wca_callback.dart';
import '../../domain/usecases/get_stored_auth_session.dart';
import '../../injection_container.dart';
import '../theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  final bool completeWcaCallbackOnLoad;
  final BuildWcaLoginUri? buildWcaLoginUri;
  final CompleteWcaCallback? completeWcaCallback;
  final GetStoredAuthSession? getStoredAuthSession;
  final ClearAuthSession? clearAuthSession;
  final Future<bool> Function(Uri uri)? openWcaLoginUri;
  final Uri? initialCallbackUri;

  const AuthPage({
    super.key,
    this.completeWcaCallbackOnLoad = false,
    this.buildWcaLoginUri,
    this.completeWcaCallback,
    this.getStoredAuthSession,
    this.clearAuthSession,
    this.openWcaLoginUri,
    this.initialCallbackUri,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isBusy = false;
  String? _statusMessage;
  String? _callbackDiagnostic;
  AuthSession? _session;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late final BuildWcaLoginUri _buildWcaLoginUri =
      widget.buildWcaLoginUri ?? sl<BuildWcaLoginUri>();
  late final CompleteWcaCallback _completeWcaCallback =
      widget.completeWcaCallback ?? sl<CompleteWcaCallback>();
  late final GetStoredAuthSession _getStoredAuthSession =
      widget.getStoredAuthSession ?? sl<GetStoredAuthSession>();
  late final ClearAuthSession _clearAuthSession =
      widget.clearAuthSession ?? sl<ClearAuthSession>();
  late final Future<bool> Function(Uri uri) _openWcaLoginUri =
      widget.openWcaLoginUri ?? openInSameTab;

  @override
  void initState() {
    super.initState();
    _bootstrapAuthState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapAuthState() async {
    final shouldCompleteWcaCallback = widget.completeWcaCallbackOnLoad &&
        (kIsWeb || widget.initialCallbackUri != null);

    setState(() {
      _isBusy = true;
      _statusMessage =
          shouldCompleteWcaCallback ? 'Validando login de WCA...' : null;
      _callbackDiagnostic = null;
    });

    Uri? callbackUri;

    try {
      AuthSession? session;
      String? statusMessage = _statusMessage;
      String? callbackDiagnostic;

      if (shouldCompleteWcaCallback) {
        callbackUri =
            widget.initialCallbackUri ?? getCurrentBrowserUri() ?? Uri.base;
        session = await _completeWcaCallback(callbackUri);
        if (session != null) {
          statusMessage = 'Cuenta WCA conectada correctamente.';
          replaceCurrentPath('/auth');
        } else {
          session = await _getStoredAuthSession();
          statusMessage = session == null
              ? 'No llego un token valido desde WCA.'
              : 'Sesion restaurada correctamente.';
          callbackDiagnostic = _buildCallbackDiagnostic(
            callbackUri,
            storedSessionFound: session != null,
          );
        }
      } else {
        session = await _getStoredAuthSession();
      }

      if (!mounted) return;
      setState(() {
        _session = session;
        _statusMessage = statusMessage;
        _callbackDiagnostic = callbackDiagnostic;
      });
    } catch (error) {
      final diagnosticUri = callbackUri ??
          widget.initialCallbackUri ??
          getCurrentBrowserUri() ??
          Uri.base;
      if (!mounted) return;
      setState(() {
        _statusMessage = 'No se pudo completar el login con WCA.';
        _callbackDiagnostic = _buildCallbackDiagnostic(
          diagnosticUri,
          storedSessionFound: false,
          error: error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _startWcaLogin() async {
    final allowInjectedRedirect = widget.openWcaLoginUri != null;
    if (!kIsWeb && !allowInjectedRedirect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El login WCA por mobile queda pendiente hasta configurar deep links.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final uri = _buildWcaLoginUri(isWeb: true);
    try {
      final redirected = await _openWcaLoginUri(uri);
      if (redirected) {
        return;
      }

      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      if (launched) {
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el login de WCA.'),
      ),
    );
  }

  Future<void> _logout() async {
    await _clearAuthSession();
    if (!mounted) return;
    setState(() {
      _session = null;
      _statusMessage = 'Sesion cerrada.';
    });
  }

  AuthProviderProfile? _getWcaProfile() {
    for (final provider
        in _session?.providers ?? const <AuthProviderProfile>[]) {
      if (provider.provider == 'wca') {
        return provider;
      }
    }

    return null;
  }

  String _buildInitials(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  Widget _buildLoggedInCard(BuildContext context) {
    final wcaProfile = _getWcaProfile();
    final userLabel = _session?.name ?? _session?.email ?? 'Sesion conectada';
    final initials = _buildInitials(userLabel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                avatarUrl: wcaProfile?.avatarUrl,
                initials: initials.isEmpty ? 'SR' : initials,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    if ((_session?.email ?? '').isNotEmpty) ...[
                      Text(
                        _session!.email!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      (wcaProfile?.wcaId ?? '').isNotEmpty
                          ? 'WCA ID: ${wcaProfile!.wcaId}'
                          : 'Cuenta WCA vinculada',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _WcaBadge(active: true),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _InfoChip(
                label: 'Proveedor',
                value: 'WCA',
              ),
              if ((wcaProfile?.wcaId ?? '').isNotEmpty)
                _InfoChip(
                  label: 'WCA ID',
                  value: wcaProfile!.wcaId!,
                ),
              if ((wcaProfile?.countryIso2 ?? '').isNotEmpty)
                _InfoChip(
                  label: 'Pais',
                  value: wcaProfile!.countryIso2!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tu sesion de Salta Rubik ya esta lista para usar el backend y futura sincronizacion.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _logout,
              child: const Text('Cerrar sesion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWcaButton() {
    return OutlinedButton(
      onPressed: _isBusy ? null : _startWcaLogin,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: AppTheme.textMuted),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/wca_logo.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Text(_isBusy ? 'Conectando...' : 'Continuar con WCA'),
        ],
      ),
    );
  }

  String _buildCallbackDiagnostic(
    Uri callbackUri, {
    required bool storedSessionFound,
    Object? error,
  }) {
    final params = extractAuthCallbackParams(callbackUri);
    final fragmentParams = extractAuthCallbackFragmentParams(callbackUri);
    final sanitizedCallbackUri = sanitizeAuthCallbackUri(callbackUri);
    final sanitizedBaseUri = sanitizeAuthCallbackUri(Uri.base);

    return [
      'Diagnostico callback web',
      'callbackUri: $sanitizedCallbackUri',
      'uriBase: $sanitizedBaseUri',
      'queryKeys: ${callbackUri.queryParameters.keys.join(', ')}',
      'fragmentKeys: ${fragmentParams.keys.join(', ')}',
      'hasTokenInParams: ${params.containsKey('access_token')}',
      'hasTokenInQuery: ${callbackUri.queryParameters.containsKey('access_token')}',
      'hasTokenInFragment: ${fragmentParams.containsKey('access_token')}',
      'storedSessionFound: $storedSessionFound',
      if (error != null) 'error: $error',
    ].join('\n');
  }

  Widget _buildCallbackDiagnosticCard(BuildContext context) {
    if (_callbackDiagnostic == null ||
        !widget.completeWcaCallbackOnLoad ||
        (!kIsWeb && widget.initialCallbackUri == null) ||
        _session != null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostico callback web',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SelectableText(
            _callbackDiagnostic!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayIdentity = _session?.name ?? _session?.email ?? 'SR';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesion' : 'Crear Cuenta'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Hero(
              tag: 'app_logo',
              child: _session != null
                  ? _ProfileAvatar(
                      avatarUrl: _getWcaProfile()?.avatarUrl,
                      initials: _buildInitials(displayIdentity),
                    )
                  : const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: AppTheme.accentColor,
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              _session == null
                  ? 'Sincroniza tus tiempos en la nube'
                  : 'Cuenta conectada',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _session == null
                  ? 'Usa tu cuenta WCA para entrar sin depender de formularios que todavia no estan activos.'
                  : 'Tu sesion actual quedo asociada a Salta Rubik usando WCA como proveedor.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.accentColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
            if (_callbackDiagnostic != null &&
                widget.completeWcaCallbackOnLoad &&
                (kIsWeb || widget.initialCallbackUri != null) &&
                _session == null) ...[
              _buildCallbackDiagnosticCard(context),
              const SizedBox(height: 24),
            ],
            if (_session != null) ...[
              _buildLoggedInCard(context),
            ] else ...[
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usa el acceso con WCA por ahora.'),
                      ),
                    );
                  },
                  child: Text(_isLogin ? 'Ingresar' : 'Registrarse'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'No tienes cuenta? Registrate'
                      : 'Ya tienes cuenta? Ingresa',
                  style: const TextStyle(color: AppTheme.accentColor),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildWcaButton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _WcaBadge extends StatelessWidget {
  final bool active;

  const _WcaBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppTheme.accentColor : AppTheme.cardColor,
        border: Border.all(
          color: active ? AppTheme.accentColor : AppTheme.textMuted,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'W',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: active ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.cardColor,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              initials.isEmpty ? 'SR' : initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            )
          : null,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
