import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GerenciarAgendamentosPage extends StatefulWidget {
  const GerenciarAgendamentosPage({super.key});

  @override
  State<GerenciarAgendamentosPage> createState() =>
      _GerenciarAgendamentosPageState();
}

class _GerenciarAgendamentosPageState extends State<GerenciarAgendamentosPage> {
  static final Map<String, Map<String, dynamic>?> _userCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _buscarSolicitante(String solicitanteId) async {
    if (solicitanteId.isEmpty) return null;
    if (_userCache.containsKey(solicitanteId)) {
      return _userCache[solicitanteId];
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(solicitanteId)
          .get();
      final userData = doc.exists ? doc.data() : null;
      _userCache[solicitanteId] = userData;
      return userData;
    } catch (e) {
      debugPrint('Erro ao buscar solicitante: $e');
      return null;
    }
  }

  Future<void> _atualizarStatus(
    String agendamentoId,
    String status, {
    String? motoristaId,
    String? veiculoId,
    String? motivo,
  }) async {
    final updateData = {
      'status': status,
      if (motoristaId != null) 'motoristaId': motoristaId,
      if (veiculoId != null) 'veiculoId': veiculoId,
      if (motivo != null) 'motivoIndeferimento': motivo,
    };
    await FirebaseFirestore.instance
        .collection('agendamentos')
        .doc(agendamentoId)
        .update(updateData);
  }

