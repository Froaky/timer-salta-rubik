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
          replaceCurrentPath(
            callbackUri.path.isEmpty ? '/auth/callback' : callbackUri.path,
          );
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

  void _goToTimerHome() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
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

  Widget _buildLoggedInPanel(BuildContext context) {
    final wcaProfile = _getWcaProfile();
    final userLabel = _session?.name ?? _session?.email ?? 'Sesion conectada';
    final initials = _buildInitials(userLabel);
    final identityRows = <_ProfileStatRow>[
      _ProfileStatRow(label: 'Proveedor', value: 'WCA'),
      if ((_session?.email ?? '').isNotEmpty)
        _ProfileStatRow(label: 'Email', value: _session!.email!),
      if ((wcaProfile?.wcaId ?? '').isNotEmpty)
        _ProfileStatRow(label: 'WCA ID', value: wcaProfile!.wcaId!),
      if ((wcaProfile?.countryIso2 ?? '').isNotEmpty)
        _ProfileStatRow(label: 'Pais', value: wcaProfile!.countryIso2!),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useWideLayout = constraints.maxWidth >= 760;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.cardColor,
                      AppTheme.secondaryColor.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: useWideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileAvatar(
                            avatarUrl: wcaProfile?.avatarUrl,
                            initials: initials.isEmpty ? 'SR' : initials,
                            radius: 42,
                            showAccentRing: true,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildProfileHeroText(
                              context,
                              userLabel: userLabel,
                              wcaProfile: wcaProfile,
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildProfileActions(context),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ProfileAvatar(
                                avatarUrl: wcaProfile?.avatarUrl,
                                initials: initials.isEmpty ? 'SR' : initials,
                                radius: 38,
                                showAccentRing: true,
                              ),
                              const Spacer(),
                              const _WcaBadge(active: true),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildProfileHeroText(
                            context,
                            userLabel: userLabel,
                            wcaProfile: wcaProfile,
                          ),
                          const SizedBox(height: 18),
                          _buildProfileActions(context, compact: true),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ProfileInfoPanel(
                    width: useWideLayout
                        ? (constraints.maxWidth - 8) / 2
                        : constraints.maxWidth,
                    title: 'Identidad',
                    subtitle: 'Datos que llegaron desde tu cuenta WCA.',
                    child: Column(
                      children: identityRows
                          .map((row) => _buildProfileRow(context, row))
                          .toList(),
                    ),
                  ),
                  _ProfileInfoPanel(
                    width: useWideLayout
                        ? (constraints.maxWidth - 8) / 2
                        : constraints.maxWidth,
                    title: 'Estado',
                    subtitle:
                        'Tu cuenta ya puede usarse para web y futura sync.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const _InfoChip(
                              label: 'Proveedor',
                              value: 'WCA',
                            ),
                            const _InfoChip(
                              label: 'Sesion',
                              value: 'Activa',
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
                          'Tu sesion de Salta Rubik ya esta lista para usar el backend y futura sincronizacion en web y mobile.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeroText(
    BuildContext context, {
    required String userLabel,
    required AuthProviderProfile? wcaProfile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'WCA CONNECTED',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            const _WcaBadge(active: true),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userLabel,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          (wcaProfile?.wcaId ?? '').isNotEmpty
              ? 'WCA ID ${wcaProfile!.wcaId}'
              : 'Cuenta WCA vinculada correctamente',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Perfil conectado a Salta Rubik. Desde aca vas a poder acceder a tus tiempos y sesiones cuando quede lista la sincronizacion completa.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildProfileActions(
    BuildContext context, {
    bool compact = false,
  }) {
    final buttons = <Widget>[
      OutlinedButton.icon(
        onPressed: _goToTimerHome,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Ir al timer'),
      ),
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesion'),
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: buttons[i],
            ),
            if (i != buttons.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i != buttons.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, _ProfileStatRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
              _buildLoggedInPanel(context),
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

class _ProfileInfoPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final double width;

  const _ProfileInfoPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.textMuted.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final bool showAccentRing;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
    this.radius = 28,
    this.showAccentRing = false,
  });

  String? _resolvedAvatarUrl() {
    final raw = avatarUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('//')) {
      return 'https:$raw';
    }

    if (raw.startsWith('/')) {
      return 'https://www.worldcubeassociation.org$raw';
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarUrl = _resolvedAvatarUrl();
    final diameter = radius * 2;
    final fallback = _ProfileAvatarFallback(
      initials: initials,
      fontSize: radius * 0.62,
    );

    return Container(
      width: diameter,
      height: diameter,
      padding: EdgeInsets.all(showAccentRing ? 3 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showAccentRing
            ? const LinearGradient(
                colors: [
                  Color(0xFF60A5FA),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
          ),
          child: resolvedAvatarUrl == null
              ? fallback
              : Image.network(
                  resolvedAvatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return fallback;
                  },
                ),
        ),
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _ProfileAvatarFallback({
    required this.initials,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B263B),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'SR' : initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
      ),
    );
  }
}

class _ProfileStatRow {
  final String label;
  final String value;

  const _ProfileStatRow({
    required this.label,
    required this.value,
  });
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
