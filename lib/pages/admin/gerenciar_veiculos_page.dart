import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GerenciarVeiculosPage extends StatefulWidget {
  const GerenciarVeiculosPage({super.key});

  @override
  State<GerenciarVeiculosPage> createState() => _GerenciarVeiculosPageState();
}

class _GerenciarVeiculosPageState extends State<GerenciarVeiculosPage> {
  final CollectionReference veiculosCollection = FirebaseFirestore.instance
      .collection('veiculos');

  final _formKey = GlobalKey<FormState>();
  final _modeloCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _placaCtrl.dispose();
    super.dispose();
  }

  // Helper para converter de forma segura um valor dinâmico para booleano
  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false; // Padrão para falso se for nulo ou outro tipo
  }

  Future<void> _salvarVeiculo({
    required bool somenteAsfalto,
    String? docId,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final veiculoData = {
      'modelo': _modeloCtrl.text.trim(),
      'placa': _placaCtrl.text.trim(),
      'somenteAsfalto': somenteAsfalto, // Sempre salva como um booleano
    };

    try {
      if (docId == null) {
        await veiculosCollection.add(veiculoData);
      } else {
        await veiculosCollection.doc(docId).update(veiculoData);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veículo ${docId == null ? 'adicionado' : 'atualizado'} com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar veículo: $e')));
    }
  }

  Future<void> _mostrarDialogoSalvar([DocumentSnapshot? doc]) async {
    final isEditing = doc != null;
    Map<String, dynamic>? data;
    bool somenteAsfalto = false;

    if (isEditing) {
      data = doc.data() as Map<String, dynamic>;
      _modeloCtrl.text = data['modelo'] ?? '';
      _placaCtrl.text = data['placa'] ?? '';
      // Conversão segura ao abrir o diálogo
      somenteAsfalto = _toBool(data['somenteAsfalto']);
    } else {
      _modeloCtrl.clear();
      _placaCtrl.clear();
      somenteAsfalto = false;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Veículo' : 'Adicionar Veículo'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _modeloCtrl,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o modelo' : null,
                    ),
                    TextFormField(
                      controller: _placaCtrl,
                      decoration: const InputDecoration(labelText: 'Placa'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe a placa' : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Somente Asfalto'),
                      value: somenteAsfalto,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          somenteAsfalto = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _salvarVeiculo(
                    somenteAsfalto: somenteAsfalto,
                    docId: doc?.id,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _excluirVeiculo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Excluir este veículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await veiculosCollection.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veículo excluído')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Veículos'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Veículo',
            onPressed: () => _mostrarDialogoSalvar(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: veiculosCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar veículos'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final veiculos = snapshot.data!.docs;
          if (veiculos.isEmpty) {
            return const Center(child: Text('Nenhum veículo cadastrado'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: veiculos.length,
            itemBuilder: (context, index) {
              final doc = veiculos[index];
              final data = doc.data() as Map<String, dynamic>;
              final modelo = data['modelo'] ?? 'Sem modelo';
              final placa = data['placa'] ?? 'Sem placa';

              // Conversão segura para exibição
              final bool somenteAsfalto = _toBool(data['somenteAsfalto']);

              return Card(
                color: Colors.deepPurple.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placa: $placa',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Somente Asfalto: ${somenteAsfalto ? 'Sim' : 'Não'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.amber),
                            tooltip: 'Editar veículo',
                            onPressed: () => _mostrarDialogoSalvar(doc),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Excluir veículo',
                            onPressed: () => _excluirVeiculo(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
