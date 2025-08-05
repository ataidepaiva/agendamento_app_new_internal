import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GerenciarUsuariosPage extends StatefulWidget {
  const GerenciarUsuariosPage({super.key});

  @override
  State<GerenciarUsuariosPage> createState() => _GerenciarUsuariosPageState();
}

class _GerenciarUsuariosPageState extends State<GerenciarUsuariosPage> {
  final CollectionReference usuariosCollection = FirebaseFirestore.instance
      .collection('usuarios');

  Future<void> promoverParaAdmin(String uid) async {
    await usuariosCollection.doc(uid).update({'tipo': 'admin'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário promovido a administrador!')),
    );
  }

  Future<void> excluirUsuario(String uid) async {
    await usuariosCollection.doc(uid).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Usuário excluído!')));
  }

  Future<void> editarUsuario(
    String uid,
    String emailAtual,
    String maspAtual,
  ) async {
    final emailController = TextEditingController(text: emailAtual);
    final maspController = TextEditingController(text: maspAtual);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: maspController,
              decoration: const InputDecoration(labelText: 'MASP'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await usuariosCollection.doc(uid).update({
        'email': emailController.text.trim(),
        'masp': maspController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usuariosCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar usuários'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final doc = usuarios[index];
              final data = doc.data() as Map<String, dynamic>;

              final nome = data['nome'] ?? 'Sem nome';
              final email = data['email'] ?? 'Sem e-mail';
              final tipo = data['tipo'] ?? 'usuario';
              final setor = data['setor'] ?? 'Não informado';
              final masp = data['masp'] ?? '---';

              return Card(
                color: Colors.deepPurple.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Nome
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// E-mail e MASP
                      Text(
                        'E-mail: $email',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'MASP: $masp',
                        style: const TextStyle(color: Colors.white70),
                      ),

                      /// Setor e Tipo
                      Text(
                        'Setor: $setor',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Tipo: ${tipo.toString().toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Botões de ação
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.amber),
                            tooltip: 'Editar dados',
                            onPressed: () async {
                              await editarUsuario(doc.id, email, masp);
                            },
                          ),
                          if (tipo != 'admin')
                            IconButton(
                              icon: const Icon(
                                Icons.upgrade,
                                color: Colors.white,
                              ),
                              tooltip: 'Promover para administrador',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirmar promoção'),
                                    content: Text(
                                      'Promover $nome a administrador?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Confirmar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await promoverParaAdmin(doc.id);
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Excluir usuário',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirmar exclusão'),
                                  content: Text(
                                    'Excluir usuário $nome? Esta ação é irreversível.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await excluirUsuario(doc.id);
                              }
                            },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/register');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('INCLUIR NOVO'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
