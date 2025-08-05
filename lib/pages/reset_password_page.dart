import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _carregando = false;
  String _mensagem = '';
  bool _sucesso = false; // Para controlar o estado de sucesso

  Future<void> _enviarLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _mensagem = '';
      _sucesso = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );

      setState(() {
        _mensagem =
            'Link de redefinição enviado!\nVerifique seu e-mail institucional.';
        _sucesso = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _mensagem = _traduzErroFirebase(e.code);
        _sucesso = false;
      });
    } catch (e) {
      setState(() {
        _mensagem = 'Erro inesperado: ${e.toString()}';
        _sucesso = false;
      });
    } finally {
      setState(() => _carregando = false);
    }
  }

  String _traduzErroFirebase(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido. Use o formato: usuario@dominio.com.br';
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Falha na conexão. Verifique sua internet.';
      default:
        return 'Erro ao enviar link: $code';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final larguraMax = 420.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Fundo com cor institucional e overlay escuro
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(115)),
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: larguraMax),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(247),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(46),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(
                        Icons.lock_reset,
                        size: 70,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Redefinição de Senha',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Informe seu e-mail institucional para receber o link de redefinição:',
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'E-mail institucional',
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF1976D2),
                          ),
                          filled: true,
                          fillColor: Colors.blueGrey[50]?.withAlpha(217),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe seu e-mail.';
                          }
                          if (!value.endsWith('.gov.br')) {
                            return 'Use seu e-mail institucional (@educacao.mg.gov.br)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      if (_mensagem.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _sucesso ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _sucesso ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            _mensagem,
                            style: TextStyle(
                              color: _sucesso
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 18),
                      _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : Center(
                              child: SizedBox(
                                width: 220,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: _enviarLink,
                                  child: const Text('ENVIAR LINK'),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Voltar ao Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
