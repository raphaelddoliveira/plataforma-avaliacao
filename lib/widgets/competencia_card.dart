import 'package:flutter/material.dart';

class CompetenciaCard extends StatelessWidget {
  final int numero;
  final String nome;
  final String? descricao;
  final String tipo;
  final int? notaSelecionada;
  final TextEditingController feedbackController;
  final Function(int) onNotaSelecionada;

  const CompetenciaCard({
    super.key,
    required this.numero,
    required this.nome,
    this.descricao,
    required this.tipo,
    required this.notaSelecionada,
    required this.feedbackController,
    required this.onNotaSelecionada,
  });

  Color _getTipoColor() {
    switch (tipo.toLowerCase()) {
      case 'comportamental':
        return const Color(0xFF4CAF50);
      case 'tecnica':
      case 'técnica':
        return Colors.blue;
      case 'lideranca':
      case 'liderança':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTipoLabel() {
    switch (tipo.toLowerCase()) {
      case 'comportamental':
        return 'Comportamental';
      case 'tecnica':
      case 'técnica':
        return 'Técnica';
      case 'lideranca':
      case 'liderança':
        return 'Liderança';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoColor = _getTipoColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tipoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tipoColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tipoColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Título e tipo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tipoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTipoLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tipoColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Descrição
            if (descricao != null && descricao!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  descricao!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Escala de avaliação
            const Text(
              'Como você avalia esta competência?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Botões de nota
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final nota = index + 1;
                final isSelected = notaSelecionada == nota;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onNotaSelecionada(nota),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 70,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tipoColor
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? tipoColor
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: tipoColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$nota',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Legenda
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 - Não atende o esperado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2 - Atende parcialmente o esperado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 - Atende totalmente o esperado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '4 - Supera o esperado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Campo de feedback
            TextField(
              controller: feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Seu feedback (opcional)',
                hintText: 'Descreva seus pontos fortes, áreas de melhoria e como você pode desenvolver esta competência...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tipoColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.comment, color: tipoColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
