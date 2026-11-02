/* =====================================================================
   PROJETO ERP — METALÚRGICA VÉRTICE LTDA.
   5. Script SQL completo
   SGBD: MySQL 8
   ===================================================================== */


/* =====================================================================
   CREATE DATABASE
   ===================================================================== */

DROP DATABASE IF EXISTS erp_vertice;
CREATE DATABASE erp_vertice;
USE erp_vertice;

-- O Workbench vem com o "safe update mode" ligado, que bloqueia UPDATE/DELETE
-- cujo WHERE não usa a chave primária. Desligamos para rodar o script inteiro.
SET SQL_SAFE_UPDATES = 0;


/* =====================================================================
   CREATE TABLE (com PK, FK e constraints)
   ===================================================================== */

-- ---------- Cadastros ----------

CREATE TABLE fornecedor (
    id_fornecedor  INT AUTO_INCREMENT,
    razao_social   VARCHAR(150) NOT NULL,
    cnpj           CHAR(14)     NOT NULL,
    contato        VARCHAR(100),
    telefone       VARCHAR(20),
    logradouro     VARCHAR(150),
    numero         VARCHAR(10),
    bairro         VARCHAR(80),
    cidade         VARCHAR(80),
    uf             CHAR(2),
    cep            CHAR(8),
    CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor),
    CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj),                 -- RN14
    CONSTRAINT ck_fornecedor_cnpj CHECK (LENGTH(cnpj) = 14)
);

CREATE TABLE material (
    id_material    INT AUTO_INCREMENT,
    codigo         VARCHAR(20)  NOT NULL,
    descricao      VARCHAR(150) NOT NULL,
    categoria      VARCHAR(20)  NOT NULL,
    unidade_medida VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_material PRIMARY KEY (id_material),
    CONSTRAINT uq_material_codigo UNIQUE (codigo),
    CONSTRAINT ck_material_categoria CHECK (categoria IN ('MATERIA_PRIMA', 'INSUMO', 'COMPONENTE'))
);

CREATE TABLE produto (
    id_produto     INT AUTO_INCREMENT,
    codigo         VARCHAR(20)  NOT NULL,
    descricao      VARCHAR(150) NOT NULL,
    tipo           VARCHAR(15)  NOT NULL,
    unidade_medida VARCHAR(10)  NOT NULL DEFAULT 'un',
    CONSTRAINT pk_produto PRIMARY KEY (id_produto),
    CONSTRAINT uq_produto_codigo UNIQUE (codigo),
    CONSTRAINT ck_produto_tipo CHECK (tipo IN ('INTERMEDIARIO', 'ACABADO'))     -- RN10
);

CREATE TABLE turno (
    id_turno       INT AUTO_INCREMENT,
    descricao      VARCHAR(10) NOT NULL,
    horario_inicio TIME        NOT NULL,
    horario_fim    TIME        NOT NULL,
    CONSTRAINT pk_turno PRIMARY KEY (id_turno),
    CONSTRAINT uq_turno_descricao UNIQUE (descricao),
    CONSTRAINT ck_turno_descricao CHECK (descricao IN ('MANHA', 'TARDE', 'NOITE'))
);

CREATE TABLE maquina (
    id_maquina INT AUTO_INCREMENT,
    nome       VARCHAR(60) NOT NULL,
    tipo       VARCHAR(20) NOT NULL,
    setor      VARCHAR(30) NOT NULL,
    CONSTRAINT pk_maquina PRIMARY KEY (id_maquina),
    CONSTRAINT uq_maquina_nome UNIQUE (nome)
);

CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT,
    nome           VARCHAR(120) NOT NULL,
    cpf            CHAR(11)     NOT NULL,
    cargo          VARCHAR(60)  NOT NULL,
    setor          VARCHAR(30)  NOT NULL,
    perfil_acesso  VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_funcionario_cpf UNIQUE (cpf),                  -- RN14
    CONSTRAINT ck_funcionario_cpf CHECK (LENGTH(cpf) = 11),
    CONSTRAINT ck_funcionario_perfil CHECK (perfil_acesso IN
        ('COMPRAS', 'PRODUCAO', 'ESTOQUE', 'VENDAS', 'FINANCEIRO', 'QUALIDADE_GESTAO'))   -- RNF01
);

CREATE TABLE cliente (
    id_cliente        INT AUTO_INCREMENT,
    nome_razao_social VARCHAR(150) NOT NULL,
    cpf_cnpj          VARCHAR(14)  NOT NULL,
    tipo_cliente      CHAR(2)      NOT NULL,
    telefone          VARCHAR(20),
    email             VARCHAR(120),
    logradouro        VARCHAR(150),
    numero            VARCHAR(10),
    bairro            VARCHAR(80),
    cidade            VARCHAR(80),
    uf                CHAR(2),
    cep               CHAR(8),
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_cpf_cnpj UNIQUE (cpf_cnpj),           -- RN14
    CONSTRAINT ck_cliente_tipo CHECK (tipo_cliente IN ('PF', 'PJ')),
    CONSTRAINT ck_cliente_documento CHECK (
        (tipo_cliente = 'PF' AND LENGTH(cpf_cnpj) = 11) OR
        (tipo_cliente = 'PJ' AND LENGTH(cpf_cnpj) = 14))
);

-- ---------- Compras ----------

CREATE TABLE pedido_compra (
    id_pedido_compra INT AUTO_INCREMENT,
    id_fornecedor    INT         NOT NULL,
    data_pedido      DATE        NOT NULL,
    status           VARCHAR(12) NOT NULL DEFAULT 'ABERTO',
    CONSTRAINT pk_pedido_compra PRIMARY KEY (id_pedido_compra),
    CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    CONSTRAINT ck_pedido_status CHECK (status IN ('ABERTO', 'PARCIAL', 'CONCLUIDO', 'CANCELADO'))
);

CREATE TABLE item_pedido_compra (
    id_item_pedido   INT AUTO_INCREMENT,
    id_pedido_compra INT           NOT NULL,
    id_material      INT           NOT NULL,
    quantidade       DECIMAL(12,3) NOT NULL,
    preco_unitario   DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_item_pedido PRIMARY KEY (id_item_pedido),
    CONSTRAINT fk_itempedido_pedido FOREIGN KEY (id_pedido_compra) REFERENCES pedido_compra (id_pedido_compra),
    CONSTRAINT fk_itempedido_material FOREIGN KEY (id_material) REFERENCES material (id_material),
    CONSTRAINT ck_itempedido_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_itempedido_preco CHECK (preco_unitario >= 0)
);

CREATE TABLE nota_fiscal_fornecedor (
    id_nf_fornecedor INT AUTO_INCREMENT,
    id_fornecedor    INT         NOT NULL,
    numero           VARCHAR(15) NOT NULL,
    serie            VARCHAR(5)  NOT NULL,
    data_emissao     DATE        NOT NULL,
    chave_acesso     CHAR(44),
    CONSTRAINT pk_nf_fornecedor PRIMARY KEY (id_nf_fornecedor),
    CONSTRAINT fk_nf_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    CONSTRAINT uq_nf_numero_serie UNIQUE (id_fornecedor, numero, serie)
);

CREATE TABLE item_nota_fornecedor (
    id_item_nf       INT AUTO_INCREMENT,
    id_nf_fornecedor INT           NOT NULL,
    id_material      INT           NOT NULL,
    id_item_pedido   INT,                         -- opcional: compra sem pedido
    quantidade       DECIMAL(12,3) NOT NULL,
    preco_unitario   DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_item_nf PRIMARY KEY (id_item_nf),
    CONSTRAINT fk_itemnf_nf FOREIGN KEY (id_nf_fornecedor) REFERENCES nota_fiscal_fornecedor (id_nf_fornecedor),
    CONSTRAINT fk_itemnf_material FOREIGN KEY (id_material) REFERENCES material (id_material),
    CONSTRAINT fk_itemnf_itempedido FOREIGN KEY (id_item_pedido) REFERENCES item_pedido_compra (id_item_pedido),
    CONSTRAINT ck_itemnf_quantidade CHECK (quantidade > 0)
);

CREATE TABLE recebimento (
    id_recebimento        INT AUTO_INCREMENT,
    id_item_nf            INT           NOT NULL,
    data_hora             DATETIME      NOT NULL,
    quantidade_recebida   DECIMAL(12,3) NOT NULL,
    resultado_conferencia VARCHAR(10)   NOT NULL,
    id_responsavel        INT           NOT NULL,
    CONSTRAINT pk_recebimento PRIMARY KEY (id_recebimento),
    CONSTRAINT fk_recebimento_itemnf FOREIGN KEY (id_item_nf) REFERENCES item_nota_fornecedor (id_item_nf),
    CONSTRAINT fk_recebimento_responsavel FOREIGN KEY (id_responsavel) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_recebimento_quantidade CHECK (quantidade_recebida > 0),
    CONSTRAINT ck_recebimento_resultado CHECK (resultado_conferencia IN ('CONFORME', 'REPROVADO'))
);

-- ---------- Produção ----------

CREATE TABLE evento_producao (
    id_evento        INT AUTO_INCREMENT,
    tipo_evento      VARCHAR(10) NOT NULL,
    id_maquina       INT         NOT NULL,
    id_funcionario   INT         NOT NULL,
    id_turno         INT         NOT NULL,
    data_hora_inicio DATETIME    NOT NULL,
    data_hora_fim    DATETIME,                    -- vazio enquanto o evento está aberto
    status_evento    VARCHAR(10) NOT NULL DEFAULT 'ABERTO',
    CONSTRAINT pk_evento PRIMARY KEY (id_evento),
    CONSTRAINT fk_evento_maquina FOREIGN KEY (id_maquina) REFERENCES maquina (id_maquina),             -- RN06
    CONSTRAINT fk_evento_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id_funcionario),
    CONSTRAINT fk_evento_turno FOREIGN KEY (id_turno) REFERENCES turno (id_turno),
    CONSTRAINT ck_evento_tipo CHECK (tipo_evento IN ('CORTE', 'USINAGEM', 'ZINCAGEM', 'MONTAGEM')),
    CONSTRAINT ck_evento_status CHECK (status_evento IN ('ABERTO', 'ENCERRADO')),
    CONSTRAINT ck_evento_datas CHECK (data_hora_fim IS NULL OR data_hora_inicio < data_hora_fim)       -- RN07
);

