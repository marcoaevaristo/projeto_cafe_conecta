// lib/services/cotacoes_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CotacaoItem {
  final String tipo;
  final double preco;
  final String unidade;
  final DateTime dataReferencia;
  final double? variacaoPct;
  final String fonte;

  CotacaoItem({
    required this.tipo,
    required this.preco,
    required this.unidade,
    required this.dataReferencia,
    this.variacaoPct,
    required this.fonte,
  });

  factory CotacaoItem.fromJson(Map<String, dynamic> j) => CotacaoItem(
        tipo: j['tipo'] ?? '',
        preco: (j['preco'] as num?)?.toDouble() ?? 0,
        unidade: j['unidade'] ?? 'saca 60kg',
        dataReferencia: DateTime.parse(j['data_referencia']),
        variacaoPct: (j['variacao_pct'] as num?)?.toDouble(),
        fonte: j['fonte'] ?? '',
      );
}

class DolarItem {
  final double cotacaoCompra;
  final double cotacaoVenda;
  final DateTime dataReferencia;
  final String fonte;

  DolarItem({
    required this.cotacaoCompra,
    required this.cotacaoVenda,
    required this.dataReferencia,
    required this.fonte,
  });

  factory DolarItem.fromJson(Map<String, dynamic> j) => DolarItem(
        cotacaoCompra: (j['cotacao_compra'] as num?)?.toDouble() ?? 0,
        cotacaoVenda: (j['cotacao_venda'] as num?)?.toDouble() ?? 0,
        dataReferencia: DateTime.parse(j['data_referencia']),
        fonte: j['fonte'] ?? 'Banco Central',
      );
}

class B3Item {
  final String contrato;
  final String? simbolo;
  final double preco;
  final double? variacaoPct;
  final String moeda;
  final DateTime dataReferencia;
  final String fonte;

  B3Item({
    required this.contrato,
    this.simbolo,
    required this.preco,
    this.variacaoPct,
    required this.moeda,
    required this.dataReferencia,
    required this.fonte,
  });

  factory B3Item.fromJson(Map<String, dynamic> j) => B3Item(
        contrato: j['contrato'] ?? '',
        simbolo: j['simbolo'],
        preco: (j['preco'] as num?)?.toDouble() ?? 0,
        variacaoPct: (j['variacao_pct'] as num?)?.toDouble(),
        moeda: j['moeda'] ?? 'USD',
        dataReferencia: DateTime.parse(j['data_referencia']),
        fonte: j['fonte'] ?? 'Investing.com',
      );
}

class HistoricoPonto {
  final DateTime data;
  final double preco;
  final double? variacaoPct;

  HistoricoPonto({required this.data, required this.preco, this.variacaoPct});

  factory HistoricoPonto.fromJson(Map<String, dynamic> j) => HistoricoPonto(
        data: DateTime.parse(j['data']),
        preco: (j['preco'] as num?)?.toDouble() ?? 0,
        variacaoPct: (j['variacao_pct'] as num?)?.toDouble(),
      );
}

class CotacoesAtual {
  final DateTime atualizadoEm;
  final List<CotacaoItem> cepea;
  final List<CotacaoItem> noticias;
  final DolarItem? dolar;
  final List<B3Item> b3;

  CotacoesAtual({
    required this.atualizadoEm,
    required this.cepea,
    required this.noticias,
    this.dolar,
    required this.b3,
  });

  factory CotacoesAtual.fromJson(Map<String, dynamic> j) => CotacoesAtual(
        atualizadoEm: DateTime.parse(j['atualizado_em']),
        cepea: (j['cepea'] as List? ?? [])
            .map((e) => CotacaoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        noticias: (j['noticias'] as List? ?? [])
            .map((e) => CotacaoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        dolar: j['dolar'] != null
            ? DolarItem.fromJson(j['dolar'] as Map<String, dynamic>)
            : null,
        b3: (j['b3'] as List? ?? [])
            .map((e) => B3Item.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CotacoesService {
  static const _baseUrl = String.fromEnvironment(
    'COTACOES_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static Uri _uri(String path, [Map<String, String>? params]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: params);

  static Future<CotacoesAtual> fetchAtual() async {
    final resp = await http.get(_uri('/api/cotacoes/atual')).timeout(
          const Duration(seconds: 20),
        );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return CotacoesAtual.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao buscar cotações: ${resp.statusCode}');
  }

  static Future<List<HistoricoPonto>> fetchHistorico({
    String fonte = 'cepea',
    String tipo = 'arabica',
    int dias = 30,
  }) async {
    final resp = await http
        .get(_uri('/api/cotacoes/historico', {
          'fonte': fonte,
          'tipo': tipo,
          'dias': dias.toString(),
        }))
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final j = json.decode(resp.body) as Map<String, dynamic>;
      return (j['pontos'] as List? ?? [])
          .map((e) => HistoricoPonto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao buscar histórico: ${resp.statusCode}');
  }
}
