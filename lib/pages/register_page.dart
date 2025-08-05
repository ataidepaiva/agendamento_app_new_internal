import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _maspCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _senhaConfirmCtrl = TextEditingController();

  // Novo campo para setor
  String? _setorSelecionado;

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmSenha = false;
  String _erro = '';

  final List<String> setores = [
    'GABINETE',
    'ASSESSORIA',
    'DIRE',
    'DAFI',
    'REDE FISICA',
    'NUTRICIONISTA',
    'NTE',
    'ESCRITURAÇÃO',
    'DIPE',
    'PRESTAÇÃO DE CONTAS',
    'INSPEÇÃO ESCOLAR',
    'PATRIMONIO',
    'DGP',
    'PAGAMENTO',
    'APOSENTADORIA',
  ];

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_setorSelecionado == null) {
      setState(() {
        _erro = 'Selecione um setor.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = '';
    });

    try {
      final nome = _nomeCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final masp = _maspCtrl.text.trim();
      final senha = _senhaCtrl.text.trim();
      final senhaConfirm = _senhaConfirmCtrl.text.trim();

      if (nome.isEmpty ||
          email.isEmpty ||
          masp.isEmpty ||
          senha.isEmpty ||
          senhaConfirm.isEmpty) {
        setState(() {
          _erro = 'Preencha todos os campos obrigatórios.';
          _carregando = false;
        });
        return;
      }

      // Cria usuário no Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Salva dados adicionais no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'nome': nome,
            'email': email,
            'masp': masp,
            'setor': _setorSelecionado,
            'tipo': 'usuario',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Envia email de verificação
      if (cred.user != null && !cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        if (!mounted) return;
        context.go('/verify-email');
      } else {
        if (!mounted) return;
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      setState(
        () => _erro =
            _traduzirErroFirebase(e.code) +
            (e.message != null ? '\n${e.message}' : ''),
      );
    } catch (e) {
      setState(() => _erro = 'Erro inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _traduzirErroFirebase(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'email-already-in-use':
        return 'E-mail já cadastrado.';
      case 'weak-password':
        return 'Senha fraca (mínimo 6 caracteres com números e letras maiúsculas).';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'network-request-failed':
        return 'Falha na conexão. Verifique sua internet.';
      default:
        return 'Erro: $code';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _maspCtrl.dispose();
    _senhaCtrl.dispose();
    _senhaConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final larguraMax = 420.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Criar Conta'),
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
          Positioned.fill(
            child: Image.asset(
              "assets/images/cadastro.jpg",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.blueGrey[100]),
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
                      Text(
                        'Cadastro de Usuário',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: _inputDecoration(
                          'Nome completo',
                          Icons.person,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDecoration(
                          'E-mail institucional',
                          Icons.email,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe seu e-mail.';
                          }
                          if (!value.contains('@') ||
                              !(value.endsWith('.com.br') ||
                                  value.endsWith('@educacao.mg.gov.br'))) {
                            return 'Informe um e-mail institucional válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maspCtrl,
                        decoration: _inputDecoration('MASP', Icons.badge),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe seu MaSP.';
                          }
                          if (int.tryParse(value) == null) {
                            return 'MASP deve conter apenas números';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo setor (lista suspensa)
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Setor', Icons.business),
                        value: _setorSelecionado,
                        items: setores
                            .map(
                              (setor) => DropdownMenuItem(
                                value: setor,
                                child: Text(setor),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _setorSelecionado = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Selecione um setor' : null,
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaCtrl,
                        decoration: _inputDecorationSenha(
                          'Senha',
                          _mostrarSenha,
                          () => setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                        obscureText: !_mostrarSenha,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Inclua uma letra maiúscula';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Inclua um número';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaConfirmCtrl,
                        decoration: _inputDecorationSenha(
                          'Repita a senha',
                          _mostrarConfirmSenha,
                          () => setState(
                            () => _mostrarConfirmSenha = !_mostrarConfirmSenha,
                          ),
                        ),
                        obscureText: !_mostrarConfirmSenha,
                        validator: (value) => value != _senhaCtrl.text
                            ? 'As senhas não conferem.'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (_erro.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _erro,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                                    backgroundColor: Colors.blue[800],
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: _cadastrar,
                                  child: const Text('Cadastrar'),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _carregando
                            ? null
                            : () => context.go('/login'),
                        child: const Text(
                          'Já tem conta? Entrar',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue[800]),
      filled: true,
      fillColor: Colors.blueGrey[50]?.withAlpha(217),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  InputDecoration _inputDecorationSenha(
    String label,
    bool mostrar,
    VoidCallback onPressed,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(Icons.lock, color: Colors.blue[800]),
      suffixIcon: IconButton(
        icon: Icon(
          mostrar ? Icons.visibility : Icons.visibility_off,
          color: Colors.blueGrey[400],
        ),
        onPressed: onPressed,
      ),
      filled: true,
      fillColor: Colors.blueGrey[50]?.withAlpha(217),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