-- ---------- Lotes (supertipo e subtipos) ----------

CREATE TABLE lote (
    id_lote            INT AUTO_INCREMENT,
    codigo_lote        VARCHAR(15)   NOT NULL,
    tipo_lote          CHAR(2)       NOT NULL,     -- MP = matéria-prima, PR = produto
    data_criacao       DATETIME      NOT NULL,
    quantidade_inicial DECIMAL(12,3) NOT NULL,
    status             VARCHAR(12)   NOT NULL DEFAULT 'DISPONIVEL',
    CONSTRAINT pk_lote PRIMARY KEY (id_lote),
    CONSTRAINT uq_lote_codigo UNIQUE (codigo_lote),                       -- RNF04
    CONSTRAINT ck_lote_tipo CHECK (tipo_lote IN ('MP', 'PR')),
    CONSTRAINT ck_lote_quantidade CHECK (quantidade_inicial > 0),
    CONSTRAINT ck_lote_status CHECK (status IN ('DISPONIVEL', 'REPROVADO', 'BLOQUEADO', 'ESGOTADO', 'INATIVADO'))
);

CREATE TABLE lote_materia_prima (
    id_lote            INT,
    id_material        INT NOT NULL,
    id_fornecedor      INT NOT NULL,
    id_recebimento     INT NOT NULL,
    numero_certificado VARCHAR(30),
    motivo_reprovacao  VARCHAR(255),
    CONSTRAINT pk_lote_materia_prima PRIMARY KEY (id_lote),
    CONSTRAINT fk_lotemp_lote FOREIGN KEY (id_lote) REFERENCES lote (id_lote),
    CONSTRAINT fk_lotemp_material FOREIGN KEY (id_material) REFERENCES material (id_material),         -- RN01
    CONSTRAINT fk_lotemp_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor), -- RN01
    CONSTRAINT fk_lotemp_recebimento FOREIGN KEY (id_recebimento) REFERENCES recebimento (id_recebimento)
);

CREATE TABLE lote_produto (
    id_lote           INT,
    id_produto        INT NOT NULL,
    id_evento_geracao INT NOT NULL,
    CONSTRAINT pk_lote_produto PRIMARY KEY (id_lote),
    CONSTRAINT fk_loteprod_lote FOREIGN KEY (id_lote) REFERENCES lote (id_lote),
    CONSTRAINT fk_loteprod_produto FOREIGN KEY (id_produto) REFERENCES produto (id_produto),
    CONSTRAINT fk_loteprod_evento FOREIGN KEY (id_evento_geracao) REFERENCES evento_producao (id_evento),
    CONSTRAINT uq_loteprod_evento UNIQUE (id_evento_geracao)              -- RN05: um evento gera um único lote
);

CREATE TABLE consumo_em_producao (
    id_evento            INT,
    id_lote_consumido    INT,
    quantidade_consumida DECIMAL(12,3) NOT NULL,
    CONSTRAINT pk_consumo PRIMARY KEY (id_evento, id_lote_consumido),
    CONSTRAINT fk_consumo_evento FOREIGN KEY (id_evento) REFERENCES evento_producao (id_evento),
    CONSTRAINT fk_consumo_lote FOREIGN KEY (id_lote_consumido) REFERENCES lote (id_lote),
    CONSTRAINT ck_consumo_quantidade CHECK (quantidade_consumida > 0)    -- RN04
);

CREATE TABLE ajuste_evento (
    id_ajuste           INT AUTO_INCREMENT,
    id_evento           INT          NOT NULL,
    id_solicitante      INT          NOT NULL,
    id_aprovador        INT,                         -- vazio enquanto pendente
    data_solicitacao    DATETIME     NOT NULL,
    data_decisao        DATETIME,
    data_aplicacao      DATETIME,
    status_ajuste       VARCHAR(10)  NOT NULL DEFAULT 'PENDENTE',
    justificativa       VARCHAR(255) NOT NULL,
    descricao_alteracao VARCHAR(255) NOT NULL,
    CONSTRAINT pk_ajuste PRIMARY KEY (id_ajuste),
    CONSTRAINT fk_ajuste_evento FOREIGN KEY (id_evento) REFERENCES evento_producao (id_evento),
    CONSTRAINT fk_ajuste_solicitante FOREIGN KEY (id_solicitante) REFERENCES funcionario (id_funcionario),
    CONSTRAINT fk_ajuste_aprovador FOREIGN KEY (id_aprovador) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_ajuste_status CHECK (status_ajuste IN ('PENDENTE', 'APROVADO', 'REJEITADO', 'APLICADO')),
    CONSTRAINT ck_ajuste_aprovador CHECK (id_aprovador IS NULL OR id_aprovador <> id_solicitante)      -- RN15
);

CREATE TABLE item_ajuste_evento (
    id_item_ajuste INT AUTO_INCREMENT,
    id_ajuste      INT          NOT NULL,
    campo_alterado VARCHAR(80)  NOT NULL,
    valor_anterior VARCHAR(100) NOT NULL,
    valor_novo     VARCHAR(100) NOT NULL,
    CONSTRAINT pk_item_ajuste PRIMARY KEY (id_item_ajuste),
    CONSTRAINT fk_itemajuste_ajuste FOREIGN KEY (id_ajuste) REFERENCES ajuste_evento (id_ajuste)
);

-- ---------- Vendas ----------

CREATE TABLE venda (
    id_venda           INT AUTO_INCREMENT,
    id_cliente         INT         NOT NULL,             -- RN08
    id_funcionario     INT         NOT NULL,
    data_venda         DATE        NOT NULL,
    forma_pagamento    VARCHAR(15) NOT NULL,
    numero_nota_fiscal VARCHAR(15),
    CONSTRAINT pk_venda PRIMARY KEY (id_venda),
    CONSTRAINT fk_venda_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_venda_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id_funcionario),
    CONSTRAINT uq_venda_nf UNIQUE (numero_nota_fiscal),
    CONSTRAINT ck_venda_pagamento CHECK (forma_pagamento IN ('PIX', 'BOLETO', 'CARTAO', 'TRANSFERENCIA', 'DINHEIRO'))
);

CREATE TABLE item_venda (
    id_venda        INT,
    id_lote_produto INT,
    quantidade      DECIMAL(12,3) NOT NULL,
    preco_unitario  DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_item_venda PRIMARY KEY (id_venda, id_lote_produto),
    CONSTRAINT fk_itemvenda_venda FOREIGN KEY (id_venda) REFERENCES venda (id_venda),
    CONSTRAINT fk_itemvenda_lote FOREIGN KEY (id_lote_produto) REFERENCES lote_produto (id_lote),
    CONSTRAINT ck_itemvenda_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_itemvenda_preco CHECK (preco_unitario >= 0)
);

-- ---------- Estoque ----------

CREATE TABLE movimentacao_estoque (
    id_movimento           INT AUTO_INCREMENT,
    id_lote                INT           NOT NULL,
    tipo                   VARCHAR(20)   NOT NULL,
    quantidade_assinada    DECIMAL(12,3) NOT NULL,     -- entrada positiva, saída negativa
    data_hora              DATETIME      NOT NULL,
    id_responsavel         INT           NOT NULL,
    origem_tipo            VARCHAR(20)   NOT NULL,
    origem_id              INT           NOT NULL,
    id_movimento_estornado INT,
    justificativa          VARCHAR(255),
    CONSTRAINT pk_movimento PRIMARY KEY (id_movimento),
    CONSTRAINT fk_movimento_lote FOREIGN KEY (id_lote) REFERENCES lote (id_lote),
    CONSTRAINT fk_movimento_responsavel FOREIGN KEY (id_responsavel) REFERENCES funcionario (id_funcionario),
    CONSTRAINT fk_movimento_estornado FOREIGN KEY (id_movimento_estornado) REFERENCES movimentacao_estoque (id_movimento),
    CONSTRAINT ck_movimento_tipo CHECK (tipo IN ('RECEBIMENTO', 'PRODUCAO', 'CONSUMO', 'VENDA',
        'DEVOLUCAO_CLIENTE', 'DEVOLUCAO_FORNECEDOR', 'PERDA', 'AJUSTE', 'ESTORNO')),
    CONSTRAINT ck_movimento_quantidade CHECK (quantidade_assinada <> 0),                 -- RN17
    CONSTRAINT ck_movimento_justificativa CHECK (
        tipo NOT IN ('PERDA', 'AJUSTE', 'ESTORNO') OR justificativa IS NOT NULL),       -- RP09
    CONSTRAINT ck_movimento_estorno CHECK (
        tipo <> 'ESTORNO' OR id_movimento_estornado IS NOT NULL)                         -- RN18
);

-- ---------- Devoluções ----------

CREATE TABLE devolucao_fornecedor (
    id_devolucao_fornecedor INT AUTO_INCREMENT,
    id_nf_fornecedor        INT          NOT NULL,
    data                    DATE         NOT NULL,
    motivo                  VARCHAR(255) NOT NULL,
    status                  VARCHAR(12)  NOT NULL DEFAULT 'REGISTRADA',
    CONSTRAINT pk_devolucao_fornecedor PRIMARY KEY (id_devolucao_fornecedor),
    CONSTRAINT fk_devforn_nf FOREIGN KEY (id_nf_fornecedor) REFERENCES nota_fiscal_fornecedor (id_nf_fornecedor),
    CONSTRAINT ck_devforn_status CHECK (status IN ('REGISTRADA', 'CONCLUIDA'))
);

CREATE TABLE item_devolucao_fornecedor (
    id_item_devolucao       INT AUTO_INCREMENT,
    id_devolucao_fornecedor INT           NOT NULL,
    id_lote                 INT           NOT NULL,
    quantidade              DECIMAL(12,3) NOT NULL,
    CONSTRAINT pk_item_devforn PRIMARY KEY (id_item_devolucao),
    CONSTRAINT fk_itemdevforn_devolucao FOREIGN KEY (id_devolucao_fornecedor) REFERENCES devolucao_fornecedor (id_devolucao_fornecedor),
    CONSTRAINT fk_itemdevforn_lote FOREIGN KEY (id_lote) REFERENCES lote_materia_prima (id_lote),
    CONSTRAINT ck_itemdevforn_quantidade CHECK (quantidade > 0)
);

