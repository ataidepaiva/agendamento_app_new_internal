import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _maspController = TextEditingController();
  final _passwordController = TextEditingController();
  String _erro = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _erro = '';
      _isLoading = true;
    });

    try {
      final maspInput = _maspController.text.trim();

      if (!RegExp(r'^\d+$').hasMatch(maspInput)) {
        setState(() {
          _erro = 'Digite apenas números do MASP.';
          _isLoading = false;
        });
        return;
      }

      // Buscar email no Firestore pelo MASP
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('masp', isEqualTo: maspInput)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _erro = 'MASP não encontrado.';
          _isLoading = false;
        });
        return;
      }

      final emailParaLogin = query.docs.first['email'] ?? '';

      if (emailParaLogin.isEmpty) {
        setState(() {
          _erro = 'E-mail não encontrado para este MASP.';
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailParaLogin,
            password: _passwordController.text.trim(),
          );

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _erro = 'Dados do usuário não encontrados.';
          _isLoading = false;
        });
        return;
      }

      final tipoUsuario = userDoc.data()!['tipo'] ?? 'usuario';

      if (!mounted) return;

      if (tipoUsuario == 'admin') {
        context.go('/admin/home');
      } else {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _erro = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro inesperado: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'MASP inválido.';
      case 'user-disabled':
        return 'Conta desativada';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      default:
        return 'Erro ao fazer login: ${code.replaceAll('-', ' ')}';
    }
  }

  @override
  void dispose() {
    _maspController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anoAtual = DateTime.now().year;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(77)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Column(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Agendamento de Veículos',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Acesse sua conta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _maspController,
                              decoration: InputDecoration(
                                labelText: 'Número do MASP',
                                prefixIcon: const Icon(Icons.badge),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                if (_erro.isNotEmpty) {
                                  setState(() => _erro = '');
                                }
                              },
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 15),
                            if (_erro.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _erro,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Text(
                                    'Ainda não tem registro? Cadastre-se',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.go('/reset-password'),
                                  child: const Text('Esqueci minha senha'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '© $anoAtual Sistema de Agendamento Corporativo',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
