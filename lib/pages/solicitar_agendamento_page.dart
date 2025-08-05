import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SolicitarAgendamentoPage extends StatefulWidget {
  const SolicitarAgendamentoPage({super.key});

  @override
  State<SolicitarAgendamentoPage> createState() =>
      _SolicitarAgendamentoPageState();
}

class _SolicitarAgendamentoPageState extends State<SolicitarAgendamentoPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _dataCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  Map<String, bool> _municipiosSelecionados = {};
  final Map<String, List<String>> _escolasPorMunicipio = {};
  final Map<String, Set<String>> _escolasSelecionadasPorMunicipio = {};

  bool _carregando = false;
  String _mensagem = '';

  @override
  void initState() {
    super.initState();
    _carregarMunicipios();
  }

  Future<void> _carregarMunicipios() async {
    try {
      final snapshot = await _firestore.collection('municipios').get();
      final Map<String, bool> mapa = {};

      for (var doc in snapshot.docs) {
        mapa[doc.id] = false;
      }

      setState(() {
        _municipiosSelecionados = mapa;
      });
    } catch (e) {
      setState(() {
        _mensagem = 'Erro ao carregar municípios.';
      });
    }
  }

  Future<void> _carregarEscolas(String municipio) async {
    if (_escolasPorMunicipio.containsKey(municipio)) return;

    try {
      final doc = await _firestore
          .collection('municipios')
          .doc(municipio)
          .get();
      final escolas = List<String>.from(doc['escolas'] ?? []);
      setState(() {
        _escolasPorMunicipio[municipio] = escolas;
        _escolasSelecionadasPorMunicipio[municipio] = {};
      });
    } catch (e) {
      setState(() {
        _mensagem = 'Erro ao carregar escolas de $municipio.';
      });
    }
  }

  Future<void> _solicitarAgendamento() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() => _mensagem = 'Usuário não autenticado.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final dataTexto = _dataCtrl.text.trim();
    final descricao = _descricaoCtrl.text.trim();

    final partes = dataTexto.split('/');
    if (partes.length != 3) {
      setState(() => _mensagem = 'Data inválida');
      return;
    }

    final dia = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    final ano = int.parse(partes[2]);

    final dataTimestamp = Timestamp.fromDate(DateTime(ano, mes, dia));

    // Monta as listas finais de envio
    final List<String> municipiosSelecionados = [];
    final List<Map<String, dynamic>> escolasSelecionadas = [];

    _municipiosSelecionados.forEach((municipio, marcado) {
      if (marcado) {
        final escolas = _escolasSelecionadasPorMunicipio[municipio] ?? {};
        if (escolas.isNotEmpty) {
          municipiosSelecionados.add(municipio);
          escolasSelecionadas.add({
            'municipio': municipio,
            'escolas': escolas.toList(),
          });
        }
      }
    });

    if (escolasSelecionadas.isEmpty) {
      setState(() => _mensagem = 'Selecione ao menos uma escola.');
      return;
    }

    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      await _firestore.collection('agendamentos').add({
        'solicitanteId': user.uid,
        'dataViagem': dataTimestamp,
        'descricao': descricao,
        'locais': escolasSelecionadas,
        'status': 'pendente',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      setState(() {
        _mensagem = 'Agendamento solicitado com sucesso!';
        _dataCtrl.clear();
        _descricaoCtrl.clear();
        _municipiosSelecionados.updateAll((key, value) => false);
        _escolasSelecionadasPorMunicipio.clear();
      });
    } catch (e) {
      setState(() {
        _mensagem = 'Erro ao solicitar agendamento.';
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Agendamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dataCtrl,
                decoration: const InputDecoration(
                  labelText: 'Data da Viagem (dd/MM/aaaa)',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _DataInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Informe a data' : null,
              ),
              const SizedBox(height: 16),
              const Text('Selecione os municípios e escolas:'),
              const SizedBox(height: 8),
              ..._municipiosSelecionados.entries.map((entry) {
                final municipio = entry.key;
                final selecionado = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(municipio),
                      value: selecionado,
                      onChanged: (val) async {
                        setState(() {
                          _municipiosSelecionados[municipio] = val ?? false;
                        });
                        if (val == true) await _carregarEscolas(municipio);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (selecionado &&
                        _escolasPorMunicipio.containsKey(municipio))
                      ..._escolasPorMunicipio[municipio]!.map((escola) {
                        final selecionadas =
                            _escolasSelecionadasPorMunicipio[municipio] ?? {};
                        final marcada = selecionadas.contains(escola);

                        return CheckboxListTile(
                          title: Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Text(escola),
                          ),
                          value: marcada,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selecionadas.add(escola);
                              } else {
                                selecionadas.remove(escola);
                              }
                              _escolasSelecionadasPorMunicipio[municipio] =
                                  selecionadas;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                    const Divider(),
                  ],
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (demandas previstas)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _solicitarAgendamento,
                      child: const Text('Solicitar'),
                    ),
              const SizedBox(height: 12),
              if (_mensagem.isNotEmpty)
                Text(
                  _mensagem,
                  style: TextStyle(
                    color: _mensagem.contains('sucesso')
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.length > 10) return oldValue;
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
