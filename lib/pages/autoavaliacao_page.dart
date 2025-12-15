import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/competencia_card.dart';
import '../models/autoavaliacao_model.dart';

class AutoavaliacaoPage extends StatefulWidget {
  final String idAvaliacao;

  const AutoavaliacaoPage({super.key, required this.idAvaliacao});

  @override
  State<AutoavaliacaoPage> createState() => _AutoavaliacaoPageState();
}

class _AutoavaliacaoPageState extends State<AutoavaliacaoPage> {
  final supabase = Supabase.instance.client;
  
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  
  AutoavaliacaoModel? autoavaliacao;
  Map<String, int> notas = {};
  Map<String, TextEditingController> feedbackControllers = {};
  String? idGestor; // UUID do gestor que criou a avaliação

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      print('Buscando avaliação com ID: ${widget.idAvaliacao}');

      // 1. Buscar avaliação pelo ID
      // Tentar converter para int se for numérico
      dynamic idBusca = widget.idAvaliacao;
      final idInt = int.tryParse(widget.idAvaliacao);
      if (idInt != null) {
        idBusca = idInt;
      }

      print('ID formatado para busca: $idBusca (tipo: ${idBusca.runtimeType})');

      final avaliacaoData = await supabase
          .from('avaliacoes')
          .select('*')
          .eq('id', idBusca)
          .maybeSingle();

      print('Dados da avaliação: $avaliacaoData');

      if (avaliacaoData == null) {
        setState(() {
          errorMessage = 'Avaliação não encontrada. Verifique o link.';
          isLoading = false;
        });
        return;
      }

      // Salvar o ID do gestor que criou a avaliação
      idGestor = avaliacaoData['user_id']?.toString();

      // 2. Buscar competências pela avaliação diretamente
      print('Buscando competências para avaliacao_id: ${widget.idAvaliacao}');

      final competenciasData = await supabase
          .from('cargo_competencia')
          .select('''
            *,
            competencia_id(
              id,
              nome_competencia,
              descricao,
              tipo_competencia
            )
          ''')
          .eq('avaliacao_id', widget.idAvaliacao);

      print('Competências encontradas: ${competenciasData.length}');

      // 4. Inicializar controllers de feedback
      for (var comp in competenciasData) {
        String compId = comp['competencia_id']['id'].toString();
        feedbackControllers[compId] = TextEditingController();

        // Buscar se já existe autoavaliação para esta competência
        final autoavaliacaoExistente = await supabase
            .from('autoavaliacao_colaborador')
            .select('*')
            .eq('id_avaliacao', widget.idAvaliacao)
            .eq('id_competencia', compId)
            .maybeSingle();

        // Preencher com dados existentes se houver
        if (autoavaliacaoExistente != null) {
          if (autoavaliacaoExistente['nota'] != null) {
            notas[compId] = autoavaliacaoExistente['nota'];
          }
          if (autoavaliacaoExistente['autoavaliacao'] != null) {
            feedbackControllers[compId]!.text = autoavaliacaoExistente['autoavaliacao'];
          }
        }
      }

      // Buscar dados do colaborador
      final userData = await supabase
          .from('colaboradores')
          .select('nome, email')
          .eq('id', avaliacaoData['colaborador_id'])
          .maybeSingle();

      print('Dados do colaborador: $userData');

