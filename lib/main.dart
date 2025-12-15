import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'pages/autoavaliacao_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remove o # da URL para web
  setPathUrlStrategy();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://swaovcwunhhmmkdsfzhg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3YW92Y3d1bmhobW1rZHNmemhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MjMzOTksImV4cCI6MjA1NzI5OTM5OX0.TmYNzEAIYxQ6Zo_PZOfBUXYLdn-SsPpVpZU51qnXEro', // Substitua pela sua chave anon
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autoavaliação',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Extrair id_avaliacao da URL
        final uri = Uri.parse(settings.name ?? '/');
        final idAvaliacao = uri.queryParameters['id_avaliacao'];

        if (idAvaliacao != null && idAvaliacao.isNotEmpty) {
          return MaterialPageRoute(
            builder: (context) => AutoavaliacaoPage(idAvaliacao: idAvaliacao),
          );
        }

        // Rota padrão caso não tenha id_avaliacao
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Link inválido',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Por favor, utilize o link enviado por email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