CREATE TABLE devolucao_cliente (
    id_devolucao_cliente INT AUTO_INCREMENT,
    id_venda             INT          NOT NULL,
    data                 DATE         NOT NULL,
    motivo               VARCHAR(255) NOT NULL,
    status               VARCHAR(12)  NOT NULL DEFAULT 'RECEBIDA',
    CONSTRAINT pk_devolucao_cliente PRIMARY KEY (id_devolucao_cliente),
    CONSTRAINT fk_devcli_venda FOREIGN KEY (id_venda) REFERENCES venda (id_venda),
    CONSTRAINT ck_devcli_status CHECK (status IN ('RECEBIDA', 'ANALISADA', 'CONCLUIDA'))
);

CREATE TABLE item_devolucao_cliente (
    id_item_devolucao_cliente INT AUTO_INCREMENT,
    id_devolucao_cliente      INT           NOT NULL,
    id_lote                   INT           NOT NULL,
    quantidade                DECIMAL(12,3) NOT NULL,
    CONSTRAINT pk_item_devcli PRIMARY KEY (id_item_devolucao_cliente),
    CONSTRAINT fk_itemdevcli_devolucao FOREIGN KEY (id_devolucao_cliente) REFERENCES devolucao_cliente (id_devolucao_cliente),
    CONSTRAINT fk_itemdevcli_lote FOREIGN KEY (id_lote) REFERENCES lote_produto (id_lote),
    CONSTRAINT ck_itemdevcli_quantidade CHECK (quantidade > 0)
);

-- ---------- Financeiro ----------

CREATE TABLE conta_pagar (
    id_conta_pagar   INT AUTO_INCREMENT,
    id_nf_fornecedor INT           NOT NULL,          -- RN23
    valor_original   DECIMAL(12,2) NOT NULL,
    vencimento       DATE          NOT NULL,
    status           VARCHAR(10)   NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT pk_conta_pagar PRIMARY KEY (id_conta_pagar),
    CONSTRAINT fk_contapagar_nf FOREIGN KEY (id_nf_fornecedor) REFERENCES nota_fiscal_fornecedor (id_nf_fornecedor),
    CONSTRAINT ck_contapagar_valor CHECK (valor_original > 0),
    CONSTRAINT ck_contapagar_status CHECK (status IN ('ABERTA', 'PARCIAL', 'QUITADA', 'CANCELADA'))
);

CREATE TABLE conta_receber (
    id_conta_receber INT AUTO_INCREMENT,
    id_venda         INT           NOT NULL,          -- RN23
    valor_original   DECIMAL(12,2) NOT NULL,
    vencimento       DATE          NOT NULL,
    status           VARCHAR(10)   NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT pk_conta_receber PRIMARY KEY (id_conta_receber),
    CONSTRAINT fk_contareceber_venda FOREIGN KEY (id_venda) REFERENCES venda (id_venda),
    CONSTRAINT ck_contareceber_valor CHECK (valor_original > 0),
    CONSTRAINT ck_contareceber_status CHECK (status IN ('ABERTA', 'PARCIAL', 'QUITADA', 'CANCELADA'))
);

CREATE TABLE movimentacao_financeira (
    id_movimento_fin INT AUTO_INCREMENT,
    id_conta_pagar   INT,
    id_conta_receber INT,
    tipo             VARCHAR(12)   NOT NULL,
    data             DATE          NOT NULL,
    valor            DECIMAL(12,2) NOT NULL,
    conta_bancaria   VARCHAR(40)   NOT NULL,
    referencia       VARCHAR(60)   NOT NULL,
    CONSTRAINT pk_movimento_fin PRIMARY KEY (id_movimento_fin),
    CONSTRAINT fk_movfin_contapagar FOREIGN KEY (id_conta_pagar) REFERENCES conta_pagar (id_conta_pagar),
    CONSTRAINT fk_movfin_contareceber FOREIGN KEY (id_conta_receber) REFERENCES conta_receber (id_conta_receber),
    CONSTRAINT ck_movfin_tipo CHECK (tipo IN ('PAGAMENTO', 'RECEBIMENTO')),
    CONSTRAINT ck_movfin_valor CHECK (valor > 0),
    CONSTRAINT ck_movfin_titulo CHECK (                      -- exatamente um dos dois títulos
        (id_conta_pagar IS NOT NULL AND id_conta_receber IS NULL) OR
        (id_conta_pagar IS NULL AND id_conta_receber IS NOT NULL))
);

CREATE TABLE conciliacao_financeira (
    id_conciliacao INT AUTO_INCREMENT,
    periodo        CHAR(7)     NOT NULL,      -- AAAA-MM
    conta_bancaria VARCHAR(40) NOT NULL,
    data_execucao  DATETIME    NOT NULL,
    id_responsavel INT         NOT NULL,
    status         VARCHAR(10) NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT pk_conciliacao PRIMARY KEY (id_conciliacao),
    CONSTRAINT fk_conciliacao_responsavel FOREIGN KEY (id_responsavel) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_conciliacao_status CHECK (status IN ('ABERTA', 'ENCERRADA'))
);

CREATE TABLE item_conciliacao (
    id_item_conciliacao INT AUTO_INCREMENT,
    id_conciliacao      INT         NOT NULL,
    id_movimento_fin    INT         NOT NULL,
    referencia_extrato  VARCHAR(60),
    valor_extrato       DECIMAL(12,2),
    situacao            VARCHAR(12) NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT pk_item_conciliacao PRIMARY KEY (id_item_conciliacao),
    CONSTRAINT fk_itemconc_conciliacao FOREIGN KEY (id_conciliacao) REFERENCES conciliacao_financeira (id_conciliacao),
    CONSTRAINT fk_itemconc_movimento FOREIGN KEY (id_movimento_fin) REFERENCES movimentacao_financeira (id_movimento_fin),
    CONSTRAINT ck_itemconc_situacao CHECK (situacao IN ('PENDENTE', 'CONCILIADO', 'DIVERGENTE'))
);

-- ---------- Qualidade / Recall ----------

CREATE TABLE recall (
    id_recall             INT AUTO_INCREMENT,
    id_lote_materia_prima INT          NOT NULL,     -- RN11
    id_funcionario        INT          NOT NULL,
    data_abertura         DATE         NOT NULL,
    motivo                VARCHAR(255) NOT NULL,
    status                VARCHAR(16)  NOT NULL DEFAULT 'ABERTO',
    data_encerramento     DATE,
    CONSTRAINT pk_recall PRIMARY KEY (id_recall),
    CONSTRAINT fk_recall_lote FOREIGN KEY (id_lote_materia_prima) REFERENCES lote_materia_prima (id_lote),
    CONSTRAINT fk_recall_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_recall_status CHECK (status IN ('ABERTO', 'EM_INVESTIGACAO', 'ENCERRADO'))
);

CREATE TABLE investigacao_recall (
    id_investigacao INT AUTO_INCREMENT,
    id_recall       INT          NOT NULL,
    data            DATETIME     NOT NULL,
    responsavel     INT          NOT NULL,
    descricao       VARCHAR(500) NOT NULL,
    evidencia       VARCHAR(500),
    conclusao       VARCHAR(500),
    CONSTRAINT pk_investigacao PRIMARY KEY (id_investigacao),
    CONSTRAINT fk_investigacao_recall FOREIGN KEY (id_recall) REFERENCES recall (id_recall),
    CONSTRAINT fk_investigacao_responsavel FOREIGN KEY (responsavel) REFERENCES funcionario (id_funcionario)
);

CREATE TABLE lote_afetado_recall (
    id_recall     INT,
    id_lote       INT,
    data_inclusao DATETIME     NOT NULL,
    justificativa VARCHAR(255) NOT NULL,
    CONSTRAINT pk_lote_afetado PRIMARY KEY (id_recall, id_lote),
    CONSTRAINT fk_loteafetado_recall FOREIGN KEY (id_recall) REFERENCES recall (id_recall),
    CONSTRAINT fk_loteafetado_lote FOREIGN KEY (id_lote) REFERENCES lote (id_lote)
);

CREATE TABLE comunicacao_recall (
    id_comunicacao  INT AUTO_INCREMENT,
    id_recall       INT          NOT NULL,
    id_cliente      INT          NOT NULL,
    data            DATETIME     NOT NULL,
    canal           VARCHAR(10)  NOT NULL,
    conteudo_resumo VARCHAR(500) NOT NULL,
    resposta        VARCHAR(500),
    responsavel     INT          NOT NULL,
    CONSTRAINT pk_comunicacao PRIMARY KEY (id_comunicacao),
    CONSTRAINT fk_comunicacao_recall FOREIGN KEY (id_recall) REFERENCES recall (id_recall),
    CONSTRAINT fk_comunicacao_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_comunicacao_responsavel FOREIGN KEY (responsavel) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_comunicacao_canal CHECK (canal IN ('EMAIL', 'TELEFONE', 'WHATSAPP', 'VISITA'))
);

CREATE TABLE providencia_recall (
    id_providencia INT AUTO_INCREMENT,
    id_recall      INT          NOT NULL,
    responsavel    INT          NOT NULL,
    acao           VARCHAR(255) NOT NULL,
    prazo          DATE         NOT NULL,
    data_execucao  DATE,
    status         VARCHAR(12)  NOT NULL DEFAULT 'PLANEJADA',
    resultado      VARCHAR(500),
    CONSTRAINT pk_providencia PRIMARY KEY (id_providencia),
    CONSTRAINT fk_providencia_recall FOREIGN KEY (id_recall) REFERENCES recall (id_recall),
    CONSTRAINT fk_providencia_responsavel FOREIGN KEY (responsavel) REFERENCES funcionario (id_funcionario),
    CONSTRAINT ck_providencia_status CHECK (status IN ('PLANEJADA', 'EM_ANDAMENTO', 'CONCLUIDA'))
);


/* =====================================================================
   INSERT
   ===================================================================== */

-- ---------- Cadastros ----------

INSERT INTO turno (descricao, horario_inicio, horario_fim) VALUES
('MANHA', '06:00', '14:00'),
('TARDE', '14:00', '22:00'),
('NOITE', '22:00', '06:00');

