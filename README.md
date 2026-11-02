# Projeto ERP – Metalúrgica Vértice

**ERP de rastreabilidade industrial: do modelo conceitual ao banco de dados implementado**

Projeto Integrador da disciplina de Modelagem de Dados, do curso de Engenharia de Software da Universidade Cidade de São Paulo (2026).

> A Metalúrgica Vértice é uma empresa fictícia. Todos os nomes de pessoas, clientes, fornecedores e transações usados nos dados de teste também são fictícios.

---

## Sumário

1. [Identificação do projeto](#1-identificação-do-projeto)
2. [Empresa e problema](#2-empresa-e-problema)
3. [Solução proposta](#3-solução-proposta)
4. [Requisitos e regras de negócio](#4-requisitos-e-regras-de-negócio)
5. [DER atualizado](#5-der-atualizado)
6. [Modelo lógico](#6-modelo-lógico)
7. [Normalização](#7-normalização)
8. [Dicionário de dados](#8-dicionário-de-dados)
9. [Implementação SQL](#9-implementação-sql)
10. [Massa de dados](#10-massa-de-dados)
11. [Consultas gerenciais](#11-consultas-gerenciais)
12. [Consultas de auditoria](#12-consultas-de-auditoria)
13. [Potencial para BI e IA](#13-potencial-para-bi-e-ia)
14. [Evolução do projeto](#14-evolução-do-projeto)
15. [Como executar](#15-como-executar)
16. [Estrutura do repositório](#16-estrutura-do-repositório)
17. [Conclusão](#17-conclusão)

---

## 1. Identificação do projeto

| Item | Descrição |
|---|---|
| Disciplina | Modelagem de Dados – Projeto Integrador |
| Curso | Engenharia de Software |
| Instituição | Universidade Cidade de São Paulo |
| Professor | Clóvis Ferraro |
| Etapa | Entrega final |
| SGBD de referência | MySQL 8.0 ou superior |

## 2. Empresa e problema

A **Metalúrgica Vértice Ltda.** é uma indústria de pequeno porte que fabrica flanges de aço e válvulas esfera. O corpo das peças é produzido internamente, passando por corte, usinagem em torno CNC e zincagem. No caso das válvulas, há ainda uma montagem final com componentes comprados de terceiros, como esferas, vedações e manoplas.

A empresa cresceu sem organizar suas informações:

- o recebimento de matéria-prima é anotado em caderno, sem número de lote padronizado;
- os certificados de qualidade do aço ficam arquivados em papel;
- a produção é controlada em planilhas soltas, sem padrão entre os turnos;
- as vendas ficam num sistema de nota fiscal sem ligação com a produção;
- o cadastro de clientes está duplicado.

**O problema central:** hoje não é possível descobrir, a partir de uma válvula vendida, de qual lote de aço ela veio. Também não é possível fazer o caminho inverso, e saber quais peças e clientes foram atingidos por um lote de aço com defeito. Na prática, um recall vira um recall total, com custo alto e risco para clientes e para a reputação da empresa.

## 3. Solução proposta

Um banco de dados para um ERP centrado na **rastreabilidade ponta a ponta por lote**. A espinha dorsal do modelo é a cadeia:

```
LOTE → EVENTO_PRODUCAO → CONSUMO_EM_PRODUCAO → novo LOTE
```

Cada etapa de produção consome lotes e gera um novo lote. Isso permite percorrer a cadeia nos dois sentidos:

- **para frente:** lote de aço → lotes intermediários → lote acabado → vendas → clientes;
- **para trás:** peça vendida → lotes de origem → fornecedor e nota fiscal.

Em torno desse núcleo, o modelo cobre:

- compras, notas fiscais e recebimentos parciais;
- estoque registrado como livro-razão de movimentações;
- ajustes de produção com aprovação e histórico do antes e depois;
- vendas e devoluções;
- controle financeiro operacional (contas a pagar e a receber e conciliação);
- recall com investigação, comunicação aos clientes e providências.

## 4. Requisitos e regras de negócio

O documento completo traz:

- 23 requisitos funcionais (RF01 a RF23);
- 9 requisitos não funcionais (RNF01 a RNF09);
- 25 regras de negócio (RN01 a RN25);
- 11 restrições e políticas organizacionais.

Algumas regras que orientam o modelo:

| Regra | O que garante |
|---|---|
| Lote nunca é excluído, apenas inativado | Preserva a cadeia de rastreabilidade de peças já vendidas |
| Evento só é encerrado com consumo registrado | Não existe lote produzido sem origem conhecida |
| Saldo de estoque é a soma das movimentações | Devoluções, perdas, ajustes e estornos sempre entram no cálculo |
| Ajuste de evento exige solicitante e aprovador diferentes | Separação de funções e trilha de auditoria |
| Rastreabilidade é por lote, não por número de série | Define a granularidade do sistema nesta etapa |
| Material reprovado no recebimento gera lote próprio | O histórico da devolução ao fornecedor não se perde |

📄 Detalhes: [`docs/requisitos/`](docs/requisitos/)

## 5. DER atualizado

![DER do ERP da Metalúrgica Vértice](docs/diagramas/DER_Metalurgica_Vertice.png)

O DER está dividido em duas visões que compartilham as entidades de ligação:

- **Visão 1:** núcleo da rastreabilidade, produção, estoque e qualidade.
- **Visão 2:** compras, recebimentos e financeiro.

## 6. Modelo lógico

O modelo relacional tem **36 tabelas**. Na conversão do DER:

- cada entidade virou uma tabela;
- cada relacionamento 1:N virou uma chave estrangeira no lado N;
- cada relacionamento N:N virou uma tabela associativa.

**Chaves compostas** (vindas de relacionamentos N:N):

| Tabela | Chave primária | Por que é composta |
|---|---|---|
| CONSUMO_EM_PRODUCAO | (id_evento, id_lote_consumido) | Um evento consome vários lotes, e um lote pode ser consumido em vários eventos |
| ITEM_VENDA | (id_venda, id_lote_produto) | Uma venda inclui vários lotes, e um lote pode ser vendido em várias vendas |
| LOTE_AFETADO_RECALL | (id_recall, id_lote) | Um recall abrange vários lotes, e um lote pode aparecer em mais de um recall |

As demais tabelas associativas, como itens de nota fiscal, de pedido e de devolução, usam identificador próprio. Assim cada item pode ter histórico individual.

**Especialização:** LOTE é o supertipo, com os subtipos LOTE_MATERIA_PRIMA e LOTE_PRODUTO. Cada subtipo usa como chave o mesmo `id_lote` do supertipo (PK e FK ao mesmo tempo).

**Restrições aplicadas no banco:**

| Restrição | Onde é usada | Regra que protege |
|---|---|---|
| PRIMARY KEY / UNIQUE | Identificadores, CNPJ, CPF e códigos internos | Não há registros duplicados |
| FOREIGN KEY | Compras, recebimento, consumo, venda, devolução, pagamento e recall | Não há referência a registro inexistente |
| NOT NULL | Responsável, quantidade e datas obrigatórias | O processo tem o preenchimento mínimo |
| CHECK | Quantidades e valores positivos, domínios de status e categoria | Não entra valor inválido num registro |

Algumas regras dependem de várias tabelas e ficam para validação na aplicação. É o caso de saldo não negativo, venda só de lote liberado e aplicação de ajuste só depois de aprovado.

📄 Diagramas do modelo lógico: [`docs/diagramas/`](docs/diagramas/)

## 7. Normalização

A normalização foi verificada em situações reais do projeto, sem criar tabelas com erros só para exemplificar.

**1FN – um campo, um valor**

| Antes | Problema | Depois |
|---|---|---|
| NF com `materiais = [aço, esfera, vedação]` | Lista dentro de um campo | NOTA_FISCAL_FORNECEDOR e ITEM_NOTA_FORNECEDOR, uma linha por material |
| `endereco` composto | Campo não atômico | `logradouro`, `cidade`, `uf` e `cep` em colunas separadas |

**2FN – depende da chave toda**

Nas tabelas com chave composta, os atributos dependem da combinação completa. Por exemplo: `(id_venda, id_lote_produto) → quantidade, preco_unitario`. O preço é negociado naquela venda, para aquele lote, e não é um dado do cadastro do lote.

**3FN – sem dependência transitiva**

| Dependência encontrada | Risco | Decisão |
|---|---|---|
| id_venda → id_cliente → nome_razao_social | Nome do cliente repetido e divergente nas vendas | VENDA guarda só `id_cliente`; o nome fica em CLIENTE |
| id_lote_materia_prima → id_recebimento → material e fornecedor | Cópias de fornecedor e material poderiam divergir | O lote guarda só `id_recebimento`; fornecedor e material vêm do documento de origem |
| id_lote → movimentações → saldo | Saldo gravado ficaria desatualizado após devolução ou estorno | O saldo é calculado na visão `VW_SALDO_LOTE` |

📄 Documentação completa: [`docs/normalizacao/`](docs/normalizacao/)

## 8. Dicionário de dados

O dicionário documenta as 36 tabelas do banco implementado. Para cada atributo, informa tipo, tamanho, chave (PK/FK), se aceita nulo e a regra ou restrição.

📄 [`docs/dicionario-dados/`](docs/dicionario-dados/)

## 9. Implementação SQL

| Arquivo | Conteúdo |
|---|---|
| [`sql/ddl/01_estrutura.sql`](sql/ddl/01_estrutura.sql) | CREATE DATABASE, as 36 tabelas, PKs, FKs, constraints e quatro visões |
| [`sql/dados/02_massa_de_dados.sql`](sql/dados/02_massa_de_dados.sql) | INSERT da massa de dados fictícia |
| [`sql/consultas/03_consultas.sql`](sql/consultas/03_consultas.sql) | SELECT e JOIN: consultas gerenciais e de auditoria |
| [`sql/consultas/04_update_delete.sql`](sql/consultas/04_update_delete.sql) | Demonstração de UPDATE e DELETE dentro de transação revertida |

**Decisões de implementação:**

- **IDs explícitos na massa de testes**, sem depender de AUTO_INCREMENT. Isso facilita reproduzir os vínculos entre as tabelas.
- **Visões calculam valores derivados**, como saldo do lote, total da venda e saldo dos títulos. Esses valores não ficam gravados em colunas.
- **DELETE não é usado em registros com histórico**: lote, movimento, consumo, venda, documento fiscal e recall. A demonstração de DELETE atua só sobre um cadastro temporário sem vínculos.

Exemplo da tabela associativa com chave composta:

```sql
CREATE TABLE CONSUMO_EM_PRODUCAO (
    id_evento            INTEGER       NOT NULL,
    id_lote_consumido    INTEGER       NOT NULL,
    quantidade_consumida DECIMAL(14,3) NOT NULL,
    PRIMARY KEY (id_evento, id_lote_consumido),
    CHECK (quantidade_consumida > 0),
    FOREIGN KEY (id_evento)         REFERENCES EVENTO_PRODUCAO(id_evento),
    FOREIGN KEY (id_lote_consumido) REFERENCES LOTE(id_lote)
);
```

## 10. Massa de dados

A massa de testes tem **118 registros fictícios**, coerentes entre si e montados para exercitar uma cadeia completa:

```
Lote de aço 101 → corte (evento 1) → lote 201 → usinagem (2) → lote 202
→ zincagem (3) → lote 203 → montagem (4) → válvula pronta, lote 204
→ vendas 1 e 2 → Distribuidora Industrial Beta e Oficina Hidráulica Gama
```

Ela inclui:

- uma nota fiscal com três materiais;
- recebimentos;
- movimentações com perda, ajuste de inventário e estorno;
- uma devolução de cliente;
- um ajuste de produção aprovado;
- contas a pagar e a receber;
- uma conciliação;
- um recall com investigação e comunicação aos clientes.

**Casos testados:**

| Caso | Resultado esperado |
|---|---|
| Rastrear o lote 101 para frente | Encontra os lotes 101 → 201 → 202 → 203 → 204 |
| Clientes afetados pelo lote 101 | Duas vendas e dois clientes |
| Saldo do lote 101 (entrada 100, consumo 40, perda 2, ajuste −1, estorno +1) | 58 unidades |
| Inserir item de venda com lote inexistente | O banco rejeita a inserção (FK) |
| Inserir consumo com quantidade negativa | O banco rejeita a inserção (CHECK) |

## 11. Consultas gerenciais

Cada consulta parte de uma pergunta do negócio:

| Código | Pergunta | Decisão que apoia |
|---|---|---|
| Q01 | Qual é o saldo por lote e quais estão bloqueados? | Priorizar liberação ou descarte de estoque |
| Q02 | Quanto foi vendido para cada cliente? | Definir prioridades comerciais |
| Q03 | Quanto ainda falta receber e pagar? | Planejar o caixa |
| Q04 | Quais lotes vieram do lote de aço 101? | Delimitar o escopo de um recall |
| Q05 | Quais clientes receberam peças do lote suspeito 101? | Comunicar só os clientes realmente afetados |
| Q10 | Quantos materiais distintos tem a NF 87002? | Conferir o recebimento |
| Q11 | Qual é o histórico de ações do recall 1? | Acompanhar e encerrar o recall |

Exemplo: consulta recursiva que encontra os clientes afetados a partir de um lote de matéria-prima.

```sql
WITH RECURSIVE afetados(id_lote, nivel) AS (
    SELECT 101, 0
    UNION ALL
    SELECT lp.id_lote, a.nivel + 1
    FROM afetados a
    JOIN CONSUMO_EM_PRODUCAO cp ON cp.id_lote_consumido = a.id_lote
    JOIN LOTE_PRODUTO lp        ON lp.id_evento_geracao = cp.id_evento
    WHERE a.nivel < 10
)
SELECT DISTINCT c.nome_razao_social, v.id_venda, iv.id_lote_produto
FROM afetados a
JOIN ITEM_VENDA iv ON iv.id_lote_produto = a.id_lote
JOIN VENDA v       ON v.id_venda = iv.id_venda
JOIN CLIENTE c     ON c.id_cliente = v.id_cliente
ORDER BY c.nome_razao_social;
```

## 12. Consultas de auditoria

Estas consultas procuram situações que merecem verificação:

| Código | O que verifica |
|---|---|
| Q06 | Lotes com saldo negativo ou entradas sem movimento correspondente |
| Q07 | Ajustes aplicados sem aprovação ou aprovados pela mesma pessoa que solicitou |
| Q08 | Títulos com pagamentos ou recebimentos acima do valor original |
| Q09 | Movimentos estornados e a contrapartida registrada |
| Q12 | Eventos encerrados sem lote de saída |
| Q13 | Diferenças entre o extrato bancário e as movimentações financeiras |

Resultado vazio na massa de testes significa que aquele cenário não tem a inconsistência. Não elimina a necessidade de prevenção nas transações reais.

## 13. Potencial para BI e IA

Cada linha segue o raciocínio problema → dados → análise → benefício:

| Problema de gestão | Dados usados | Indicador de BI | Possibilidade de IA | Benefício |
|---|---|---|---|---|
| Demora para identificar lote com risco | LOTE, CONSUMO_EM_PRODUCAO, VENDA, RECALL | Tempo para localizar clientes; volume afetado | Priorizar investigações com base em padrões de não conformidade | Recall menor, mais rápido e mais barato |
| Divergências de estoque | MOVIMENTACAO_ESTOQUE, LOTE, EVENTO_PRODUCAO | Perdas por período; ajustes por motivo | Sinalizar movimentos atípicos para revisão | Redução de perdas |
| Atrasos em compras | PEDIDO_COMPRA, ITEM_NOTA_FORNECEDOR, RECEBIMENTO | Pedidos entregues parcialmente; divergências | Prever risco de atraso por fornecedor | Produção sem parada por falta de material |
| Fluxo financeiro | CONTA_PAGAR, CONTA_RECEBER, MOVIMENTACAO_FINANCEIRA | Caixa previsto x realizado; títulos vencidos | Estimar recebimentos futuros | Planejamento de caixa mais confiável |
| Qualidade e recall | INVESTIGACAO_RECALL, COMUNICACAO_RECALL, PROVIDENCIA_RECALL | Prazo médio de tratativa; ações pendentes | Agrupar motivos recorrentes | Ações preventivas na origem do problema |

As possibilidades de IA são propostas, e não sistemas implementados. Para usá-las, seria preciso ter histórico suficiente, métricas de desempenho e validação humana das decisões de qualidade e segurança.

## 14. Evolução do projeto

Principais mudanças da primeira para a entrega final, a partir da devolutiva do professor:

| Ponto | Como era | Como ficou |
|---|---|---|
| Estoque | Saldo = quantidade inicial − consumo − venda | Livro-razão com entradas, consumos, vendas, devoluções, perdas, ajustes e estornos |
| Ajustes de produção | Justificativa e aprovação pouco detalhadas | AJUSTE_EVENTO com etapas e ITEM_AJUSTE_EVENTO com valor anterior e novo |
| Geração de lotes | Relação evento–lote obrigatória desde a abertura | O lote de produto só é criado no encerramento validado do evento (0,1 → 1,1) |
| Recall | Abertura e lista de clientes, sem histórico | Investigação, lotes abrangidos, comunicações e providências |
| Rastreabilidade | Granularidade não definida | Rastreabilidade por lote, sem número de série |
| Compras | Nota fiscal como atributo do lote | NF e itens próprios, pedidos, recebimentos parciais e devoluções |
| Financeiro | Excluído por causa da contabilidade terceirizada | Contas a pagar e a receber, baixas e conciliação operacional |
| Requisitos não funcionais | Metas genéricas | Metas verificáveis e critérios de aceite |

O histórico de versões deste repositório registra a evolução do trabalho ao longo do semestre.

## 15. Como executar

1. Tenha um servidor **MySQL 8.0 ou superior**. A consulta recursiva usa `WITH RECURSIVE`, que exige a versão 8.
2. Execute os scripts nesta ordem, num banco vazio:

```bash
mysql -u usuario -p < sql/ddl/01_estrutura.sql
mysql -u usuario -p < sql/dados/02_massa_de_dados.sql
mysql -u usuario -p < sql/consultas/03_consultas.sql
mysql -u usuario -p < sql/consultas/04_update_delete.sql
```

3. Confira os resultados com os casos da [seção 10](#10-massa-de-dados).

Evidências de execução, como capturas de tela e saídas, ficam em [`evidencias/`](evidencias/).

## 16. Estrutura do repositório

```
Projeto-ERP-Metalurgica-Vertice/
│
├── README.md
│
├── docs/
│   ├── requisitos/          → requisitos, regras de negócio e documento do trabalho
│   ├── diagramas/           → DER, modelo lógico e fluxogramas
│   ├── dicionario-dados/    → dicionário do banco implementado
│   └── normalizacao/        → análise 1FN, 2FN e 3FN
│
├── sql/
│   ├── ddl/                 → criação do banco, tabelas e restrições
│   ├── dados/               → massa de dados
│   ├── consultas/           → consultas gerenciais, de auditoria e UPDATE/DELETE
│   └── auditoria/           → consultas de auditoria separadas, se necessário
│
├── evidencias/              → capturas de execução e testes
│
└── apresentacao/            → material da defesa final
```

## 17. Conclusão

O projeto transformou um problema real de uma pequena indústria em um banco de dados implementado. O problema era não saber de onde veio e para onde foi cada peça.

A cadeia **LOTE → EVENTO_PRODUCAO → CONSUMO_EM_PRODUCAO**, presente desde a primeira entrega, foi preservada. Ela ganhou estoque auditável, ajustes com histórico, recall documentado, compras e controle financeiro.

O modelo está normalizado até a 3FN, protegido por restrições no próprio banco e testado com uma massa de dados que percorre a cadeia completa. Com isso, a empresa passa a responder com dados a pergunta que antes não conseguia:

> **"Se este lote de aço tiver defeito, quais clientes precisam ser avisados?"**
