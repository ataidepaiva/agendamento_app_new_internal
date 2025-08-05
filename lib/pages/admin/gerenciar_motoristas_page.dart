import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GerenciarMotoristasPage extends StatefulWidget {
  const GerenciarMotoristasPage({super.key});

  @override
  State<GerenciarMotoristasPage> createState() =>
      _GerenciarMotoristasPageState();
}

class _GerenciarMotoristasPageState extends State<GerenciarMotoristasPage> {
  final _nomeCtrl = TextEditingController();
  String _jornada = '6h';
  DateTime? _inicioContrato;
  DateTime? _fimContrato;
  String _mensagem = '';
  String _setorSelecionado = 'TODOS';
  String? _motoristaEmEdicaoId;

  final List<String> _setores = [
    'TODOS',
    'GABINETE',
    'DIRE',
    'DAFI',
    'REDE FISICA',
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

  Future<void> _selecionarData({required bool inicio}) async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        if (inicio) {
          _inicioContrato = data;
        } else {
          _fimContrato = data;
        }
      });
    }
  }

  Future<void> _cadastrarMotorista() async {
    final nome = _nomeCtrl.text.trim();

    if (nome.isEmpty) {
      setState(() => _mensagem = 'Informe o nome.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('motoristas').add({
        'nome': nome,
        'jornada': _jornada,
        'inicioContrato': _inicioContrato != null
            ? Timestamp.fromDate(_inicioContrato!)
            : null,
        'fimContrato': _fimContrato != null
            ? Timestamp.fromDate(_fimContrato!)
            : null,
        'setorAtendimento': _setorSelecionado,
      });

      _limparCampos();
      setState(() => _mensagem = 'Motorista cadastrado com sucesso!');
    } catch (e) {
      setState(() => _mensagem = 'Erro ao cadastrar motorista.');
    }
  }

  Future<void> _atualizarMotorista() async {
    if (_motoristaEmEdicaoId == null) return;

    final nome = _nomeCtrl.text.trim();

    if (nome.isEmpty) {
      setState(() => _mensagem = 'Informe o nome.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('motoristas')
          .doc(_motoristaEmEdicaoId)
          .update({
            'nome': nome,
            'jornada': _jornada,
            'inicioContrato': _inicioContrato != null
                ? Timestamp.fromDate(_inicioContrato!)
                : null,
            'fimContrato': _fimContrato != null
                ? Timestamp.fromDate(_fimContrato!)
                : null,
            'setorAtendimento': _setorSelecionado,
          });

      _limparCampos();
      setState(() => _mensagem = 'Motorista atualizado com sucesso!');
    } catch (e) {
      setState(() => _mensagem = 'Erro ao atualizar motorista.');
    }
  }

  void _editarMotorista(String id, Map<String, dynamic> dados) {
    setState(() {
      _motoristaEmEdicaoId = id;
      _nomeCtrl.text = dados['nome'] ?? '';
      _jornada = dados['jornada'] ?? '6h';
      _setorSelecionado = dados['setorAtendimento'] ?? 'TODOS';
      _inicioContrato = dados['inicioContrato'] != null
          ? (dados['inicioContrato'] as Timestamp).toDate()
          : null;
      _fimContrato = dados['fimContrato'] != null
          ? (dados['fimContrato'] as Timestamp).toDate()
          : null;
      _mensagem = '';
    });
  }

  void _limparCampos() {
    _nomeCtrl.clear();
    _jornada = '6h';
    _inicioContrato = null;
    _fimContrato = null;
    _setorSelecionado = 'TODOS';
    _motoristaEmEdicaoId = null;
  }

  Future<void> _removerMotorista(String id) async {
    await FirebaseFirestore.instance.collection('motoristas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Motoristas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Campo nome
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Motorista',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// Jornada
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _jornada,
                decoration: const InputDecoration(
                  labelText: 'Jornada Diária',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _jornada = value!),
                items: const [
                  DropdownMenuItem(value: '6h', child: Text('6 horas')),
                  DropdownMenuItem(value: '8h', child: Text('8 horas')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// Setor
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String>(
                value: _setorSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Setor que o motorista atende',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    setState(() => _setorSelecionado = value!),
                items: _setores
                    .map(
                      (setor) =>
                          DropdownMenuItem(value: setor, child: Text(setor)),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            /// Início do contrato
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _inicioContrato != null
                      ? 'Início do contrato: ${df.format(_inicioContrato!)}'
                      : 'Início do contrato não definido',
                ),
                TextButton(
                  onPressed: () => _selecionarData(inicio: true),
                  child: const Text('Selecionar Início'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Fim do contrato
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fimContrato != null
                      ? 'Fim do contrato: ${df.format(_fimContrato!)}'
                      : 'Fim do contrato não definido',
                ),
                TextButton(
                  onPressed: () => _selecionarData(inicio: false),
                  child: const Text('Selecionar Fim'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Botão cadastrar/atualizar
            ElevatedButton(
              onPressed: _motoristaEmEdicaoId == null
                  ? _cadastrarMotorista
                  : _atualizarMotorista,
              child: Text(
                _motoristaEmEdicaoId == null
                    ? 'Cadastrar Motorista'
                    : 'Atualizar Motorista',
              ),
            ),
            const SizedBox(height: 12),

            /// Mensagem
            if (_mensagem.isNotEmpty)
              Text(
                _mensagem,
                style: TextStyle(
                  color: _mensagem.contains('sucesso')
                      ? Colors.green
                      : Colors.red,
                ),
              ),

            const Divider(height: 32),

            const Text(
              'Motoristas Cadastrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// Lista de motoristas
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('motoristas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('Nenhum motorista cadastrado.');
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final dados = doc.data() as Map<String, dynamic>;

                      final inicio = dados['inicioContrato'] != null
                          ? df.format(
                              (dados['inicioContrato'] as Timestamp).toDate(),
                            )
                          : '-';
                      final fim = dados['fimContrato'] != null
                          ? df.format(
                              (dados['fimContrato'] as Timestamp).toDate(),
                            )
                          : '-';
                      final setor =
                          dados['setorAtendimento'] ?? 'Não informado';

                      return Card(
                        child: ListTile(
                          title: Text(dados['nome'] ?? ''),
                          subtitle: Text(
                            'Jornada: ${dados['jornada']}\n'
                            'Setor: $setor\n'
                            'Início: $inicio | Fim: $fim',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    _editarMotorista(doc.id, dados),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _removerMotorista(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