INSERT INTO maquina (nome, tipo, setor) VALUES
('Serra de fita SF-01',       'SERRA',          'Corte'),
('Torno CNC 01',              'TORNO_CNC',      'Usinagem'),
('Torno CNC 02',              'TORNO_CNC',      'Usinagem'),
('Linha de zincagem LZ-01',   'LINHA_ZINCAGEM', 'Zincagem'),
('Bancada de montagem BM-01', 'BANCADA',        'Montagem');

INSERT INTO funcionario (nome, cpf, cargo, setor, perfil_acesso) VALUES
('Carlos Mendes',        '11122233344', 'Comprador',                 'Compras',    'COMPRAS'),
('Ana Paula Ribeiro',    '22233344455', 'Conferente de recebimento', 'Estoque',    'ESTOQUE'),
('João Batista Silva',   '33344455566', 'Operador de serra',         'Produção',   'PRODUCAO'),
('Marcos Oliveira',      '44455566677', 'Operador de torno CNC',     'Produção',   'PRODUCAO'),
('Rita Farias',          '55566677788', 'Operadora de zincagem',     'Produção',   'PRODUCAO'),
('Pedro Henrique Costa', '66677788899', 'Montador',                  'Produção',   'PRODUCAO'),
('Luciana Prado',        '77788899900', 'Supervisora de produção',   'Produção',   'PRODUCAO'),
('Fernanda Lima',        '88899900011', 'Vendedora',                 'Vendas',     'VENDAS'),
('Roberto Alves',        '99900011122', 'Analista financeiro',       'Financeiro', 'FINANCEIRO'),
('Juliana Torres',       '10120230340', 'Coordenadora de qualidade', 'Qualidade',  'QUALIDADE_GESTAO');

INSERT INTO fornecedor (razao_social, cnpj, contato, telefone, logradouro, numero, bairro, cidade, uf, cep) VALUES
('Aços Paulista Distribuidora Ltda.',      '12345678000190', 'Sérgio Ramos',   '1140028922', 'Av. do Estado',      '5200', 'Cambuci',             'São Paulo', 'SP', '01516000'),
('Zincotec Insumos Químicos Ltda.',        '23456789000101', 'Patrícia Gomes', '1144556677', 'Rua das Indústrias', '310',  'Distrito Industrial', 'Jundiaí',   'SP', '13213000'),
('Hidrocomp Componentes Industriais S.A.', '34567890000112', 'Marcelo Dias',   '1932345566', 'Rod. Anhanguera',    'km 104', 'Nova Europa',       'Campinas',  'SP', '13065000');

INSERT INTO material (codigo, descricao, categoria, unidade_medida) VALUES
('MP-ACO1020', 'Barra de aço SAE 1020 Ø38 mm', 'MATERIA_PRIMA', 'kg'),
('MP-ACO1045', 'Barra de aço SAE 1045 Ø76 mm', 'MATERIA_PRIMA', 'kg'),
('IN-ZINCO',   'Ânodo de zinco',               'INSUMO',        'kg'),
('CP-ESFERA',  'Esfera inox 1/2"',             'COMPONENTE',    'un'),
('CP-ANEL',    'Anel de vedação PTFE 1/2"',    'COMPONENTE',    'un'),
('CP-MANOPLA', 'Manopla 1/2"',                 'COMPONENTE',    'un');

INSERT INTO produto (codigo, descricao, tipo) VALUES
('PI-VLV-CORTADO', 'Corpo de válvula cortado', 'INTERMEDIARIO'),   -- 1
('PI-VLV-USINADO', 'Corpo de válvula usinado', 'INTERMEDIARIO'),   -- 2
('PI-VLV-ZINCADO', 'Corpo de válvula zincado', 'INTERMEDIARIO'),   -- 3
('PA-VALVULA',     'Válvula esfera 1/2"',      'ACABADO'),         -- 4
('PI-FLG-CORTADO', 'Flange DN50 cortado',      'INTERMEDIARIO'),   -- 5
('PI-FLG-USINADO', 'Flange DN50 usinado',      'INTERMEDIARIO'),   -- 6
('PA-FLANGE',      'Flange DN50 zincado',      'ACABADO');         -- 7

INSERT INTO cliente (nome_razao_social, cpf_cnpj, tipo_cliente, telefone, email, cidade, uf) VALUES
('Distribuidora Hidráulica Paulista Ltda.', '45678901000123', 'PJ', '1133221100',  'compras@dhpaulista.com.br', 'São Paulo',   'SP'),
('Comercial HidroSul Ltda.',                '56789012000134', 'PJ', '4133224455',  'pedidos@hidrosul.com.br',   'Curitiba',    'PR'),
('Oficina Mecânica São Jorge Ltda.',        '67890123000145', 'PJ', '1145671234',  'oficina.sjorge@email.com',  'Guarulhos',   'SP'),
('José Roberto Nunes',                      '12312312387',    'PF', '11987654321', NULL,                        'Osasco',      'SP'),
('Indústria de Plásticos Ômega Ltda.',      '78901234000156', 'PJ', NULL,          'suprimentos@omega.ind.br',  'Santo André', 'SP');

-- ---------- Compras ----------

INSERT INTO pedido_compra (id_fornecedor, data_pedido, status) VALUES
(1, '2026-08-03', 'CONCLUIDO'),
(3, '2026-08-05', 'PARCIAL'),
(2, '2026-08-06', 'CONCLUIDO'),
(1, '2026-09-20', 'ABERTO');

INSERT INTO item_pedido_compra (id_pedido_compra, id_material, quantidade, preco_unitario) VALUES
(1, 1, 500, 9.80),
(1, 2, 300, 11.50),
(2, 4, 300, 4.20),
(2, 5, 300, 1.10),
(2, 6, 300, 3.50),
(3, 3, 100, 18.00),
(4, 1, 400, 9.90),
(4, 2, 200, 11.60);

INSERT INTO nota_fiscal_fornecedor (id_fornecedor, numero, serie, data_emissao) VALUES
(1, '45871', '1', '2026-08-10'),
(3, '10233', '1', '2026-08-11'),
(2, '7781',  '2', '2026-08-12'),
(1, '46120', '1', '2026-09-02');

INSERT INTO item_nota_fornecedor (id_nf_fornecedor, id_material, id_item_pedido, quantidade, preco_unitario) VALUES
(1, 1, 1,    500, 9.80),
(1, 2, 2,    300, 11.50),
(2, 4, 3,    300, 4.20),
(2, 5, 4,    300, 1.10),
(2, 6, 5,    200, 3.50),     -- faturado parcialmente
(3, 3, 6,    100, 18.00),
(4, 1, NULL, 300, 9.85);     -- compra sem pedido

INSERT INTO recebimento (id_item_nf, data_hora, quantidade_recebida, resultado_conferencia, id_responsavel) VALUES
(1, '2026-08-10 08:30', 300, 'CONFORME',  2),
(1, '2026-08-12 09:00', 200, 'CONFORME',  2),   -- recebimento parcial do mesmo item
(2, '2026-08-10 08:45', 300, 'CONFORME',  2),
(3, '2026-08-11 10:00', 300, 'CONFORME',  2),
(4, '2026-08-11 10:10', 300, 'CONFORME',  2),
(5, '2026-08-11 10:20', 200, 'CONFORME',  2),
(6, '2026-08-12 14:00', 100, 'CONFORME',  2),
(7, '2026-09-02 11:00', 300, 'REPROVADO', 2);

-- ---------- Lotes de matéria-prima ----------

INSERT INTO lote (codigo_lote, tipo_lote, data_criacao, quantidade_inicial, status) VALUES
('MP-2026-0001', 'MP', '2026-08-10 08:40', 300, 'DISPONIVEL'),   -- 1 aço 1020
('MP-2026-0002', 'MP', '2026-08-12 09:10', 200, 'DISPONIVEL'),   -- 2 aço 1020
('MP-2026-0003', 'MP', '2026-08-10 08:55', 300, 'DISPONIVEL'),   -- 3 aço 1045
('MP-2026-0004', 'MP', '2026-08-11 10:05', 300, 'DISPONIVEL'),   -- 4 esferas
('MP-2026-0005', 'MP', '2026-08-11 10:15', 300, 'DISPONIVEL'),   -- 5 anéis
('MP-2026-0006', 'MP', '2026-08-11 10:25', 200, 'DISPONIVEL'),   -- 6 manoplas
('MP-2026-0007', 'MP', '2026-08-12 14:10', 100, 'DISPONIVEL'),   -- 7 zinco
('MP-2026-0008', 'MP', '2026-09-02 11:10', 300, 'REPROVADO');    -- 8 aço reprovado (RN02)

INSERT INTO lote_materia_prima (id_lote, id_material, id_fornecedor, id_recebimento, numero_certificado, motivo_reprovacao) VALUES
(1, 1, 1, 1, 'C-88412', NULL),
(2, 1, 1, 2, 'C-88530', NULL),
(3, 2, 1, 3, 'C-90117', NULL),
(4, 4, 3, 4, NULL, NULL),
(5, 5, 3, 5, NULL, NULL),
(6, 6, 3, 6, NULL, NULL),
(7, 3, 2, 7, 'Z-311',   NULL),
(8, 1, 1, 8, 'C-91004', 'Dureza fora da especificação');

-- ---------- Eventos de produção ----------