  Future<void> _mostrarDialogoIndeferir(
    BuildContext context,
    String agendamentoId,
  ) async {
    final motivoController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Indeferir Agendamento'),
          content: TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo do indeferimento',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final motivo = motivoController.text.trim();
                if (motivo.isNotEmpty) {
                  _atualizarStatus(agendamentoId, 'indeferido', motivo: motivo);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Indeferir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoDeferir(
    String agendamentoId,
    Timestamp dataViagem,
  ) async {
    final motoristasDisponiveis = await _getDisponiveis(
      'motoristas',
      dataViagem,
    );
    final veiculosDisponiveis = await _getDisponiveis('veiculos', dataViagem);

    if (!mounted) return;

    String? motoristaSelecionado;
    String? veiculoSelecionado;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deferir Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                items: motoristasDisponiveis
                    .map(
                      (doc) => DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc.data()['nome'] ?? 'Sem nome'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => motoristaSelecionado = value,
                decoration: const InputDecoration(labelText: 'Motorista'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                items: veiculosDisponiveis
                    .map(
                      (doc) => DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc.data()['modelo'] ?? 'Sem modelo'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => veiculoSelecionado = value,
                decoration: const InputDecoration(labelText: 'Veículo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (motoristaSelecionado != null &&
                    veiculoSelecionado != null) {
                  _atualizarStatus(
                    agendamentoId,
                    'confirmado',
                    motoristaId: motoristaSelecionado,
                    veiculoId: veiculoSelecionado,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Deferir'),
            ),
          ],
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getDisponiveis(
    String collection,
    Timestamp dataViagem,
  ) async {
    final agendamentosNoDia = await FirebaseFirestore.instance
        .collection('agendamentos')
        .where('dataViagem', isEqualTo: dataViagem)
        .where('status', whereIn: ['confirmado', 'concluido'])
        .get();

    final idsIndisponiveis = agendamentosNoDia.docs
        .map(
          (doc) =>
              doc.data()['${collection.substring(0, collection.length - 1)}Id']
                  as String?,
        )
        .where((id) => id != null)
        .toSet();

    final todos = await FirebaseFirestore.instance.collection(collection).get();

    return todos.docs
        .where((doc) => !idsIndisponiveis.contains(doc.id))
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelado':
      case 'indeferido':
        return Colors.red;
      case 'concluído':
      case 'concluido':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Icons.check_circle;
      case 'pendente':
        return Icons.schedule;
      case 'cancelado':
      case 'indeferido':
        return Icons.cancel;
      case 'concluído':
      case 'concluido':
        return Icons.task_alt;
      default:
        return Icons.info;
    }
  }

  Widget _buildAgendamentoCard(
    BuildContext context,
    DocumentSnapshot agendamento,
    Map<String, dynamic>? solicitante,
  ) {
    final dados = agendamento.data() as Map<String, dynamic>;
    final status = dados['status'] ?? 'Sem status';
    final assunto = dados['descricao'] ?? 'Sem descrição';
    final locais = dados['locais'];
    final dataViagemTimestamp = dados['dataViagem'] as Timestamp?;
    final motoristaId = dados['motoristaId'];
    final veiculoId = dados['veiculoId'];
    final motivoIndeferimento = dados['motivoIndeferimento'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _mostrarDetalhesAgendamento(context, dados, solicitante);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assunto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dataViagemTimestamp != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Data da Viagem',
                  DateFormat('dd/MM/yyyy').format(dataViagemTimestamp.toDate()),
                ),
              ],
              _buildLocaisWidget(locais),
              if (status == 'indeferido' && motivoIndeferimento != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.comment_outlined,
                  'Motivo',
                  motivoIndeferimento,
                ),
              ],
              if (motoristaId != null &&
                  motoristaId.isNotEmpty &&
                  veiculoId != null &&
                  veiculoId.isNotEmpty) ...[
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('motoristas')
                      .doc(motoristaId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final motorista =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return _buildInfoRow(
                      Icons.person,
                      'Motorista',
                      motorista['nome'] ?? 'Não encontrado',
                    );
                  },
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('veiculos')
                      .doc(veiculoId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final veiculo =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return _buildInfoRow(
                      Icons.directions_car,
                      'Veículo',
                      veiculo['modelo'] ?? 'Não encontrado',
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (solicitante != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solicitante['nome'] ?? 'Sem nome',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solicitante['email'] ?? 'Sem email',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.person_off, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Solicitante não encontrado',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              if (status == 'pendente') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _mostrarDialogoIndeferir(context, agendamento.id),
                      child: const Text('Indeferir'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          _atualizarStatus(agendamento.id, 'cancelado'),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _mostrarDialogoDeferir(
                        agendamento.id,
                        dados['dataViagem'] as Timestamp,
                      ),
                      child: const Text('Deferir'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLocaisWidget(dynamic locaisData) {
    if (locaisData is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.route, 'Locais', ''),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: locaisData.map<Widget>((local) {
                final municipio =
                    local['municipio'] ?? 'Município não informado';
                final escolas = local['escolas'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• $municipio',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: escolas
                            .map((escola) => Text('- $escola'))
                            .toList(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
    return _buildInfoRow(Icons.route, 'Locais', 'Não informado');
  }

  void _mostrarDetalhesAgendamento(
    BuildContext context,
    Map<String, dynamic> dados,
    Map<String, dynamic>? solicitante,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dados['descricao'] ?? 'Agendamento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dados['descricao'] != null) ...[
                const Text(
                  'Descrição:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(dados['descricao']),
                const SizedBox(height: 16),
              ],
              const Text(
                'Informações do Solicitante:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (solicitante != null) ...[
                Text('Nome: ${solicitante['nome'] ?? 'Sem nome'}'),
                Text('Email: ${solicitante['email'] ?? 'Sem email'}'),
                if (solicitante['telefone'] != null)
                  Text('Telefone: ${solicitante['telefone']}'),
              ] else
                const Text('Solicitante não encontrado'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Pesquisar',
              hintText: 'Pesquise por status, data, local...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('agendamentos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum agendamento encontrado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Os agendamentos aparecerão aqui quando forem criados',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final agendamentos = snapshot.data!.docs;

              final agendamentosFiltrados = agendamentos.where((agendamento) {
                if (_searchTerm.isEmpty) return true;

                final dados = agendamento.data() as Map<String, dynamic>;
                final searchTermLower = _searchTerm.toLowerCase();

                if ((dados['status'] ?? '').toLowerCase().contains(
                  searchTermLower,
                )) {
                  return true;
                }
                if ((dados['descricao'] ?? '').toLowerCase().contains(
                  searchTermLower,
                )) {
                  return true;
                }
                if ((dados['motivoIndeferimento'] ?? '').toLowerCase().contains(
                  searchTermLower,
                )) {
                  return true;
                }

                final dataViagemTimestamp = dados['dataViagem'] as Timestamp?;
                if (dataViagemTimestamp != null) {
                  final dataFormatada = DateFormat(
                    'dd/MM/yyyy',
                  ).format(dataViagemTimestamp.toDate());
                  if (dataFormatada.contains(searchTermLower)) return true;
                }

                if (dados['locais'] is List) {
                  for (final local in dados['locais']) {
                    if ((local['municipio'] ?? '').toLowerCase().contains(
                      searchTermLower,
                    )) {
                      return true;
                    }
                    if (local['escolas'] is List) {
                      for (final escola in local['escolas']) {
                        if (escola.toString().toLowerCase().contains(
                          searchTermLower,
                        )) {
                          return true;
                        }
                      }
                    }
                  }
                }

                final solicitanteId = dados['solicitanteId'];
                if (solicitanteId != null &&
                    _userCache.containsKey(solicitanteId)) {
                  final solicitante = _userCache[solicitanteId];
                  if (solicitante != null) {
                    if ((solicitante['nome'] ?? '').toLowerCase().contains(
                      searchTermLower,
                    )) {
                      return true;
                    }
                    if ((solicitante['email'] ?? '').toLowerCase().contains(
                      searchTermLower,
                    )) {
                      return true;
                    }
                  }
                }

                return false;
              }).toList();

              agendamentosFiltrados.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final timestampA = dataA['dataViagem'] as Timestamp?;
                final timestampB = dataB['dataViagem'] as Timestamp?;

                if (timestampA == null && timestampB == null) return 0;
                if (timestampA == null) return 1;
                if (timestampB == null) return -1;

                return timestampB.compareTo(timestampA);
              });

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _userCache.clear();
                  });
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: agendamentosFiltrados.length,
                  itemBuilder: (context, index) {
                    final agendamento = agendamentosFiltrados[index];
                    final dados = agendamento.data() as Map<String, dynamic>;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _buscarSolicitante(dados['solicitanteId'] ?? ''),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !_userCache.containsKey(dados['solicitanteId'])) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text('Carregando informações...'),
                                ],
                              ),
                            ),
                          );
                        }

                        return _buildAgendamentoCard(
                          context,
                          agendamento,
                          userSnapshot.data,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
