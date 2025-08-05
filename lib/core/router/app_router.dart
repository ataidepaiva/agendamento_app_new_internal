import 'package:agendamento_app/pages/admin/admin_dashboard_page.dart';
import 'package:go_router/go_router.dart';

// Importando suas páginas
import 'package:agendamento_app/pages/login_page.dart';
import 'package:agendamento_app/pages/register_page.dart';
import 'package:agendamento_app/pages/reset_password_page.dart';
import 'package:agendamento_app/pages/verify_email_page.dart';
import 'package:agendamento_app/pages/home_page.dart';
import 'package:agendamento_app/pages/meus_agendamentos_page.dart';
import 'package:agendamento_app/pages/solicitar_agendamento_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_usuarios_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_motoristas_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_escolas_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_veiculos_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_page.dart';

// Definindo as rotas
final GoRouter router = GoRouter(
  initialLocation: '/login', // Página inicial do app
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),

    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/meus-agendamentos',
      builder: (context, state) => const MeusAgendamentosPage(),
    ),
    GoRoute(
      path: '/agendamento',
      builder: (context, state) => const SolicitarAgendamentoPage(),
    ),
    GoRoute(
      path: '/admin/home',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const GerenciarUsuariosPage(),
    ),
    GoRoute(
      path: '/admin/drivers',
      builder: (context, state) => const GerenciarMotoristasPage(),
    ),
    GoRoute(
      path: '/admin/schools',
      builder: (context, state) => const GerenciarEscolasPage(),
    ),
    GoRoute(
      path: '/admin/vehicles',
      builder: (context, state) => const GerenciarVeiculosPage(),
    ),
    GoRoute(
      path: '/admin/gerenciar',
      builder: (context, state) => const GerenciarPage(),
    ),
  ],
);