INSERT INTO evento_producao (tipo_evento, id_maquina, id_funcionario, id_turno, data_hora_inicio, data_hora_fim, status_evento) VALUES
-- válvulas, leva 1 (aço do lote 1)
('CORTE',    1, 3, 1, '2026-08-13 07:00', '2026-08-13 10:00', 'ENCERRADO'),   -- 1
('USINAGEM', 2, 4, 1, '2026-08-14 06:30', '2026-08-14 13:30', 'ENCERRADO'),   -- 2
('ZINCAGEM', 4, 5, 2, '2026-08-15 14:30', '2026-08-15 20:00', 'ENCERRADO'),   -- 3
('MONTAGEM', 5, 6, 1, '2026-08-17 06:15', '2026-08-17 13:45', 'ENCERRADO'),   -- 4
-- válvulas, leva 2 (aço do lote 1)
('CORTE',    1, 3, 3, '2026-08-20 22:30', '2026-08-21 02:30', 'ENCERRADO'),   -- 5
('USINAGEM', 3, 4, 1, '2026-08-21 07:00', '2026-08-21 14:00', 'ENCERRADO'),   -- 6
('ZINCAGEM', 4, 5, 2, '2026-08-22 14:20', '2026-08-22 19:40', 'ENCERRADO'),   -- 7
('MONTAGEM', 5, 6, 2, '2026-08-24 14:10', '2026-08-24 21:30', 'ENCERRADO'),   -- 8
-- flanges (aço do lote 3)
('CORTE',    1, 3, 2, '2026-08-18 15:00', '2026-08-18 18:00', 'ENCERRADO'),   -- 9
('USINAGEM', 2, 4, 2, '2026-08-19 14:30', '2026-08-19 21:00', 'ENCERRADO'),   -- 10
('ZINCAGEM', 4, 5, 1, '2026-08-25 07:00', '2026-08-25 11:00', 'ENCERRADO'),   -- 11
-- evento em andamento, ainda sem lote de saída (RN05)
('CORTE',    1, 3, 1, '2026-09-28 07:00', NULL,               'ABERTO');      -- 12

-- ---------- Lotes de produto ----------

INSERT INTO lote (codigo_lote, tipo_lote, data_criacao, quantidade_inicial) VALUES
('PR-2026-0001', 'PR', '2026-08-13 10:05', 200),   --  9 corpo cortado
('PR-2026-0002', 'PR', '2026-08-14 13:35', 198),   -- 10 corpo usinado
('PR-2026-0003', 'PR', '2026-08-15 20:05', 198),   -- 11 corpo zincado
('PR-2026-0004', 'PR', '2026-08-17 13:50', 150),   -- 12 válvula
('PR-2026-0005', 'PR', '2026-08-21 02:35', 150),   -- 13 corpo cortado
('PR-2026-0006', 'PR', '2026-08-21 14:05', 150),   -- 14 corpo usinado
('PR-2026-0007', 'PR', '2026-08-22 19:45', 150),   -- 15 corpo zincado
('PR-2026-0008', 'PR', '2026-08-24 21:35', 50),    -- 16 válvula
('PR-2026-0009', 'PR', '2026-08-18 18:05', 60),    -- 17 flange cortado
('PR-2026-0010', 'PR', '2026-08-19 21:05', 60),    -- 18 flange usinado
('PR-2026-0011', 'PR', '2026-08-25 11:05', 60);    -- 19 flange zincado

INSERT INTO lote_produto (id_lote, id_produto, id_evento_geracao) VALUES
(9, 1, 1), (10, 2, 2), (11, 3, 3), (12, 4, 4),
(13, 1, 5), (14, 2, 6), (15, 3, 7), (16, 4, 8),
(17, 5, 9), (18, 6, 10), (19, 7, 11);

-- ---------- Consumo em produção ----------

INSERT INTO consumo_em_producao (id_evento, id_lote_consumido, quantidade_consumida) VALUES
(1, 1, 120),                                  -- corte: 120 kg de aço
(2, 9, 200),
(3, 10, 198), (3, 7, 6),                      -- zincagem: corpos + zinco
(4, 11, 150), (4, 4, 150), (4, 5, 150), (4, 6, 150),   -- montagem: corpo + componentes
(5, 1, 90),
(6, 13, 150),
(7, 14, 150), (7, 7, 5),
(8, 15, 50), (8, 4, 50), (8, 5, 50), (8, 6, 50),
(9, 3, 180),
(10, 17, 60),
(11, 18, 60), (11, 7, 4),
(12, 2, 80);                                  -- evento ainda aberto

-- ---------- Vendas ----------

INSERT INTO venda (id_cliente, id_funcionario, data_venda, forma_pagamento, numero_nota_fiscal) VALUES
(1, 8, '2026-08-26', 'BOLETO', '000101'),
(2, 8, '2026-08-28', 'PIX',    '000102'),
(3, 8, '2026-09-03', 'CARTAO', '000103'),
(4, 8, '2026-09-05', 'PIX',    '000104');

INSERT INTO item_venda (id_venda, id_lote_produto, quantidade, preco_unitario) VALUES
(1, 12, 100, 48.90),
(1, 19, 20,  62.00),
(2, 12, 30,  49.50),
(3, 16, 10,  52.00),
(3, 19, 5,   64.00),
(4, 12, 2,   55.00);

-- ---------- Devoluções ----------

INSERT INTO devolucao_cliente (id_venda, data, motivo, status) VALUES
(2, '2026-09-08', 'Vazamento na vedação após instalação', 'ANALISADA');
INSERT INTO item_devolucao_cliente (id_devolucao_cliente, id_lote, quantidade) VALUES
(1, 12, 5);

INSERT INTO devolucao_fornecedor (id_nf_fornecedor, data, motivo, status) VALUES
(4, '2026-09-03', 'Material reprovado na conferência', 'CONCLUIDA');
INSERT INTO item_devolucao_fornecedor (id_devolucao_fornecedor, id_lote, quantidade) VALUES
(1, 8, 300);

-- ---------- Movimentações de estoque (RN16: saldo = soma das movimentações) ----------

INSERT INTO movimentacao_estoque
(id_lote, tipo, quantidade_assinada, data_hora, id_responsavel, origem_tipo, origem_id, id_movimento_estornado, justificativa) VALUES
-- recebimentos
(1, 'RECEBIMENTO', 300, '2026-08-10 08:30', 2, 'RECEBIMENTO', 1, NULL, NULL),     -- 1
(2, 'RECEBIMENTO', 200, '2026-08-12 09:00', 2, 'RECEBIMENTO', 2, NULL, NULL),     -- 2
(3, 'RECEBIMENTO', 300, '2026-08-10 08:45', 2, 'RECEBIMENTO', 3, NULL, NULL),     -- 3
(4, 'RECEBIMENTO', 300, '2026-08-11 10:00', 2, 'RECEBIMENTO', 4, NULL, NULL),     -- 4
(5, 'RECEBIMENTO', 300, '2026-08-11 10:10', 2, 'RECEBIMENTO', 5, NULL, NULL),     -- 5
(6, 'RECEBIMENTO', 200, '2026-08-11 10:20', 2, 'RECEBIMENTO', 6, NULL, NULL),     -- 6
(7, 'RECEBIMENTO', 100, '2026-08-12 14:00', 2, 'RECEBIMENTO', 7, NULL, NULL),     -- 7
(8, 'RECEBIMENTO', 300, '2026-09-02 11:00', 2, 'RECEBIMENTO', 8, NULL, NULL),     -- 8
-- produção (consumo negativo, lote gerado positivo)
(1,  'CONSUMO',  -120, '2026-08-13 07:00', 3, 'EVENTO', 1, NULL, NULL),           -- 9
(9,  'PRODUCAO',  200, '2026-08-13 10:00', 3, 'EVENTO', 1, NULL, NULL),           -- 10
(9,  'CONSUMO',  -200, '2026-08-14 06:30', 4, 'EVENTO', 2, NULL, NULL),           -- 11
(10, 'PRODUCAO',  198, '2026-08-14 13:30', 4, 'EVENTO', 2, NULL, NULL),           -- 12
(10, 'CONSUMO',  -198, '2026-08-15 14:30', 5, 'EVENTO', 3, NULL, NULL),           -- 13
(7,  'CONSUMO',    -6, '2026-08-15 14:30', 5, 'EVENTO', 3, NULL, NULL),           -- 14
(11, 'PRODUCAO',  198, '2026-08-15 20:00', 5, 'EVENTO', 3, NULL, NULL),           -- 15
(11, 'CONSUMO',  -150, '2026-08-17 06:15', 6, 'EVENTO', 4, NULL, NULL),           -- 16
(4,  'CONSUMO',  -150, '2026-08-17 06:15', 6, 'EVENTO', 4, NULL, NULL),           -- 17
(5,  'CONSUMO',  -150, '2026-08-17 06:15', 6, 'EVENTO', 4, NULL, NULL),           -- 18
(6,  'CONSUMO',  -150, '2026-08-17 06:15', 6, 'EVENTO', 4, NULL, NULL),           -- 19
(12, 'PRODUCAO',  150, '2026-08-17 13:45', 6, 'EVENTO', 4, NULL, NULL),           -- 20
(1,  'CONSUMO',   -90, '2026-08-20 22:30', 3, 'EVENTO', 5, NULL, NULL),           -- 21
(13, 'PRODUCAO',  150, '2026-08-21 02:30', 3, 'EVENTO', 5, NULL, NULL),           -- 22
(13, 'CONSUMO',  -150, '2026-08-21 07:00', 4, 'EVENTO', 6, NULL, NULL),           -- 23
(14, 'PRODUCAO',  150, '2026-08-21 14:00', 4, 'EVENTO', 6, NULL, NULL),           -- 24
(14, 'CONSUMO',  -150, '2026-08-22 14:20', 5, 'EVENTO', 7, NULL, NULL),           -- 25
(7,  'CONSUMO',    -5, '2026-08-22 14:20', 5, 'EVENTO', 7, NULL, NULL),           -- 26
(15, 'PRODUCAO',  150, '2026-08-22 19:40', 5, 'EVENTO', 7, NULL, NULL),           -- 27
(15, 'CONSUMO',   -50, '2026-08-24 14:10', 6, 'EVENTO', 8, NULL, NULL),           -- 28
(4,  'CONSUMO',   -50, '2026-08-24 14:10', 6, 'EVENTO', 8, NULL, NULL),           -- 29
(5,  'CONSUMO',   -50, '2026-08-24 14:10', 6, 'EVENTO', 8, NULL, NULL),           -- 30
(6,  'CONSUMO',   -50, '2026-08-24 14:10', 6, 'EVENTO', 8, NULL, NULL),           -- 31
(16, 'PRODUCAO',   50, '2026-08-24 21:30', 6, 'EVENTO', 8, NULL, NULL),           -- 32
(3,  'CONSUMO',  -180, '2026-08-18 15:00', 3, 'EVENTO', 9, NULL, NULL),           -- 33
(17, 'PRODUCAO',   60, '2026-08-18 18:00', 3, 'EVENTO', 9, NULL, NULL),           -- 34
(17, 'CONSUMO',   -60, '2026-08-19 14:30', 4, 'EVENTO', 10, NULL, NULL),          -- 35
(18, 'PRODUCAO',   60, '2026-08-19 21:00', 4, 'EVENTO', 10, NULL, NULL),          -- 36
(18, 'CONSUMO',   -60, '2026-08-25 07:00', 5, 'EVENTO', 11, NULL, NULL),          -- 37
(7,  'CONSUMO',    -4, '2026-08-25 07:00', 5, 'EVENTO', 11, NULL, NULL),          -- 38
(19, 'PRODUCAO',   60, '2026-08-25 11:00', 5, 'EVENTO', 11, NULL, NULL),          -- 39
(2,  'CONSUMO',   -80, '2026-09-28 07:00', 3, 'EVENTO', 12, NULL, NULL),          -- 40
-- vendas
(12, 'VENDA', -100, '2026-08-26 12:00', 8, 'VENDA', 1, NULL, NULL),               -- 41
(19, 'VENDA',  -20, '2026-08-26 12:00', 8, 'VENDA', 1, NULL, NULL),               -- 42
(12, 'VENDA',  -30, '2026-08-28 12:00', 8, 'VENDA', 2, NULL, NULL),               -- 43
(16, 'VENDA',  -10, '2026-09-03 12:00', 8, 'VENDA', 3, NULL, NULL),               -- 44
(19, 'VENDA',   -5, '2026-09-03 12:00', 8, 'VENDA', 3, NULL, NULL),               -- 45
(12, 'VENDA',   -2, '2026-09-05 12:00', 8, 'VENDA', 4, NULL, NULL),               -- 46
-- devoluções
(8,  'DEVOLUCAO_FORNECEDOR', -300, '2026-09-03 09:00', 2, 'DEVOLUCAO_FORNECEDOR', 1, NULL, NULL),  -- 47
(12, 'DEVOLUCAO_CLIENTE',       5, '2026-09-08 15:00', 2, 'DEVOLUCAO_CLIENTE',    1, NULL, NULL),  -- 48
-- perda lançada errada, estorno e lançamento correto (RN18)
(4, 'PERDA',   -5, '2026-09-10 16:00', 2, 'INVENTARIO', 1, NULL, 'Esferas danificadas no manuseio'),        -- 49
(4, 'ESTORNO',  5, '2026-09-10 16:20', 2, 'MOVIMENTO', 49, 49,  'Quantidade digitada errada (5 em vez de 3)'), -- 50
(4, 'PERDA',   -3, '2026-09-10 16:21', 2, 'INVENTARIO', 1, NULL, 'Esferas danificadas no manuseio'),        -- 51
-- ajuste de inventário
(7, 'AJUSTE',  -1, '2026-09-30 17:00', 2, 'INVENTARIO', 2, NULL, 'Contagem física 1 kg abaixo do sistema'); -- 52

