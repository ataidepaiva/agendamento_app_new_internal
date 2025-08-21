import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:agendamento_app/pages/home_page.dart';

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
  String? _escolaErrorMessage;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar municípios.')),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar escolas de $municipio.')),
      );
    }
  }

  bool _ehDiaUtil(DateTime dia) {
    if (dia.weekday == DateTime.saturday || dia.weekday == DateTime.sunday) {
      return false;
    }
    return true;
  }

  Future<void> _selecionarData(BuildContext context) async {
    final hoje = DateTime.now();
    var dataInicial = hoje.add(const Duration(days: 1));
    while (!_ehDiaUtil(dataInicial)) {
      dataInicial = dataInicial.add(const Duration(days: 1));
    }

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: dataInicial,
      lastDate: DateTime(hoje.year + 1, hoje.month, hoje.day),
      locale: const Locale('pt', 'BR'),
      selectableDayPredicate: _ehDiaUtil,
    );

    if (dataSelecionada != null) {
      final formatter = DateFormat('dd/MM/yyyy');
      _dataCtrl.text = formatter.format(dataSelecionada);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sucesso!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Agendamento requerido com sucesso!'),
                Text('Aguarde confirmação na página "MEUS AGENDAMENTOS".'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Explicitly pop the dialog
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _solicitarAgendamento() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final List<Map<String, dynamic>> escolasSelecionadas = [];
    _municipiosSelecionados.forEach((municipio, marcado) {
      if (marcado) {
        final escolas = _escolasSelecionadasPorMunicipio[municipio] ?? {};
        if (escolas.isNotEmpty) {
          escolasSelecionadas.add({
            'municipio': municipio,
            'escolas': escolas.toList(),
          });
        }
      }
    });

    if (escolasSelecionadas.isEmpty) {
      setState(() {
        _escolaErrorMessage = 'Selecione ao menos uma escola.';
      });
    } else {
      setState(() {
        _escolaErrorMessage = null;
      });
    }

    if (!_formKey.currentState!.validate() || escolasSelecionadas.isEmpty) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final dataTexto = _dataCtrl.text.trim();
      final dataTimestamp =
          Timestamp.fromDate(DateFormat('dd/MM/yyyy').parse(dataTexto));

      await _firestore.collection('agendamentos').add({
        'solicitanteId': user.uid,
        'dataViagem': dataTimestamp,
        'descricao': _descricaoCtrl.text.trim(),
        'locais': escolasSelecionadas,
        'status': 'pendente',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      setState(() {
        _dataCtrl.clear();
        _descricaoCtrl.clear();
        _municipiosSelecionados.updateAll((key, value) => false);
        _escolasSelecionadasPorMunicipio.clear();
        _formKey.currentState?.reset();
      });

      if (!mounted) return;
      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao solicitar agendamento.')),
      );
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
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data da Viagem',
                  hintText: 'Clique para selecionar a data',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selecionarData(context),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Selecione a data da viagem';
                  }
                  return null;
                },
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
              if (_escolaErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _escolaErrorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (demandas previstas)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 20),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _solicitarAgendamento,
                      child: const Text('Solicitar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}