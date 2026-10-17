// test/cafe_conecta_test.dart
// Testes automatizados completos do Café Conecta
// Execute com: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_conecta/models/cafe_model.dart';
import 'package:cafe_conecta/services/planos_service.dart';

void main() {
  // ═══════════════════════════════════════════════
  // 1. MODELOS
  // ═══════════════════════════════════════════════
  group('📦 CafeModel', () {
    test('fromMap cria modelo corretamente', () {
      final map = {
        'id': 1,
        'usuario_id': 2,
        'tipo': 'Arábica',
        'classificacao': 'Tipo 2',
        'quantidade': 100,
        'bebida': 'Estritamente Mole',
        'peneira': '17',
        'safra': '2024',
        'regiao': 'Sul de Minas',
        'cidade': 'Varginha',
        'fazenda': 'Fazenda Boa Vista',
        'preco_saca': 850.0,
        'status': 'ativo',
        'score_qualidade': 87,
        'verificado': 1,
        'is_favorito': 0,
        'lat': -21.55,
        'lng': -45.43,
      };

      final cafe = CafeModel.fromMap(map);

      expect(cafe.id, 1);
      expect(cafe.tipo, 'Arábica');
      expect(cafe.classificacao, 'Tipo 2');
      expect(cafe.quantidade, 100);
      expect(cafe.precoSaca, 850.0);
      expect(cafe.scoreQualidade, 87);
      expect(cafe.verificado, true);
      expect(cafe.lat, -21.55);
    });

    test('toMap serializa corretamente', () {
      final cafe = CafeModel(
        usuarioId: 1,
        tipo: 'Conilon',
        classificacao: 'Tipo 4',
        quantidade: 50,
        regiao: 'Espírito Santo',
        cidade: 'Vitória',
        precoSaca: 450.0,
        status: 'ativo',
      );

      final map = cafe.toMap();
      expect(map['tipo'], 'Conilon');
      expect(map['quantidade'], 50);
      expect(map['preco_saca'], 450.0);
    });

    test('nomeCurto retorna tipo e classificação', () {
      final cafe = CafeModel(
        usuarioId: 1, tipo: 'Arábica', classificacao: 'Tipo 2',
        quantidade: 10, regiao: 'MG', cidade: 'BH',
      );
      expect(cafe.nomeCurto, 'Arábica – Tipo 2');
    });

    test('scoreLabel retorna categoria correta', () {
      final scores = {90: 'Excelente', 85: 'Muito Bom', 80: 'Bom', 70: 'Regular'};
      for (final entry in scores.entries) {
        final cafe = CafeModel(
          usuarioId: 1, tipo: 'A', classificacao: 'T2',
          quantidade: 1, regiao: 'MG', cidade: 'BH',
          scoreQualidade: entry.key,
        );
        expect(cafe.scoreLabel, entry.value, reason: 'Score ${entry.key}');
      }
    });
  });

  // ═══════════════════════════════════════════════
  // 2. USUÁRIO MODEL
  // ═══════════════════════════════════════════════
  group('👤 UsuarioModel', () {
    test('fromMap cria usuário corretamente', () {
      final map = {
        'id': 5,
        'nome': 'João Silva',
        'email': 'joao@teste.com',
        'tipo': 'produtor',
        'empresa': 'Fazenda São João',
        'telefone': '(35) 99999-9999',
        'regiao': 'Sul de Minas',
        'verificado': 1,
      };
      final u = UsuarioModel.fromMap(map);
      expect(u.nome, 'João Silva');
      expect(u.tipo, 'produtor');
      expect(u.verificado, true);
    });

    test('toMap serializa verificado como inteiro', () {
      final u = UsuarioModel(
        nome: 'Ana', email: 'ana@teste.com',
        tipo: 'comprador', verificado: true,
      );
      expect(u.toMap()['verificado'], 1);
    });
  });

  // ═══════════════════════════════════════════════
  // 3. PROPOSTA MODEL
  // ═══════════════════════════════════════════════
  group('📋 PropostaModel', () {
    test('valorTotal calcula corretamente', () {
      final p = PropostaModel(
        deUsuarioId: 1, paraUsuarioId: 2, cafeId: 3,
        quantidadeSacas: 50, precoOfertado: 850.0,
        condicaoPagamento: 'À vista', prazoEntrega: '30 dias',
      );
      expect(p.valorTotal, 42500.0);
    });

    test('status padrão é aguardando', () {
      final p = PropostaModel(
        deUsuarioId: 1, paraUsuarioId: 2, cafeId: 1,
        quantidadeSacas: 10, precoOfertado: 500.0,
        condicaoPagamento: 'Parcelado', prazoEntrega: '15 dias',
      );
      expect(p.status, 'aguardando');
    });
  });

  // ═══════════════════════════════════════════════
  // 4. ALERTA MODEL
  // ═══════════════════════════════════════════════
  group('🔔 AlertaModel', () {
    test('descricao com todos os campos', () {
      final a = AlertaModel(
        usuarioId: 1,
        tipoCafe: 'Arábica',
        classificacao: 'Tipo 2',
        regiao: 'Sul de Minas',
        precoMaximo: 900.0,
        scoreMinimo: 80,
      );
      expect(a.descricao, contains('Arábica'));
      expect(a.descricao, contains('Tipo 2'));
      expect(a.descricao, contains('Sul de Minas'));
    });

    test('descricao sem filtros retorna mensagem padrão', () {
      final a = AlertaModel(usuarioId: 1);
      expect(a.descricao, contains('Qualquer café'));
    });

    test('ativo por padrão', () {
      final a = AlertaModel(usuarioId: 1);
      expect(a.ativo, true);
    });
  });

  // ═══════════════════════════════════════════════
  // 5. PLANOS SERVICE
  // ═══════════════════════════════════════════════
  group('💎 PlanosService', () {
    test('existe 4 planos definidos', () {
      expect(PlanosService.planos.length, 4);
    });

    test('plano gratuito tem tier 0', () {
      final p = PlanosService.getById('gratuito');
      expect(p?.tipo, PlanoTipo.gratuito);
      expect(p?.preco, 0.0);
    });

    test('plano premium tem preço R\$149', () {
      final p = PlanosService.getById('premium');
      expect(p?.preco, 149.0);
    });

    test('gratuito NÃO tem acesso a classificação IA', () {
      expect(PlanosService.temAcesso(PlanoTipo.gratuito, 'classificacao_ia'), false);
    });

    test('profissional TEM acesso a classificação IA', () {
      expect(PlanosService.temAcesso(PlanoTipo.profissional, 'classificacao_ia'), true);
    });

    test('premium TEM acesso a todos os recursos', () {
      final recursos = [
        'publicar_anuncio', 'ver_catalogo', 'cotacoes_tempo_real',
        'classificacao_ia', 'laudo_digital', 'qr_code', 'api_integracao',
      ];
      for (final r in recursos) {
        expect(
          PlanosService.temAcesso(PlanoTipo.premium, r), true,
          reason: 'Premium deve ter acesso a: $r',
        );
      }
    });

    test('gratuito tem limite de 3 anúncios', () {
      expect(PlanosService.getLimite(PlanoTipo.gratuito, 'anuncios'), 3);
    });

    test('profissional tem limite ilimitado de anúncios', () {
      expect(PlanosService.getLimite(PlanoTipo.profissional, 'anuncios'), greaterThan(100));
    });

    test('planoNecessario retorna profissional para laudo_digital', () {
      expect(PlanosService.planoNecessario('laudo_digital'), PlanoTipo.profissional);
    });

    test('planoNecessario retorna gratuito para ver_catalogo', () {
      expect(PlanosService.planoNecessario('ver_catalogo'), PlanoTipo.gratuito);
    });

    test('getByTipo retorna plano correto', () {
      final p = PlanosService.getByTipo(PlanoTipo.basico);
      expect(p.id, 'basico');
      expect(p.preco, 29.0);
    });

    test('getById com id inválido retorna plano gratuito', () {
      final p = PlanosService.getById('invalido');
      expect(p?.tipo, PlanoTipo.gratuito);
    });
  });

  // ═══════════════════════════════════════════════
  // 6. HISTÓRICO DE PREÇOS
  // ═══════════════════════════════════════════════
  group('📈 HistoricoPrecoModel', () {
    test('fromMap cria modelo corretamente', () {
      final map = {
        'id': 1,
        'tipo_cafe': 'Arábica',
        'regiao': 'Sul de Minas',
        'preco_medio': 820.50,
        'mes': '2024-01',
      };
      final h = HistoricoPrecoModel.fromMap(map);
      expect(h.tipoCafe, 'Arábica');
      expect(h.precoMedio, 820.50);
      expect(h.mes, '2024-01');
    });
  });

  // ═══════════════════════════════════════════════
  // 7. AVALIAÇÃO MODEL
  // ═══════════════════════════════════════════════
  group('⭐ AvaliacaoModel', () {
    test('fromMap cria avaliação corretamente', () {
      final map = {
        'id': 1,
        'de_usuario_id': 2,
        'para_usuario_id': 3,
        'proposta_id': 5,
        'nota': 5,
        'comentario': 'Excelente negócio!',
      };
      final a = AvaliacaoModel.fromMap(map);
      expect(a.nota, 5);
      expect(a.comentario, 'Excelente negócio!');
    });

    test('toMap serializa corretamente', () {
      final a = AvaliacaoModel(
        deUsuarioId: 1, paraUsuarioId: 2,
        propostaId: 3, nota: 4,
        comentario: 'Muito bom',
      );
      final map = a.toMap();
      expect(map['nota'], 4);
      expect(map['comentario'], 'Muito bom');
    });
  });

  // ═══════════════════════════════════════════════
  // 8. REGRAS DE NEGÓCIO
  // ═══════════════════════════════════════════════
  group('🏢 Regras de negócio', () {
    test('plano básico NÃO tem acesso a laudo digital', () {
      expect(PlanosService.temAcesso(PlanoTipo.basico, 'laudo_digital'), false);
    });

    test('hierarquia de planos está correta', () {
      // gratuito < basico < profissional < premium
      expect(PlanoTipo.gratuito.index, lessThan(PlanoTipo.basico.index));
      expect(PlanoTipo.basico.index, lessThan(PlanoTipo.profissional.index));
      expect(PlanoTipo.profissional.index, lessThan(PlanoTipo.premium.index));
    });

    test('valor total proposta com 0 sacas é 0', () {
      final p = PropostaModel(
        deUsuarioId: 1, paraUsuarioId: 2, cafeId: 1,
        quantidadeSacas: 0, precoOfertado: 850.0,
        condicaoPagamento: 'À vista', prazoEntrega: '30 dias',
      );
      expect(p.valorTotal, 0.0);
    });

    test('café sem score retorna Regular', () {
      final cafe = CafeModel(
        usuarioId: 1, tipo: 'A', classificacao: 'T2',
        quantidade: 1, regiao: 'MG', cidade: 'BH',
        scoreQualidade: null,
      );
      expect(cafe.scoreLabel, 'Regular');
    });
  });
}
