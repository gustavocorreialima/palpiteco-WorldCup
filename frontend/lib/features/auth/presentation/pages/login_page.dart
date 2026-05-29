import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/di/service_locator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure    = true;
  bool _isRegister = false;
  final _usernameCtrl    = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  AuthService get _auth => sl<AuthService>();

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic)),
    );
    _ctrl.forward();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_auth.status == AuthStatus.authenticated && mounted) {
      context.go('/home');
    }
  }

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Preencha email e senha.');
      return;
    }

    if (_isRegister) {
      final username     = _usernameCtrl.text.trim();
      final displayName  = _displayNameCtrl.text.trim();
      if (username.isEmpty || displayName.isEmpty) {
        _showError('Preencha todos os campos.');
        return;
      }
      await _auth.register(
        username:    username,
        email:       email,
        displayName: displayName,
        password:    password,
      );
    } else {
      await _auth.login(email, password);
    }
  }

  Future<void> _submitDemo() async {
    await _auth.loginDemo();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTextStyles.body.copyWith(color: Colors.white)),
      backgroundColor: AppColors.liveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Glow superior
          Positioned(
            top: -100, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [AppColors.neonBlue.withOpacity(0.12), Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: _auth,
              builder: (context, _) {
                if (_auth.error != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _auth.error != null) {
                      _showError(_auth.error!);
                      _auth.clearError();
                    }
                  });
                }
                return FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Back
                          GestureDetector(
                            onTap: () => context.go('/onboarding'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Header
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: _isRegister ? 'Criar\n' : 'Entre no\n',
                                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1),
                              ),
                              TextSpan(
                                text: _isRegister ? 'sua conta' : 'Bolão 2026',
                                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.neonBlue, height: 1.1),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRegister
                                ? 'Crie sua conta e comece a palpitar.'
                                : 'Faça seu palpite. Vença a competição.',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 36),

                          // Google OAuth
                          if (!_isRegister) ...[
                            _GoogleButton(
                              loading: _auth.loading,
                              onTap: () async {
                                // Google OAuth redireciona via URL — por ora usa demo
                                await _submitDemo();
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(child: Divider(color: AppColors.cardBorder)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('ou use seu email', style: AppTextStyles.caption),
                              ),
                              Expanded(child: Divider(color: AppColors.cardBorder)),
                            ]),
                            const SizedBox(height: 20),
                          ],

                          // Campos extra para registro
                          if (_isRegister) ...[
                            _PremiumField(
                              controller: _displayNameCtrl,
                              label: 'Nome completo',
                              icon: Icons.badge_rounded,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            _PremiumField(
                              controller: _usernameCtrl,
                              label: 'Nome de usuário',
                              icon: Icons.alternate_email_rounded,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Email
                          _PremiumField(
                            controller: _emailCtrl,
                            label: 'E-mail',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          // Senha
                          _PremiumField(
                            controller: _passwordCtrl,
                            label: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppColors.textMuted, size: 20,
                              ),
                            ),
                          ),

                          if (!_isRegister) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('Esqueceu a senha?',
                                style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue)),
                            ),
                          ],
                          const SizedBox(height: 28),

                          // Botão principal
                          _PrimaryButton(
                            label: _isRegister ? 'Criar conta' : 'Entrar',
                            loading: _auth.loading,
                            onTap: _submit,
                          ),
                          const SizedBox(height: 12),

                          // Visitante (apenas no login)
                          if (!_isRegister)
                            _SecondaryButton(
                              label: 'Entrar como visitante',
                              loading: _auth.loading,
                              onTap: _submitDemo,
                            ),

                          const SizedBox(height: 28),

                          // Toggle login/register
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isRegister = !_isRegister;
                                _auth.clearError();
                              }),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.caption,
                                  children: [
                                    TextSpan(text: _isRegister ? 'Já tem conta? ' : 'Não tem conta? '),
                                    TextSpan(
                                      text: _isRegister ? 'Entrar' : 'Criar conta',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.neonBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
              child: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Continuar com Google', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  const _PremiumField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: loading
                ? [AppColors.neonBlue.withOpacity(0.5), AppColors.neonBlue.withOpacity(0.4)]
                : [AppColors.neonBlue, const Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: loading ? null : [
            BoxShadow(color: AppColors.neonBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(label, style: AppTextStyles.button),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.textMuted, strokeWidth: 2))
              : Text(label, style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}