-- ---------- Ajustes de evento ----------

INSERT INTO ajuste_evento (id_evento, id_solicitante, id_aprovador, data_solicitacao, data_decisao, status_ajuste, justificativa, descricao_alteracao) VALUES
(3,  5, NULL, '2026-08-16 08:00', NULL,               'PENDENTE',  'Pesagem do zinco registrada a menor', 'Consumo de zinco: 6 kg para 7 kg'),
(10, 4, NULL, '2026-08-20 07:10', NULL,               'PENDENTE',  'Horário de término digitado errado',  'Fim do evento: 21:00 para 20:40'),
(7,  5, 7,    '2026-08-23 09:00', '2026-08-23 11:30', 'REJEITADO', 'Pedido de troca de turno no registro', 'Turno: TARDE para MANHA');

INSERT INTO item_ajuste_evento (id_ajuste, campo_alterado, valor_anterior, valor_novo) VALUES
(1, 'quantidade_consumida (evento 3, lote 7)', '6',                '7'),
(2, 'data_hora_fim',                           '2026-08-19 21:00', '2026-08-19 20:40'),
(3, 'id_turno',                                '2',                '1');

-- ---------- Financeiro ----------

INSERT INTO conta_pagar (id_nf_fornecedor, valor_original, vencimento, status) VALUES
(1, 4175.00, '2026-09-09', 'QUITADA'),
(1, 4175.00, '2026-11-09', 'ABERTA'),
(2, 2290.00, '2026-09-10', 'PARCIAL'),
(3, 1800.00, '2026-09-11', 'QUITADA'),
(4, 2955.00, '2026-10-02', 'CANCELADA');   -- material devolvido

INSERT INTO conta_receber (id_venda, valor_original, vencimento, status) VALUES
(1, 3065.00, '2026-09-25', 'QUITADA'),
(1, 3065.00, '2026-10-25', 'ABERTA'),
(2, 1485.00, '2026-08-28', 'QUITADA'),
(3,  840.00, '2026-10-03', 'QUITADA'),
(4,  110.00, '2026-09-05', 'QUITADA');

INSERT INTO movimentacao_financeira (id_conta_pagar, id_conta_receber, tipo, data, valor, conta_bancaria, referencia) VALUES
(1,    NULL, 'PAGAMENTO',   '2026-09-09', 4175.00, 'Itaú 1234-5', 'TED 0909-01'),
(3,    NULL, 'PAGAMENTO',   '2026-09-10', 1500.00, 'Itaú 1234-5', 'Boleto 10233 parcial'),
(4,    NULL, 'PAGAMENTO',   '2026-09-11', 1800.00, 'Itaú 1234-5', 'Boleto 7781'),
(NULL, 1,    'RECEBIMENTO', '2026-09-25', 3065.00, 'Itaú 1234-5', 'Boleto NF 000101 1/2'),
(NULL, 3,    'RECEBIMENTO', '2026-08-28', 1485.00, 'Itaú 1234-5', 'PIX NF 000102'),
(NULL, 4,    'RECEBIMENTO', '2026-10-03',  840.00, 'Itaú 1234-5', 'Cartão NF 000103'),
(NULL, 5,    'RECEBIMENTO', '2026-09-05',  110.00, 'Itaú 1234-5', 'PIX NF 000104');

INSERT INTO conciliacao_financeira (periodo, conta_bancaria, data_execucao, id_responsavel, status) VALUES
('2026-09', 'Itaú 1234-5', '2026-10-02 10:00', 9, 'ENCERRADA'),
('2026-10', 'Itaú 1234-5', '2026-11-01 09:00', 9, 'ABERTA');

INSERT INTO item_conciliacao (id_conciliacao, id_movimento_fin, referencia_extrato, valor_extrato, situacao) VALUES
(1, 1, 'EXT-0909', 4175.00, 'CONCILIADO'),
(1, 2, 'EXT-0910', 1500.00, 'CONCILIADO'),
(1, 3, 'EXT-0911', 1800.00, 'CONCILIADO'),
(1, 4, 'EXT-0925', 3065.00, 'CONCILIADO'),
(1, 7, 'EXT-0905',  110.00, 'CONCILIADO'),
(2, 6, 'EXT-1003',  815.64, 'DIVERGENTE'),   -- taxa do cartão
(2, 5, NULL,          NULL, 'PENDENTE');     -- lançado no período errado (excluído no DELETE)


/* =====================================================================
   SELECT
   ===================================================================== */

-- Produtos acabados (os únicos que podem ser vendidos - RN10)
SELECT codigo, descricao
FROM produto
WHERE tipo = 'ACABADO';

-- Clientes pessoa jurídica de SP
SELECT nome_razao_social, cpf_cnpj, cidade
FROM cliente
WHERE tipo_cliente = 'PJ' AND uf = 'SP'
ORDER BY nome_razao_social;

-- Eventos de produção ainda abertos
SELECT id_evento, tipo_evento, data_hora_inicio
FROM evento_producao
WHERE status_evento = 'ABERTO';

-- Ajustes aguardando aprovação
SELECT id_ajuste, id_evento, data_solicitacao, justificativa
FROM ajuste_evento
WHERE status_ajuste = 'PENDENTE';

-- Saldo de cada lote (soma das movimentações - RN16)
SELECT id_lote, SUM(quantidade_assinada) AS saldo
FROM movimentacao_estoque
GROUP BY id_lote
ORDER BY id_lote;


/* =====================================================================
   JOIN
   ===================================================================== */

-- Origem de cada lote de matéria-prima: material, fornecedor, NF e conferente
SELECT l.codigo_lote, m.descricao AS material, f.razao_social AS fornecedor,
       nf.numero AS nota_fiscal, r.data_hora AS recebido_em,
       r.resultado_conferencia, lmp.numero_certificado, fu.nome AS conferente
FROM lote_materia_prima lmp
JOIN lote l                    ON l.id_lote = lmp.id_lote
JOIN material m                ON m.id_material = lmp.id_material
JOIN fornecedor f              ON f.id_fornecedor = lmp.id_fornecedor
JOIN recebimento r             ON r.id_recebimento = lmp.id_recebimento
JOIN item_nota_fornecedor inf  ON inf.id_item_nf = r.id_item_nf
JOIN nota_fiscal_fornecedor nf ON nf.id_nf_fornecedor = inf.id_nf_fornecedor
JOIN funcionario fu            ON fu.id_funcionario = r.id_responsavel
ORDER BY l.codigo_lote;

-- Eventos com máquina, operador, turno, lote consumido e lote gerado
-- (LEFT JOIN para mostrar também o evento aberto, que ainda não gerou lote)
SELECT e.id_evento, e.tipo_evento, mq.nome AS maquina, fu.nome AS operador, t.descricao AS turno,
       lc.codigo_lote AS lote_consumido, c.quantidade_consumida,
       lg.codigo_lote AS lote_gerado
FROM evento_producao e
JOIN maquina mq            ON mq.id_maquina = e.id_maquina
JOIN funcionario fu        ON fu.id_funcionario = e.id_funcionario
JOIN turno t               ON t.id_turno = e.id_turno
JOIN consumo_em_producao c ON c.id_evento = e.id_evento
JOIN lote lc               ON lc.id_lote = c.id_lote_consumido
LEFT JOIN lote_produto lp  ON lp.id_evento_geracao = e.id_evento
LEFT JOIN lote lg          ON lg.id_lote = lp.id_lote
ORDER BY e.id_evento;

