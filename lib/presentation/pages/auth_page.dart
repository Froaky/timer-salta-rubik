import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
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
              'Sincroniza tus tiempos en la nube',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una cuenta para ver tus estadísticas en cualquier dispositivo.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

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
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementar lógica de Firebase
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Sincronización próximamente disponible')),
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

            // Google Login Option
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Google Sign In
              },
              icon: const Icon(Icons.g_mobiledata, size: 32),
              label: const Text('Continuar con Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
