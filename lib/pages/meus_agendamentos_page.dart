import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MeusAgendamentosPage extends StatefulWidget {
  const MeusAgendamentosPage({super.key});

  @override
  State<MeusAgendamentosPage> createState() => _MeusAgendamentosPageState();
}

class _MeusAgendamentosPageState extends State<MeusAgendamentosPage> {
  final _auth = FirebaseAuth.instance;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Agendamentos'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agendamentos')
            .where('solicitanteId', isEqualTo: usuario.uid)
            .orderBy('dataHoraViagem', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('🔥 ERRO NO FIRESTORE: ${snapshot.error}');
            return Center(
              child: Text(
                'Erro ao carregar agendamentos: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint(
              '📭 Nenhum agendamento encontrado para UID: ${usuario.uid}',
            );
            return const Center(child: Text('Nenhum agendamento encontrado.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              try {
                final agendamento = docs[index];
                final dataTimestamp =
                    agendamento['dataHoraViagem'] as Timestamp?;
                final data = dataTimestamp?.toDate();
                final status = agendamento['status'] ?? 'pendente';
                final rotaId = (agendamento.data() as Map<String, dynamic>)['rotaId'] ?? '';

                if (data == null) {
                  debugPrint(
                    '⚠️ Agendamento sem dataHoraViagem: ${agendamento.id}',
                  );
                  return ListTile(
                    title: const Text('Agendamento sem data'),
                    subtitle: Text('ID: ${agendamento.id}'),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('rotas')
                      .doc(rotaId)
                      .get(),
                  builder: (context, rotaSnapshot) {
                    String destino = 'Destino não encontrado';
                    String obs = '';

                    if (rotaSnapshot.hasData && rotaSnapshot.data!.exists) {
                      final rotaData =
                          rotaSnapshot.data!.data() as Map<String, dynamic>;
                      destino = rotaData['destino'] ?? destino;
                      obs = rotaData['obs'] ?? '';
                    } else {
                      debugPrint('⚠️ Rota não encontrada para rotaId: $rotaId');
                    }

                    return Card(
                      color: Colors.indigo.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.directions_car,
                          color: Colors.amber,
                        ),
                        title: Text(
                          _dateFormat.format(data),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Status: $status\nDestino: $destino\nObs: $obs',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              } catch (e, stack) {
                debugPrint('❌ Erro ao construir agendamento: $e');
                debugPrint(stack.toString());
                return const ListTile(
                  title: Text('Erro ao exibir agendamento'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