-- Histórico de compras de um cliente (RF11)
SELECT c.nome_razao_social, v.data_venda, v.numero_nota_fiscal,
       p.descricao AS produto, l.codigo_lote, iv.quantidade, iv.preco_unitario
FROM cliente c
JOIN venda v         ON v.id_cliente = c.id_cliente
JOIN item_venda iv   ON iv.id_venda = v.id_venda
JOIN lote_produto lp ON lp.id_lote = iv.id_lote_produto
JOIN produto p       ON p.id_produto = lp.id_produto
JOIN lote l          ON l.id_lote = lp.id_lote
WHERE c.id_cliente = 1;

-- Quantidade de vendas por cliente (LEFT JOIN mostra quem ainda não comprou)
SELECT c.nome_razao_social, COUNT(v.id_venda) AS qtd_vendas
FROM cliente c
LEFT JOIN venda v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome_razao_social
ORDER BY qtd_vendas DESC, c.nome_razao_social;

-- Extrato de movimentações de um lote, com responsável
SELECT l.codigo_lote, mv.data_hora, mv.tipo, mv.quantidade_assinada,
       fu.nome AS responsavel, mv.justificativa
FROM movimentacao_estoque mv
JOIN lote l         ON l.id_lote = mv.id_lote
JOIN funcionario fu ON fu.id_funcionario = mv.id_responsavel
WHERE l.codigo_lote = 'PR-2026-0004'
ORDER BY mv.data_hora;


/* =====================================================================
   UPDATE
   ===================================================================== */

-- Atualizar contato de cliente
UPDATE cliente
SET telefone = '11912345678', email = 'jr.nunes@email.com'
WHERE id_cliente = 4;

-- Lotes que ficaram com saldo zero passam para ESGOTADO
UPDATE lote
SET status = 'ESGOTADO'
WHERE status = 'DISPONIVEL'
  AND id_lote IN (SELECT id_lote
                  FROM movimentacao_estoque
                  GROUP BY id_lote
                  HAVING SUM(quantidade_assinada) = 0);

-- Ajuste de evento (RN15/RN21): aprovação por outra pessoa e aplicação
UPDATE ajuste_evento
SET status_ajuste = 'APROVADO', id_aprovador = 7, data_decisao = '2026-08-16 10:00'
WHERE id_ajuste = 1;

UPDATE consumo_em_producao
SET quantidade_consumida = 7
WHERE id_evento = 3 AND id_lote_consumido = 7;

INSERT INTO movimentacao_estoque
(id_lote, tipo, quantidade_assinada, data_hora, id_responsavel, origem_tipo, origem_id, justificativa)
VALUES (7, 'AJUSTE', -1, '2026-08-16 10:05', 7, 'AJUSTE_EVENTO', 1, 'Aplicação do ajuste 1: consumo de zinco de 6 para 7 kg');

UPDATE ajuste_evento
SET status_ajuste = 'APLICADO', data_aplicacao = '2026-08-16 10:05'
WHERE id_ajuste = 1;

-- Recall (RN11/RN12): abertura, registro do escopo e bloqueio dos lotes
INSERT INTO recall (id_lote_materia_prima, id_funcionario, data_abertura, motivo, status) VALUES
(1, 10, '2026-09-15', 'Devoluções por vazamento; suspeita de defeito no aço da corrida C-88412', 'EM_INVESTIGACAO');

INSERT INTO lote_afetado_recall (id_recall, id_lote, data_inclusao, justificativa) VALUES
(1, 1,  '2026-09-15 10:00', 'Lote de aço suspeito'),
(1, 9,  '2026-09-15 10:00', 'Corpo cortado do lote suspeito'),
(1, 10, '2026-09-15 10:00', 'Corpo usinado derivado'),
(1, 11, '2026-09-15 10:00', 'Corpo zincado derivado'),
(1, 12, '2026-09-15 10:00', 'Válvulas derivadas'),
(1, 13, '2026-09-15 10:00', 'Corpo cortado do lote suspeito'),
(1, 14, '2026-09-15 10:00', 'Corpo usinado derivado'),
(1, 15, '2026-09-15 10:00', 'Corpo zincado derivado'),
(1, 16, '2026-09-15 10:00', 'Válvulas derivadas');

UPDATE lote
SET status = 'BLOQUEADO'
WHERE status = 'DISPONIVEL'
  AND id_lote IN (SELECT id_lote FROM lote_afetado_recall WHERE id_recall = 1);

INSERT INTO investigacao_recall (id_recall, data, responsavel, descricao, evidencia) VALUES
(1, '2026-09-16 14:00', 10, 'Ensaio metalográfico em amostras do lote MP-2026-0001', 'Laudo LAB-118: inclusões acima do limite');

INSERT INTO comunicacao_recall (id_recall, id_cliente, data, canal, conteudo_resumo, resposta, responsavel) VALUES
(1, 1, '2026-09-17 09:00', 'EMAIL',    'Aviso de recall das válvulas do lote PR-2026-0004', 'Confirmou as peças em estoque', 10),
(1, 2, '2026-09-17 09:30', 'TELEFONE', 'Aviso de recall das válvulas do lote PR-2026-0004', NULL,                            10),
(1, 3, '2026-09-17 10:00', 'EMAIL',    'Aviso de recall das válvulas do lote PR-2026-0008', 'Agendou retirada',              10);

INSERT INTO providencia_recall (id_recall, responsavel, acao, prazo, data_execucao, status, resultado) VALUES
(1, 2,  'Separar os lotes bloqueados na área de quarentena', '2026-09-16', '2026-09-16', 'CONCLUIDA',    'Lotes isolados'),
(1, 10, 'Substituir as válvulas vendidas',                   '2026-10-15', NULL,         'EM_ANDAMENTO', NULL);

-- Lote reprovado já devolvido: inativado, nunca excluído (RN13)
UPDATE lote
SET status = 'INATIVADO'
WHERE id_lote = 8;

-- Pedido 2 encerrado (fornecedor cancelou o saldo não faturado)
UPDATE pedido_compra
SET status = 'CONCLUIDO'
WHERE id_pedido_compra = 2;


/* =====================================================================
   DELETE
   Obs.: lotes e movimentações de estoque não são excluídos (RN13, RN17).
   O DELETE é usado apenas em registros que ainda estão em elaboração.
   ===================================================================== */

-- Remover item de um pedido de compra que ainda está aberto
DELETE FROM item_pedido_compra
WHERE id_item_pedido = 8
  AND id_pedido_compra IN (SELECT id_pedido_compra FROM pedido_compra WHERE status = 'ABERTO');

-- Remover lançamento incluído por engano em uma conciliação aberta
DELETE FROM item_conciliacao
WHERE id_item_conciliacao = 7
  AND id_conciliacao IN (SELECT id_conciliacao FROM conciliacao_financeira WHERE status = 'ABERTA');


/* =====================================================================
   CONSULTAS GERENCIAIS
   ===================================================================== */

-- 1. Saldo atual de cada lote com descrição do item
SELECT l.codigo_lote,
       COALESCE(m.descricao, p.descricao) AS item,
       l.status,
       l.quantidade_inicial,
       SUM(mv.quantidade_assinada) AS saldo_atual
FROM lote l
LEFT JOIN lote_materia_prima lmp ON lmp.id_lote = l.id_lote
LEFT JOIN material m             ON m.id_material = lmp.id_material
LEFT JOIN lote_produto lp        ON lp.id_lote = l.id_lote
LEFT JOIN produto p              ON p.id_produto = lp.id_produto
JOIN movimentacao_estoque mv     ON mv.id_lote = l.id_lote
GROUP BY l.id_lote, l.codigo_lote, m.descricao, p.descricao, l.status, l.quantidade_inicial
ORDER BY l.codigo_lote;

-- 2. Rastreabilidade "para frente" (RF13): de um lote de aço até os clientes
--    aço → corte → usinagem → zincagem → montagem → venda
SELECT aco.codigo_lote  AS lote_aco,
       valv.codigo_lote AS lote_valvula,
       cli.nome_razao_social AS cliente,
       v.numero_nota_fiscal,
       v.data_venda,
       iv.quantidade
FROM lote aco
JOIN consumo_em_producao c1 ON c1.id_lote_consumido = aco.id_lote
JOIN lote_produto cortado   ON cortado.id_evento_geracao = c1.id_evento
JOIN consumo_em_producao c2 ON c2.id_lote_consumido = cortado.id_lote
JOIN lote_produto usinado   ON usinado.id_evento_geracao = c2.id_evento
JOIN consumo_em_producao c3 ON c3.id_lote_consumido = usinado.id_lote
JOIN lote_produto zincado   ON zincado.id_evento_geracao = c3.id_evento
JOIN consumo_em_producao c4 ON c4.id_lote_consumido = zincado.id_lote
JOIN lote_produto lpv       ON lpv.id_evento_geracao = c4.id_evento
JOIN lote valv              ON valv.id_lote = lpv.id_lote
JOIN item_venda iv          ON iv.id_lote_produto = lpv.id_lote
JOIN venda v                ON v.id_venda = iv.id_venda
JOIN cliente cli            ON cli.id_cliente = v.id_cliente
WHERE aco.codigo_lote = 'MP-2026-0001'
ORDER BY v.data_venda;

-- 3. Rastreabilidade "para trás" (RF12): de uma venda até o lote de aço e o fornecedor
SELECT v.numero_nota_fiscal,
       valv.codigo_lote AS lote_valvula,
       aco.codigo_lote  AS lote_aco,
       lmp.numero_certificado,
       f.razao_social   AS fornecedor
FROM venda v
JOIN item_venda iv          ON iv.id_venda = v.id_venda
JOIN lote valv              ON valv.id_lote = iv.id_lote_produto
JOIN lote_produto lpv       ON lpv.id_lote = valv.id_lote
JOIN consumo_em_producao c4 ON c4.id_evento = lpv.id_evento_geracao
JOIN lote_produto zincado   ON zincado.id_lote = c4.id_lote_consumido
JOIN consumo_em_producao c3 ON c3.id_evento = zincado.id_evento_geracao
JOIN lote_produto usinado   ON usinado.id_lote = c3.id_lote_consumido
JOIN consumo_em_producao c2 ON c2.id_evento = usinado.id_evento_geracao
JOIN lote_produto cortado   ON cortado.id_lote = c2.id_lote_consumido
JOIN consumo_em_producao c1 ON c1.id_evento = cortado.id_evento_geracao
JOIN lote aco               ON aco.id_lote = c1.id_lote_consumido
JOIN lote_materia_prima lmp ON lmp.id_lote = aco.id_lote
JOIN fornecedor f           ON f.id_fornecedor = lmp.id_fornecedor
WHERE v.numero_nota_fiscal = '000102';