      setState(() {
        autoavaliacao = AutoavaliacaoModel.fromJson({
          'id': widget.idAvaliacao,
          'id_colaborador': {
            'id': avaliacaoData['colaborador_id'],
            'nome': userData?['nome'] ?? 'Colaborador',
            'email': userData?['email'] ?? '',
          },
          'id_avaliacao': avaliacaoData,
          'status': 'pendente',
          'expira_em': null,
          'competencias': List<Map<String, dynamic>>.from(
            competenciasData.map((e) => Map<String, dynamic>.from(e))
          ),
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar dados: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _enviarAutoavaliacao() async {
    // Validar se todas as competências foram avaliadas
    final competenciasNaoAvaliadas = autoavaliacao!.competencias
        .where((comp) => notas[comp['competencia_id']['id'].toString()] == null)
        .toList();

    if (competenciasNaoAvaliadas.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, avalie todas as competências antes de enviar'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1. Salvar as notas e feedbacks na tabela autoavaliacao_colaborador
      for (var comp in autoavaliacao!.competencias) {
        String compId = comp['competencia_id']['id'].toString();

        // Verificar se já existe registro
        final existente = await supabase
            .from('autoavaliacao_colaborador')
            .select('id')
            .eq('id_avaliacao', widget.idAvaliacao)
            .eq('id_competencia', compId)
            .maybeSingle();

        if (existente != null) {
          // Atualizar
          await supabase
              .from('autoavaliacao_colaborador')
              .update({
                'nota': notas[compId],
                'autoavaliacao': feedbackControllers[compId]!.text.trim(),
                'status': 'concluido',
                'id_gestor': idGestor,
              })
              .eq('id', existente['id']);
        } else {
          // Inserir
          await supabase
              .from('autoavaliacao_colaborador')
              .insert({
                'id_avaliacao': int.parse(widget.idAvaliacao),
                'id_competencia': int.parse(compId),
                'id_colaborador': int.parse(autoavaliacao!.idColaborador),
                'nota': notas[compId],
                'autoavaliacao': feedbackControllers[compId]!.text.trim(),
                'status': 'concluido',
                'id_gestor': idGestor,
              });
        }
      }

      // 2. Atualizar status_autoavaliacao na tabela avaliacoes
      await supabase
          .from('avaliacoes')
          .update({
            'status_autoavaliacao': 'Concluído',
          })
          .eq('id', widget.idAvaliacao);

      // 3. Mostrar mensagem de sucesso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2D9D8F), size: 32),
                SizedBox(width: 12),
                Text('Sucesso!'),
              ],
            ),
            content: const Text(
              'Sua autoavaliação foi enviada com sucesso.\n\nObrigado pela sua participação! Seu gestor receberá suas respostas.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    errorMessage = 'Autoavaliação concluída com sucesso!';
                    autoavaliacao = null;
                  });
                },
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar autoavaliação: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _formatarData(String? dataStr) {
    if (dataStr == null) return '';
    try {
      final data = DateTime.parse(dataStr);
      return DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(data);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cores do sistema
    const primaryColor = Color(0xFF2D9D8F);
    const secondaryColor = Color(0xFF26857A);

    // Loading
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Carregando autoavaliação...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Erro
    if (errorMessage != null && autoavaliacao == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      errorMessage!.contains('expirou') 
                          ? Icons.access_time 
                          : Icons.error_outline,
                      size: 64,
                      color: errorMessage!.contains('expirou') 
                          ? Colors.orange 
                          : Colors.red,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Tela principal
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Autoavaliação de Competências'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com gradiente
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${autoavaliacao!.colaboradorNome}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Avalie suas competências de forma honesta e objetiva. Suas respostas ajudarão no seu desenvolvimento profissional.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      if (autoavaliacao!.expiraEm != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, 
                                  color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Expira em: ${_formatarData(autoavaliacao!.expiraEm)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Lista de competências
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Competências
                  ...autoavaliacao!.competencias.asMap().entries.map((entry) {
                    final index = entry.key;
                    final comp = entry.value;
                    final competencia = comp['competencia_id'];
                    final compId = competencia['id'].toString();

                    return CompetenciaCard(
                      numero: index + 1,
                      nome: competencia['nome_competencia'] ?? 'Competência',
                      descricao: competencia['descricao'],
                      tipo: competencia['tipo_competencia'] ?? 'tecnica',
                      notaSelecionada: notas[compId],
                      feedbackController: feedbackControllers[compId]!,
                      onNotaSelecionada: (nota) {
                        setState(() => notas[compId] = nota);
                      },
                    );
                  }),

                  const SizedBox(height: 32),

                  // Botão de enviar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _enviarAutoavaliacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Enviar Autoavaliação',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
