import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const AuthPage({
    super.key,
    this.completeWcaCallbackOnLoad = false,
    this.buildWcaLoginUri,
    this.completeWcaCallback,
    this.getStoredAuthSession,
    this.clearAuthSession,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isBusy = false;
  String? _statusMessage;
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
    setState(() {
      _isBusy = true;
      _statusMessage =
          widget.completeWcaCallbackOnLoad ? 'Validando login de WCA...' : null;
    });

    try {
      AuthSession? session;
      String? statusMessage = _statusMessage;

      if (widget.completeWcaCallbackOnLoad && kIsWeb) {
        session = await _completeWcaCallback(Uri.base);
        statusMessage = session == null
            ? 'No llegó un token válido desde WCA.'
            : 'Cuenta WCA conectada correctamente.';
      } else {
        session = await _getStoredAuthSession();
      }

      if (!mounted) return;
      setState(() {
        _session = session;
        _statusMessage = statusMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'No se pudo completar el login con WCA.';
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
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El login WCA por mobile queda pendiente hasta configurar deep links.',
          ),
        ),
      );
      return;
    }

    final uri = _buildWcaLoginUri(isWeb: true);
    await launchUrl(uri, webOnlyWindowName: '_self');
  }

  Future<void> _logout() async {
    await _clearAuthSession();
    if (!mounted) return;
    setState(() {
      _session = null;
      _statusMessage = 'Sesión cerrada.';
    });
  }

  Widget _buildLoggedInCard(BuildContext context) {
    final AuthProviderProfile? wcaProfile =
        _session?.providers.cast<AuthProviderProfile?>().firstWhere(
              (provider) => provider?.provider == 'wca',
              orElse: () => null,
            );

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
            children: [
              const _WcaBadge(active: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session?.name ?? _session?.email ?? 'Sesión conectada',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wcaProfile?.wcaId != null
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
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tu sesión de Salta Rubik ya está lista para usar el backend y futura sincronización.',
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
              child: const Text('Cerrar sesión'),
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
          const _WcaBadge(active: true),
          const SizedBox(width: 12),
          Text(_isBusy ? 'Conectando...' : 'Continuar con WCA'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Hero(
              tag: 'app_logo',
              child: Icon(
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
                  ? 'Usá tu cuenta WCA para entrar sin depender de formularios que todavía no están activos.'
                  : 'Tu sesión actual quedó asociada a Salta Rubik usando WCA como proveedor.',
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
                  labelText: 'Contraseña',
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
                        content: Text('Usá el acceso con WCA por ahora.'),
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
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Ingresa',
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