-- 4. Resumo do recall: lotes envolvidos, unidades vendidas e clientes atingidos
SELECT r.id_recall, r.status, r.data_abertura,
       (SELECT COUNT(*) FROM lote_afetado_recall la WHERE la.id_recall = r.id_recall) AS lotes_afetados,
       (SELECT COUNT(*) FROM lote_afetado_recall la
          JOIN lote l ON l.id_lote = la.id_lote
         WHERE la.id_recall = r.id_recall AND l.status = 'BLOQUEADO') AS lotes_bloqueados,
       (SELECT SUM(iv.quantidade) FROM item_venda iv
         WHERE iv.id_lote_produto IN (SELECT id_lote FROM lote_afetado_recall WHERE id_recall = r.id_recall)) AS unidades_vendidas,
       (SELECT COUNT(DISTINCT v.id_cliente) FROM venda v
          JOIN item_venda iv ON iv.id_venda = v.id_venda
         WHERE iv.id_lote_produto IN (SELECT id_lote FROM lote_afetado_recall WHERE id_recall = r.id_recall)) AS clientes_atingidos
FROM recall r;

-- 5. Produção por etapa, máquina e turno
SELECT e.tipo_evento, mq.nome AS maquina, t.descricao AS turno,
       COUNT(*) AS qtd_eventos,
       SUM(l.quantidade_inicial) AS pecas_produzidas,
       SUM(TIMESTAMPDIFF(MINUTE, e.data_hora_inicio, e.data_hora_fim)) AS minutos_trabalhados
FROM evento_producao e
JOIN maquina mq      ON mq.id_maquina = e.id_maquina
JOIN turno t         ON t.id_turno = e.id_turno
JOIN lote_produto lp ON lp.id_evento_geracao = e.id_evento
JOIN lote l          ON l.id_lote = lp.id_lote
GROUP BY e.tipo_evento, mq.nome, t.descricao
ORDER BY e.tipo_evento, mq.nome;

-- 6. Faturamento por mês e por cliente
SELECT DATE_FORMAT(v.data_venda, '%Y-%m') AS mes,
       c.nome_razao_social,
       SUM(iv.quantidade * iv.preco_unitario) AS faturamento
FROM venda v
JOIN cliente c     ON c.id_cliente = v.id_cliente
JOIN item_venda iv ON iv.id_venda = v.id_venda
GROUP BY DATE_FORMAT(v.data_venda, '%Y-%m'), c.nome_razao_social
ORDER BY mes, faturamento DESC;

-- 7. Produtos mais vendidos
SELECT p.descricao,
       SUM(iv.quantidade) AS unidades_vendidas,
       SUM(iv.quantidade * iv.preco_unitario) AS receita
FROM item_venda iv
JOIN lote_produto lp ON lp.id_lote = iv.id_lote_produto
JOIN produto p       ON p.id_produto = lp.id_produto
GROUP BY p.descricao
ORDER BY receita DESC;

-- 8. Reprovações no recebimento por fornecedor
SELECT f.razao_social,
       COUNT(*) AS recebimentos,
       SUM(CASE WHEN r.resultado_conferencia = 'REPROVADO' THEN 1 ELSE 0 END) AS reprovados
FROM recebimento r
JOIN item_nota_fornecedor inf  ON inf.id_item_nf = r.id_item_nf
JOIN nota_fiscal_fornecedor nf ON nf.id_nf_fornecedor = inf.id_nf_fornecedor
JOIN fornecedor f              ON f.id_fornecedor = nf.id_fornecedor
GROUP BY f.razao_social
ORDER BY reprovados DESC, f.razao_social;

-- 9. Contas a receber em aberto, com valor já recebido
SELECT c.nome_razao_social, cr.id_conta_receber, cr.vencimento, cr.valor_original,
       (SELECT COALESCE(SUM(mf.valor), 0) FROM movimentacao_financeira mf
         WHERE mf.id_conta_receber = cr.id_conta_receber) AS valor_recebido,
       DATEDIFF('2026-11-01', cr.vencimento) AS dias_em_atraso
FROM conta_receber cr
JOIN venda v   ON v.id_venda = cr.id_venda
JOIN cliente c ON c.id_cliente = v.id_cliente
WHERE cr.status IN ('ABERTA', 'PARCIAL');

-- 10. Total pago e recebido por mês (fluxo de caixa realizado)
SELECT DATE_FORMAT(data, '%Y-%m') AS mes,
       SUM(CASE WHEN tipo = 'RECEBIMENTO' THEN valor ELSE 0 END) AS entradas,
       SUM(CASE WHEN tipo = 'PAGAMENTO'   THEN valor ELSE 0 END) AS saidas
FROM movimentacao_financeira
GROUP BY DATE_FORMAT(data, '%Y-%m')
ORDER BY mes;


/* =====================================================================
   CONSULTAS DE AUDITORIA
   ===================================================================== */

-- 1. Quem registrou cada tipo de movimentação de estoque (RNF09)
SELECT fu.nome, fu.perfil_acesso, mv.tipo, COUNT(*) AS qtd_movimentos
FROM movimentacao_estoque mv
JOIN funcionario fu ON fu.id_funcionario = mv.id_responsavel
GROUP BY fu.nome, fu.perfil_acesso, mv.tipo
ORDER BY fu.nome, mv.tipo;

-- 2. Estornos e o movimento original que corrigiram (RN18)
SELECT est.id_movimento AS estorno, est.data_hora, est.quantidade_assinada,
       ori.id_movimento AS movimento_original, ori.tipo, ori.quantidade_assinada AS qtd_original,
       est.justificativa
FROM movimentacao_estoque est
JOIN movimentacao_estoque ori ON ori.id_movimento = est.id_movimento_estornado;

-- 3. Perdas e ajustes de inventário com responsável e justificativa (RP09)
SELECT mv.data_hora, l.codigo_lote, mv.tipo, mv.quantidade_assinada,
       fu.nome AS responsavel, mv.justificativa
FROM movimentacao_estoque mv
JOIN lote l         ON l.id_lote = mv.id_lote
JOIN funcionario fu ON fu.id_funcionario = mv.id_responsavel
WHERE mv.tipo IN ('PERDA', 'AJUSTE')
ORDER BY mv.data_hora;

-- 4. Ajustes de evento: solicitante, aprovador e valores antes/depois (RN15)
SELECT a.id_ajuste, a.id_evento, a.status_ajuste,
       sol.nome AS solicitante, apr.nome AS aprovador,
       i.campo_alterado, i.valor_anterior, i.valor_novo
FROM ajuste_evento a
JOIN funcionario sol      ON sol.id_funcionario = a.id_solicitante
LEFT JOIN funcionario apr ON apr.id_funcionario = a.id_aprovador
JOIN item_ajuste_evento i ON i.id_ajuste = a.id_ajuste
ORDER BY a.id_ajuste;

-- 5. Lotes com saldo negativo (deve retornar vazio)
SELECT id_lote, SUM(quantidade_assinada) AS saldo
FROM movimentacao_estoque
GROUP BY id_lote
HAVING SUM(quantidade_assinada) < 0;

-- 6. Lotes reprovados que foram consumidos na produção (deve retornar vazio - RP06)
SELECT l.codigo_lote, c.id_evento
FROM consumo_em_producao c
JOIN lote_materia_prima lmp ON lmp.id_lote = c.id_lote_consumido
JOIN recebimento r          ON r.id_recebimento = lmp.id_recebimento
JOIN lote l                 ON l.id_lote = lmp.id_lote
WHERE r.resultado_conferencia = 'REPROVADO';

-- 7. Eventos encerrados que não geraram lote (deve retornar vazio - RN05)
SELECT e.id_evento, e.tipo_evento
FROM evento_producao e
LEFT JOIN lote_produto lp ON lp.id_evento_geracao = e.id_evento
WHERE e.status_evento = 'ENCERRADO'
  AND lp.id_lote IS NULL;

-- 8. Itens de nota fiscal recebidos sem pedido de compra
SELECT nf.numero AS nota_fiscal, f.razao_social, m.descricao, inf.quantidade
FROM item_nota_fornecedor inf
JOIN nota_fiscal_fornecedor nf ON nf.id_nf_fornecedor = inf.id_nf_fornecedor
JOIN fornecedor f              ON f.id_fornecedor = nf.id_fornecedor
JOIN material m                ON m.id_material = inf.id_material
WHERE inf.id_item_pedido IS NULL;

-- 9. Vendas sem conta a receber (deve retornar vazio - RN23)
SELECT v.id_venda, v.numero_nota_fiscal
FROM venda v
LEFT JOIN conta_receber cr ON cr.id_venda = v.id_venda
WHERE cr.id_conta_receber IS NULL;

-- 10. Conciliação: diferenças entre o sistema e o extrato (RN24)
SELECT cf.periodo, mf.referencia, mf.valor AS valor_sistema, ic.valor_extrato,
       ic.valor_extrato - mf.valor AS diferenca, ic.situacao
FROM item_conciliacao ic
JOIN conciliacao_financeira cf  ON cf.id_conciliacao = ic.id_conciliacao
JOIN movimentacao_financeira mf ON mf.id_movimento_fin = ic.id_movimento_fin
WHERE ic.situacao <> 'CONCILIADO';

-- 11. Clientes atingidos pelo recall que ainda não foram comunicados (RN25)
SELECT DISTINCT c.nome_razao_social, v.numero_nota_fiscal
FROM lote_afetado_recall la
JOIN item_venda iv ON iv.id_lote_produto = la.id_lote
JOIN venda v       ON v.id_venda = iv.id_venda
JOIN cliente c     ON c.id_cliente = v.id_cliente
WHERE la.id_recall = 1
  AND c.id_cliente NOT IN (SELECT id_cliente FROM comunicacao_recall WHERE id_recall = 1);
