import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final bool initialRegister;
  const AuthScreen({super.key, required this.onLogin, this.initialRegister = true});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  late bool _isRegister;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;

    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _cardCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _cardCtrl.dispose(); _floatCtrl.dispose();
    _userCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    _cardCtrl.reset();
    setState(() { _isRegister = !_isRegister; _error = null; });
    _cardCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = _isRegister
          ? await ApiService.register(_userCtrl.text.trim(), _passCtrl.text.trim())
          : await ApiService.login(_userCtrl.text.trim(), _passCtrl.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      await prefs.setString('username', res['username']);
      ApiService.setToken(res['token']);
      ApiService.setUsername(res['username']);
      widget.onLogin();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final maxW     = isTablet ? 480.0 : double.infinity;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(kPrimary, const Color(0xFF2E7D32), _bgCtrl.value)!,
                Color.lerp(kPrimaryMid, kAccent2, _bgCtrl.value)!,
                Color.lerp(kAccent2, const Color(0xFF66BB6A), _bgCtrl.value)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              ..._buildFloatingCircles(size),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: isTablet ? 48 : 28,
                        right: isTablet ? 48 : 28,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.07),
                          // Logo + title
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (_, __) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: Column(children: [
                                Container(
                                  width: isTablet ? 120 : 96,
                                  height: isTablet ? 120 : 96,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kAccent, width: 3),
                                  ),
                                  child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
                                ),
                                const SizedBox(height: 14),
                                const Text('VitaPulse',
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                                const SizedBox(height: 4),
                                Text('Your personal diet companion',
                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                              ]),
                            ),
                          ),
                          SizedBox(height: size.height * 0.05),
                          // Card
                          AnimatedBuilder(
                            animation: _cardCtrl,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _cardSlide.value),
                              child: Opacity(opacity: _cardFade.value, child: child),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
                              ),
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // Toggle tabs
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFFEFF7EF), borderRadius: BorderRadius.circular(14)),
                                    child: Row(children: [_tab('Register', _isRegister), _tab('Login', !_isRegister)]),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(_isRegister ? 'Create Account' : 'Welcome Back',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
                                  const SizedBox(height: 4),
                                  Text(_isRegister ? 'Start your health journey today' : 'Sign in to continue',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _userCtrl,
                                    decoration: _inputDeco('Username', Icons.person_outline),
                                    validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    decoration: _inputDeco('Password', Icons.lock_outline).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                                      ]),
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: _loading ? 0 : 4,
                                      ),
                                      child: _loading
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : Text(_isRegister ? 'Create Account' : 'Sign In',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _switchMode,
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                          children: [
                                            TextSpan(text: _isRegister ? 'Already have an account? ' : "Don't have an account? "),
                                            TextSpan(
                                              text: _isRegister ? 'Sign In' : 'Register',
                                              style: const TextStyle(color: kAccent2, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) => Expanded(
    child: GestureDetector(
      onTap: active ? null : _switchMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: active ? Colors.white : Colors.grey.shade600)),
      ),
    ),
  );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: kAccent2),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent2, width: 2)),
    filled: true,
    fillColor: const Color(0xFFF6FBF6),
  );

  List<Widget> _buildFloatingCircles(Size size) {
    final rng = Random(42);
    return List.generate(8, (i) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 20.0 + rng.nextDouble() * 60;
      return Positioned(
        left: x, top: y,
        child: AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.05 + 0.08 * sin(_bgCtrl.value * pi + i),
            child: Container(width: r, height: r, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      );
    });
  }
}
