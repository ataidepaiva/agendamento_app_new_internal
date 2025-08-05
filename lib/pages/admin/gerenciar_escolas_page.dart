import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GerenciarEscolasPage extends StatefulWidget {
  const GerenciarEscolasPage({super.key});

  @override
  State<GerenciarEscolasPage> createState() => _GerenciarEscolasPageState();
}

class _GerenciarEscolasPageState extends State<GerenciarEscolasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _municipioSelecionado;
  List<String> _escolas = [];
  final TextEditingController _novaEscolaController = TextEditingController();

  Future<List<String>> _buscarMunicipios() async {
    final snapshot = await _firestore.collection('municipios').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> _carregarEscolas(String municipio) async {
    final doc = await _firestore.collection('municipios').doc(municipio).get();
    final data = doc.data();
    if (data != null && data['escolas'] is List) {
      setState(() {
        _municipioSelecionado = municipio;
        _escolas = List<String>.from(data['escolas']);
      });
    } else {
      setState(() {
        _municipioSelecionado = municipio;
        _escolas = [];
      });
    }
  }

  Future<void> _adicionarEscola() async {
    final novaEscola = _novaEscolaController.text.trim();
    if (novaEscola.isEmpty || _municipioSelecionado == null) return;

    if (!_escolas.contains(novaEscola)) {
      setState(() => _escolas.add(novaEscola));
      await _firestore
          .collection('municipios')
          .doc(_municipioSelecionado)
          .update({'escolas': _escolas});
      _novaEscolaController.clear();
    }
  }

  Future<void> _removerEscola(String escola) async {
    setState(() => _escolas.remove(escola));
    await _firestore.collection('municipios').doc(_municipioSelecionado).update(
      {'escolas': _escolas},
    );
  }

  @override
  void dispose() {
    _novaEscolaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Escolas por Município')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<List<String>>(
              future: _buscarMunicipios(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final municipios = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _municipioSelecionado,
                  items: municipios.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _carregarEscolas(value);
                  },
                  decoration: const InputDecoration(labelText: 'Município'),
                );
              },
            ),
            const SizedBox(height: 20),
            if (_municipioSelecionado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escolas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._escolas.map(
                    (e) => ListTile(
                      title: Text(e),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerEscola(e),
                      ),
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _novaEscolaController,
                    decoration: InputDecoration(
                      labelText: 'Nova Escola',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _adicionarEscola,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
