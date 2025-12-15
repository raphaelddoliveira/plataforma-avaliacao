class AutoavaliacaoModel {
  final String id;
  final String idColaborador;
  final String idAvaliacao;
  final String colaboradorNome;
  final String colaboradorEmail;
  final String? token;
  final String status;
  final String? dataEnvio;
  final String? dataConclusao;
  final String? expiraEm;
  final List<dynamic> competencias;

  AutoavaliacaoModel({
    required this.id,
    required this.idColaborador,
    required this.idAvaliacao,
    required this.colaboradorNome,
    required this.colaboradorEmail,
    this.token,
    required this.status,
    this.dataEnvio,
    this.dataConclusao,
    this.expiraEm,
    required this.competencias,
  });

  factory AutoavaliacaoModel.fromJson(Map<String, dynamic> json) {
    // Verificar se id_colaborador é um Map ou String
    final colaborador = json['id_colaborador'];
    final idColab = colaborador is Map ? (colaborador['id']?.toString() ?? '') : colaborador.toString();
    final nomeColab = colaborador is Map ? (colaborador['nome'] ?? '') : '';
    final emailColab = colaborador is Map ? (colaborador['email'] ?? '') : '';

    // Verificar se id_avaliacao é um Map ou String
    final avaliacao = json['id_avaliacao'];
    final idAval = avaliacao is Map ? (avaliacao['id']?.toString() ?? '') : avaliacao.toString();

    return AutoavaliacaoModel(
      id: json['id'].toString(),
      idColaborador: idColab,
      idAvaliacao: idAval,
      colaboradorNome: nomeColab,
      colaboradorEmail: emailColab,
      token: json['token'],
      status: json['status'] ?? 'pendente',
      dataEnvio: json['data_envio'],
      dataConclusao: json['data_conclusao'],
      expiraEm: json['expira_em'],
      competencias: json['competencias'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_colaborador': idColaborador,
      'id_avaliacao': idAvaliacao,
      'token': token,
      'status': status,
      'data_envio': dataEnvio,
      'data_conclusao': dataConclusao,
      'expira_em': expiraEm,
    };
  }
}
