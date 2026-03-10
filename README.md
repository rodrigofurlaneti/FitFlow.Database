# 🏋️ Sistema de Gerenciamento de Academia — Documentação do Banco de Dados

> **Banco:** `academia_db` | **SGBD:** MySQL 8+ | **Charset:** `utf8mb4_unicode_ci`

---

## Sumário

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Diagrama MER — Entidade-Relacionamento](#2-diagrama-mer--entidade-relacionamento)
3. [Módulos e Tabelas](#3-módulos-e-tabelas)
   - [3.1 Infraestrutura](#31-infraestrutura)
   - [3.2 Recursos Humanos](#32-recursos-humanos)
   - [3.3 Alunos](#33-alunos)
   - [3.4 Planos e Matrículas](#34-planos-e-matrículas)
   - [3.5 Financeiro](#35-financeiro)
   - [3.6 Controle de Acesso](#36-controle-de-acesso)
   - [3.7 Aulas Coletivas](#37-aulas-coletivas)
   - [3.8 Treinos e Avaliações](#38-treinos-e-avaliações)
   - [3.9 Equipamentos](#39-equipamentos)
   - [3.10 Loja / Produtos](#310-loja--produtos)
   - [3.11 Comunicação e Auditoria](#311-comunicação-e-auditoria)
4. [Dicionário de Relacionamentos](#4-dicionário-de-relacionamentos)
5. [Regras de Negócio no Banco](#5-regras-de-negócio-no-banco)
6. [Views, Procedures e Triggers](#6-views-procedures-e-triggers)
7. [Boas Práticas e Convenções](#7-boas-práticas-e-convenções)

---

## 1. Visão Geral da Arquitetura

O banco foi dividido em **11 módulos temáticos** com **35 tabelas**, cobrindo todo o ciclo de vida de uma academia: do cadastro do aluno à catraca, do plano à cobrança, do treino ao estoque da loja.

```
┌──────────────────────────────────────────────────────────────────┐
│                        academia_db                               │
│                                                                  │
│   INFRAESTRUTURA          RH & INSTRUTORES       ALUNOS          │
│   enderecos               cargos                 alunos          │
│   unidades                funcionarios           contatos_emerg  │
│                           instrutores            restricoes_med  │
│                           especialidades                         │
│                                                                  │
│   PLANOS & MATRÍCULAS     FINANCEIRO             ACESSO          │
│   planos                  formas_pagamento        acessos        │
│   modalidades             cobrancas                              │
│   matriculas              estornos                               │
│   congelamentos                                                  │
│                                                                  │
│   AULAS COLETIVAS         TREINOS                EQUIPAMENTOS    │
│   salas                   fichas_treino           equipamentos   │
│   aulas                   exercicios              manutencoes    │
│   agendamentos_aula       ficha_exercicios        categorias_eq  │
│   lista_espera_aulas      execucoes_treino                       │
│                           avaliacoes_fisicas                     │
│                           sessoes_personal                       │
│                                                                  │
│   LOJA                    COMUNICAÇÃO            AUDITORIA       │
│   produtos                notificacoes            logs_audit.    │
│   categorias_produto      avaliacoes_instrutor                   │
│   vendas                                                         │
│   itens_venda                                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Diagrama MER — Entidade-Relacionamento

```
                    ┌─────────────┐
                    │  enderecos  │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────┴──────┐  ┌──────┴──────┐  ┌────┴─────────┐
    │  unidades   │  │funcionarios │  │   alunos     │
    └──────┬──────┘  └──────┬──────┘  └──────┬───────┘
           │                │                 │
    ┌──────┴──────┐   ┌──────┴──────┐   ┌─────┴──────────────────┐
    │   salas     │   │  instrutores│   │      matriculas         │
    └──────┬──────┘   └──────┬──────┘   └──┬───────┬─────────────┘
           │                 │             │       │
    ┌──────┴──────┐   ┌──────┴──────┐  ┌──┴───┐ ┌─┴───────────┐
    │    aulas    │   │especialid.  │  │planos│ │congelamentos│
    └──────┬──────┘   └─────────────┘  └──┬───┘ └─────────────┘
           │                              │
    ┌──────┴──────────┐            ┌──────┴─────┐
    │agendamentos_aula│            │ cobrancas  │
    └──────┬──────────┘            └──────┬─────┘
           │                             │
    ┌──────┴──────┐               ┌──────┴─────┐
    │lista_espera │               │  estornos  │
    └─────────────┘               └────────────┘

    ┌─────────────┐   ┌──────────────┐   ┌────────────────┐
    │fichas_treino│──▶│ficha_exerc.  │──▶│   exercicios   │
    └──────┬──────┘   └──────────────┘   └────────────────┘
           │
    ┌──────┴──────────┐
    │execucoes_treino │──▶ execucao_series
    └─────────────────┘

    ┌────────────┐      ┌────────────────┐    ┌─────────────┐
    │equipamentos│──▶   │  manutencoes   │    │   vendas    │──▶ itens_venda ──▶ produtos
    └────────────┘      └────────────────┘    └─────────────┘
```

### Cardinalidades principais

| Entidade A | Cardinalidade | Entidade B | Observação |
|---|:---:|---|---|
| `enderecos` | 1 : N | `unidades` | Uma unidade tem 1 endereço |
| `enderecos` | 1 : N | `funcionarios` | Um funcionário tem 1 endereço |
| `enderecos` | 1 : N | `alunos` | Um aluno tem 1 endereço |
| `unidades` | 1 : N | `funcionarios` | Funcionário pertence a 1 unidade |
| `unidades` | 1 : N | `alunos` | Aluno tem unidade principal |
| `unidades` | 1 : N | `salas` | Salas pertencem a uma unidade |
| `unidades` | 1 : N | `matriculas` | Matrícula vinculada a uma unidade |
| `cargos` | 1 : N | `funcionarios` | Vários funcionários por cargo |
| `funcionarios` | 1 : 1 | `instrutores` | Instrutor é um funcionário especializado |
| `instrutores` | N : N | `especialidades` | Via `instrutor_especialidades` |
| `alunos` | 1 : N | `matriculas` | Aluno pode ter histórico de matrículas |
| `alunos` | 1 : 1 (ref.) | `alunos` | Auto-relacionamento: `indicado_por` |
| `planos` | 1 : N | `matriculas` | Vários alunos em um mesmo plano |
| `planos` | N : N | `modalidades` | Via `plano_modalidades` |
| `matriculas` | 1 : N | `cobrancas` | Uma matrícula gera várias cobranças |
| `matriculas` | 1 : N | `congelamentos` | Histórico de congelamentos |
| `matriculas` | 1 : N | `acessos` | Cada entrada registra a matrícula usada |
| `aulas` | 1 : N | `agendamentos_aula` | Vários alunos por aula |
| `aulas` | 1 : N | `lista_espera_aulas` | Fila de espera por aula/data |
| `fichas_treino` | 1 : N | `ficha_exercicios` | Vários exercícios por ficha |
| `exercicios` | 1 : N | `ficha_exercicios` | Mesmo exercício em várias fichas |
| `fichas_treino` | 1 : N | `execucoes_treino` | Histórico de execuções |
| `execucoes_treino` | 1 : N | `execucao_series` | Detalhamento por série |
| `equipamentos` | 1 : N | `manutencoes` | Histórico de manutenções |
| `vendas` | 1 : N | `itens_venda` | Itens de cada venda |
| `produtos` | 1 : N | `itens_venda` | Produto aparece em vários itens |

---

## 3. Módulos e Tabelas

---

### 3.1 Infraestrutura

#### `enderecos`
Tabela central de endereços reutilizada por **unidades**, **funcionários** e **alunos**. Evita duplicação de colunas de endereço nas entidades principais.

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador único |
| `cep` | CHAR(8) | CEP sem formatação |
| `logradouro` | VARCHAR(150) | Rua / Avenida |
| `numero` | VARCHAR(10) | Número do imóvel |
| `complemento` | VARCHAR(60) | Apto, bloco etc. (opcional) |
| `bairro` | VARCHAR(80) | Bairro |
| `cidade` | VARCHAR(80) | Cidade |
| `uf` | CHAR(2) | Estado (sigla) |

**Relacionamentos:** referenciada por `unidades.endereco_id`, `funcionarios.endereco_id`, `alunos.endereco_id`.

---

#### `unidades`
Representa cada filial física da academia. Permite operação multi-unidade com controle de capacidade máxima simultânea.

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador |
| `nome` | VARCHAR(100) | Nome da unidade |
| `cnpj` | CHAR(14) UNIQUE | CNPJ sem formatação |
| `telefone` | VARCHAR(20) | Telefone de contato |
| `email` | VARCHAR(120) | E-mail da unidade |
| `endereco_id` | FK → enderecos | Endereço físico |
| `capacidade_max` | SMALLINT | Máx. de alunos simultâneos |
| `ativa` | TINYINT(1) | Soft-delete |

**Relacionamentos:**
- `1 : N` com `funcionarios`, `alunos`, `salas`, `matriculas`, `acessos`, `equipamentos`, `produtos`
- `N : 1` com `enderecos`

---

### 3.2 Recursos Humanos

#### `cargos`
Tabela de domínio com os cargos disponíveis na academia (Gerente, Recepcionista, Financeiro, TI etc.).

---

#### `funcionarios`
Cadastro de todos os colaboradores da academia. Vinculado a uma unidade e a um cargo. Possui `senha_hash` para autenticação no sistema interno. O campo `data_demissao` permite soft-delete com histórico.

**Regra:** `data_demissao` deve ser **≥** `data_admissao` (constraint `CHECK`).

**Relacionamentos:**
- `N : 1` com `cargos`, `unidades`, `enderecos`
- `1 : 1` com `instrutores` (extensão especializada)
- Referenciado em `matriculas`, `cobrancas`, `congelamentos`, `manutencoes`, `vendas`

---

#### `instrutores`
Extensão de `funcionarios` para profissionais de educação física. Armazena o **CREF** (registro profissional obrigatório) e a nota média calculada pelas avaliações dos alunos.

| Coluna | Tipo | Descrição |
|---|---|---|
| `funcionario_id` | FK UNIQUE | Vínculo 1:1 com funcionários |
| `cref` | VARCHAR(20) UNIQUE | Número do CREF |
| `nota_media` | DECIMAL(3,2) | Calculada via trigger (0–5) |

---

#### `especialidades`
Domínio de especialidades dos instrutores (Musculação, Pilates, Yoga…).

---

#### `instrutor_especialidades`
Tabela de junção **N:N** entre `instrutores` e `especialidades`. Um instrutor pode ter múltiplas especialidades.

---

### 3.3 Alunos

#### `alunos`
Entidade principal dos clientes da academia. Possui auto-relacionamento (`indicado_por`) para rastrear indicações entre alunos — útil em programas de fidelidade.

| Coluna | Tipo | Descrição |
|---|---|---|
| `cpf` | CHAR(11) UNIQUE | CPF sem formatação |
| `senha_hash` | VARCHAR(255) | Autenticação no app do aluno |
| `foto_url` | VARCHAR(255) | Foto para reconhecimento |
| `unidade_id` | FK | Unidade de matrícula principal |
| `indicado_por` | FK → alunos | Auto-relacionamento (nullable) |
| `ativo` | TINYINT(1) | Soft-delete |

**Trigger associado:** ao desativar um aluno (`ativo = 0`), todos os seus agendamentos futuros são automaticamente cancelados.

---

#### `aluno_contatos_emergencia`
Armazena 1 ou mais contatos de emergência por aluno (nome, parentesco, telefone). Regra de segurança obrigatória em academias.

**Relacionamento:** `N : 1` com `alunos` (ON DELETE CASCADE).

---

#### `aluno_restricoes_medicas`
Registra restrições médicas do aluno com período de vigência (`data_inicio` / `data_fim`). Visível para instrutores antes de montarem fichas de treino.

---

### 3.4 Planos e Matrículas

#### `modalidades`
Catálogo das atividades oferecidas: Musculação, Natação, Spinning, Yoga, Funcional etc. Usada para definir o que cada plano inclui.

---

#### `planos`
Define os pacotes de serviços da academia com todas as regras comerciais embutidas.

| Coluna | Tipo | Descrição |
|---|---|---|
| `duracao_meses` | TINYINT | Duração (0 = acesso diário) |
| `valor` | DECIMAL | Mensalidade |
| `valor_adesao` | DECIMAL | Taxa de adesão (pode ser zero) |
| `permite_congelamento` | TINYINT(1) | Se o plano aceita congelar |
| `max_congelamentos` | TINYINT | Quantas vezes pode congelar |
| `dias_congelamento` | SMALLINT | Máximo de dias por congelamento |
| `numero_acessos_dia` | TINYINT | 0 = ilimitado |

---

#### `plano_modalidades`
Junção **N:N** entre `planos` e `modalidades`. Define quais atividades estão incluídas em cada plano.

---

#### `matriculas`
Vínculo entre aluno e plano, com controle de período e ciclo de vida completo.

**Estados possíveis:**
```
ativa ──▶ congelada ──▶ ativa
     └──▶ suspensa
     └──▶ cancelada
     └──▶ expirada  (por evento agendado ou trigger)
```

| Coluna | Tipo | Descrição |
|---|---|---|
| `data_inicio` | DATE | Início da vigência |
| `data_fim` | DATE | Fim da vigência (ajustado em congelamentos) |
| `status` | ENUM | Ciclo de vida da matrícula |
| `renovacao_auto` | TINYINT(1) | Se renova automaticamente |

**Regra:** `data_fim > data_inicio` (constraint `CHECK`).

---

#### `congelamentos`
Registra cada período de congelamento de uma matrícula. A procedure `sp_congelar_matricula` valida todas as regras (plano permite? limite atingido? dias excedidos?) antes de inserir e ajusta automaticamente o `data_fim` da matrícula.

---

### 3.5 Financeiro

#### `formas_pagamento`
Domínio das formas de pagamento aceitas: Dinheiro, Cartão de Crédito, Débito, PIX, Boleto.

---

#### `cobrancas`
Centraliza todas as cobranças do sistema (mensalidades, adesões, sessões de personal). Possui coluna gerada `valor_final = valor - desconto`.

| Coluna | Tipo | Descrição |
|---|---|---|
| `data_vencimento` | DATE | Data-limite de pagamento |
| `data_pagamento` | DATE | Preenchida ao quitar |
| `status` | ENUM | `pendente / pago / atrasado / cancelado` |
| `multa` | DECIMAL | Multa por atraso |
| `juros` | DECIMAL | Juros por atraso |
| `valor_final` | GENERATED | `valor - desconto` (coluna calculada) |

**Evento diário:** cobranças pendentes com `data_vencimento < HOJE` têm status alterado para `atrasado` automaticamente.

**View associada:** `vw_cobrancas_atraso` exibe inadimplentes com estimativa de multa e juros.

---

#### `estornos`
Registra estornos realizados em cobranças já pagas. Mantém rastreabilidade financeira completa com o funcionário responsável.

---

### 3.6 Controle de Acesso

#### `acessos`
Log imutável de todas as tentativas de entrada na academia — permitidas e negadas. É o coração do controle de catraca.

| Coluna | Tipo | Descrição |
|---|---|---|
| `entrada` | DATETIME | Timestamp de entrada |
| `saida` | DATETIME | Timestamp de saída (nullable) |
| `negado` | TINYINT(1) | `1` se acesso foi bloqueado |
| `motivo_negado` | VARCHAR(150) | Razão do bloqueio |

**Regras de bloqueio** (via `sp_registrar_acesso`):
1. Nenhuma matrícula ativa ou vencida → bloqueia
2. Cobrança em atraso há mais de 5 dias → bloqueia
3. Limite diário de acessos do plano atingido → bloqueia

**Trigger:** registros de acesso negado são imutáveis (não podem ser editados).

---

### 3.7 Aulas Coletivas

#### `salas`
Salas físicas de cada unidade com capacidade máxima. Vinculada às aulas para evitar conflitos de horário.

---

#### `aulas`
Agenda fixa das aulas coletivas com recorrência semanal (`dia_semana` 0–6). Define instrutor responsável, sala, vagas disponíveis e nível de dificuldade.

**Regra:** `horario_fim > horario_inicio` (constraint `CHECK`).

---

#### `agendamentos_aula`
Inscrição de alunos em aulas coletivas para uma data específica. Impede duplicidade via constraint `UNIQUE (aluno_id, aula_id, data_aula)`.

**Estados:** `confirmado → presente / ausente / cancelado`

---

#### `lista_espera_aulas`
Quando uma aula está lotada, o aluno entra na fila com posição numerada. A procedure `sp_agendar_aula` gerencia isso automaticamente. Se uma vaga abrir (cancelamento), a lógica de negócio pode promover o primeiro da fila.

---

### 3.8 Treinos e Avaliações

#### `avaliacoes_fisicas`
Registro periódico das métricas corporais do aluno feito pelo instrutor. O **IMC** é uma coluna gerada (`peso / altura²`), nunca precisa ser inserido manualmente.

| Coluna | Tipo | Descrição |
|---|---|---|
| `imc` | DECIMAL GENERATED | Calculado automaticamente |
| `percentual_gordura` | DECIMAL | % de gordura corporal |
| `massa_muscular_kg` | DECIMAL | Massa muscular em kg |
| `vo2_max` | DECIMAL | Capacidade aeróbica |
| `circ_*` | DECIMAL | Circunferências corporais |

---

#### `fichas_treino`
Plano de treino personalizado elaborado pelo instrutor para o aluno. Pode ter data de validade e múltiplas fichas simultâneas (A/B/C).

---

#### `exercicios`
Catálogo global de exercícios com grupo muscular, descrição e link de vídeo demonstrativo.

---

#### `ficha_exercicios`
Detalha cada exercício dentro de uma ficha: dia do treino (A/B/C/D), ordem, séries, repetições, carga e tempo de descanso.

---

#### `execucoes_treino`
Cada vez que o aluno realiza um treino fica registrado aqui com data, duração e observações. Base para relatórios de frequência e evolução.

---

#### `execucao_series`
Detalhamento de cada série executada: repetições efetivamente feitas e carga usada. Permite análise de progressão de carga ao longo do tempo.

---

#### `sessoes_personal`
Agendamento e controle de sessões de personal trainer avulsas. Vinculada a uma cobrança para controle financeiro automatizado.

**Estados:** `agendada → realizada / cancelada / falta_aluno / falta_instrutor`

---

#### `avaliacoes_instrutor`
O aluno avalia o instrutor com nota de 1 a 5 e comentário. Uma **trigger** recalcula a `nota_media` na tabela `instrutores` após cada avaliação inserida.

---

### 3.9 Equipamentos

#### `categorias_equipamento`
Domínio de categorias: Cardiovascular, Musculação, Peso Livre, Acessórios, Aquático.

---

#### `equipamentos`
Inventário de todos os equipamentos de cada unidade com dados de aquisição, número de série, vida útil e status atual.

**Status:** `ativo / em_manutencao / desativado`

---

#### `manutencoes`
Histórico completo de manutenções preventivas e corretivas por equipamento. Inclui custo, datas de início/fim e dados do técnico responsável.

---

### 3.10 Loja / Produtos

#### `categorias_produto`
Domínio de categorias de produtos vendidos: Suplementos, Roupas, Acessórios, Bebidas.

---

#### `produtos`
Catálogo de produtos com controle de estoque. O campo `estoque_minimo` é usado pela view `vw_estoque_critico` para alertar itens que precisam de reposição.

**Trigger associada:** `trg_before_item_venda_insert` bloqueia a venda se o estoque for insuficiente antes de inserir o item.

---

#### `vendas`
Cabeçalho de cada venda realizada no balcão. `total_final` é coluna gerada (`total - desconto`).

**Relacionamentos:**
- `N : 1` com `alunos` (nullable — pode ser venda para não-aluno)
- `N : 1` com `funcionarios` (vendedor)
- `N : 1` com `unidades`
- `1 : N` com `itens_venda`

---

#### `itens_venda`
Linhas da venda com quantidade, preço unitário e desconto. `subtotal` é coluna gerada automaticamente.

---

### 3.11 Comunicação e Auditoria

#### `notificacoes`
Sistema de notificações push/e-mail/SMS para alunos. Registra tipo (`vencimento`, `cobranca`, `aula`, `treino`, `promo`, `sistema`), canal de envio e status de leitura.

---

#### `logs_auditoria`
Tabela de auditoria que registra toda operação sensível (`INSERT`, `UPDATE`, `DELETE`) nas principais tabelas, com snapshot JSON do estado anterior e posterior do registro.

| Coluna | Tipo | Descrição |
|---|---|---|
| `tabela` | VARCHAR | Nome da tabela afetada |
| `registro_id` | INT | PK do registro modificado |
| `acao` | ENUM | `INSERT / UPDATE / DELETE` |
| `dados_antes` | JSON | Estado antes da alteração |
| `dados_depois` | JSON | Estado após a alteração |
| `ip` | VARCHAR(45) | IP do usuário (IPv4/IPv6) |

---

## 4. Dicionário de Relacionamentos

```
enderecos          ◄──1:N──  unidades
enderecos          ◄──1:N──  funcionarios
enderecos          ◄──1:N──  alunos
cargos             ◄──1:N──  funcionarios
unidades           ◄──1:N──  funcionarios
unidades           ◄──1:N──  alunos
unidades           ◄──1:N──  salas
unidades           ◄──1:N──  matriculas
unidades           ◄──1:N──  acessos
unidades           ◄──1:N──  equipamentos
unidades           ◄──1:N──  produtos
unidades           ◄──1:N──  vendas
funcionarios       ──1:1──▶  instrutores
instrutores       ◄──N:N──▶  especialidades        [instrutor_especialidades]
alunos             ◄──1:N──  matriculas
alunos             ◄──1:N──  acessos
alunos             ◄──1:N──  agendamentos_aula
alunos             ◄──1:N──  lista_espera_aulas
alunos             ◄──1:N──  avaliacoes_fisicas
alunos             ◄──1:N──  fichas_treino
alunos             ◄──1:N──  execucoes_treino
alunos             ◄──1:N──  sessoes_personal
alunos             ◄──1:N──  cobrancas
alunos             ◄──1:N──  vendas
alunos             ◄──1:N──  notificacoes
alunos             ◄──1:N──  avaliacoes_instrutor
alunos             ◄──auto── alunos                [indicado_por]
planos            ◄──N:N──▶  modalidades            [plano_modalidades]
planos             ◄──1:N──  matriculas
matriculas         ◄──1:N──  cobrancas
matriculas         ◄──1:N──  congelamentos
matriculas         ◄──1:N──  acessos
cobrancas          ◄──1:N──  estornos
cobrancas          ──1:1──▶  sessoes_personal
instrutores        ◄──1:N──  aulas
instrutores        ◄──1:N──  avaliacoes_fisicas
instrutores        ◄──1:N──  fichas_treino
instrutores        ◄──1:N──  sessoes_personal
instrutores        ◄──1:N──  avaliacoes_instrutor
salas              ◄──1:N──  aulas
aulas              ◄──1:N──  agendamentos_aula
aulas              ◄──1:N──  lista_espera_aulas
fichas_treino      ◄──1:N──  ficha_exercicios
fichas_treino      ◄──1:N──  execucoes_treino
exercicios         ◄──1:N──  ficha_exercicios
execucoes_treino   ◄──1:N──  execucao_series
ficha_exercicios   ◄──1:N──  execucao_series
equipamentos       ◄──1:N──  manutencoes
produtos           ◄──1:N──  itens_venda
vendas             ◄──1:N──  itens_venda
formas_pagamento   ◄──1:N──  cobrancas
formas_pagamento   ◄──1:N──  vendas
```

---

## 5. Regras de Negócio no Banco

### Constraints declarativas (sempre aplicadas)

| Regra | Onde | Tipo |
|---|---|---|
| `data_demissao >= data_admissao` | `funcionarios` | CHECK |
| `data_fim > data_inicio` | `matriculas`, `congelamentos`, `fichas_treino` | CHECK |
| `salario > 0` | `funcionarios` | CHECK |
| `valor > 0` | `cobrancas`, `sessoes_personal` | CHECK |
| `desconto ≤ valor` | `cobrancas` | CHECK |
| `nota BETWEEN 1 AND 5` | `avaliacoes_instrutor` | CHECK |
| `nota_media BETWEEN 0 AND 5` | `instrutores` | CHECK |
| `dia_semana BETWEEN 0 AND 6` | `aulas` | CHECK |
| `horario_fim > horario_inicio` | `aulas` | CHECK |
| CPF único | `alunos`, `funcionarios` | UNIQUE |
| E-mail único | `alunos`, `funcionarios` | UNIQUE |
| CNPJ único | `unidades` | UNIQUE |
| CREF único | `instrutores` | UNIQUE |
| Nº série único | `equipamentos` | UNIQUE |
| IMC calculado automaticamente | `avaliacoes_fisicas` | GENERATED |
| `valor_final = valor - desconto` | `cobrancas` | GENERATED |
| `total_final = total - desconto` | `vendas` | GENERATED |
| `subtotal = qtd * preco - desc` | `itens_venda` | GENERATED |

---

## 6. Views, Procedures e Triggers

### Views

| View | Propósito |
|---|---|
| `vw_alunos_ativos` | Lista alunos com matrícula ativa, plano, unidade e dias restantes |
| `vw_cobrancas_atraso` | Inadimplentes com estimativa de multa e juros acumulados |
| `vw_ocupacao_aulas_hoje` | Vagas disponíveis nas aulas do dia atual |
| `vw_estoque_critico` | Produtos com estoque abaixo ou igual ao mínimo |

### Stored Procedures

| Procedure | Propósito |
|---|---|
| `sp_registrar_acesso` | Controle de catraca com 3 camadas de validação |
| `sp_agendar_aula` | Inscrição em aula coletiva com lista de espera automática |
| `sp_congelar_matricula` | Congelamento com validação das regras do plano |
| `sp_gerar_cobrancas_mensais` | Geração em lote de mensalidades sem duplicidade |
| `sp_registrar_pagamento` | Baixa de pagamento com validação de status |
| `sp_atualizar_nota_instrutor` | Recalcula média de avaliações do instrutor |

### Triggers

| Trigger | Evento | Ação |
|---|---|---|
| `trg_after_avaliacao_insert` | AFTER INSERT em `avaliacoes_instrutor` | Recalcula `nota_media` do instrutor |
| `trg_after_item_venda_insert` | AFTER INSERT em `itens_venda` | Decrementa estoque do produto |
| `trg_before_item_venda_insert` | BEFORE INSERT em `itens_venda` | Bloqueia se estoque insuficiente |
| `trg_before_acesso_update` | BEFORE UPDATE em `acessos` | Impede edição de acessos negados |
| `trg_after_aluno_desativar` | AFTER UPDATE em `alunos` | Cancela agendamentos futuros ao desativar |
| `trg_before_matricula_update` | BEFORE UPDATE em `matriculas` | Expira matrícula se `data_fim < hoje` |

### Evento Agendado

| Evento | Frequência | Ações |
|---|---|---|
| `evt_manutencao_diaria` | Todo dia às 01:00 | Expira matrículas vencidas · Marca cobranças atrasadas · Registra ausências do dia anterior |

---

## 7. Boas Práticas e Convenções

### Nomenclatura
- Tabelas em **snake_case** no **plural**
- PKs sempre `id` com `INT UNSIGNED AUTO_INCREMENT`
- FKs nomeadas como `entidade_id` (ex.: `aluno_id`, `plano_id`)
- Constraints nomeadas com prefixo `fk_` (foreign key) ou `chk_` (check)
- Índices com prefixo `idx_`

### Tipos de dados
- Datas sem hora: `DATE` · Datas com hora: `DATETIME`
- Dinheiro: `DECIMAL(10,2)` · Nunca `FLOAT`
- Booleanos: `TINYINT(1)` (`0 = false`, `1 = true`)
- Textos curtos fixos: `CHAR` · Textos variáveis: `VARCHAR`
- Campos grandes: `TEXT`
- Dados estruturados de auditoria: `JSON`

### Soft-delete
Registros sensíveis não são excluídos fisicamente. Usam coluna `ativo TINYINT(1)` ou `status ENUM(...)`. Isso preserva histórico financeiro, de acesso e de matrículas.

### Integridade referencial
Todas as FKs estão declaradas explicitamente. `ON DELETE CASCADE` é usado apenas onde a dependência é total (ex.: contatos de emergência são excluídos junto com o aluno).

### Performance
Índices adicionais foram criados para as consultas mais frequentes:

```sql
-- Buscas por CPF e e-mail
idx_alunos_cpf, idx_alunos_email, idx_func_cpf

-- Relatórios financeiros
idx_cob_vencimento, idx_cob_aluno

-- Controle de acesso
idx_acessos_aluno_data

-- Agendamentos
idx_agend_data

-- Alerta de estoque
idx_prod_estoque
```

---

> 📄 **Arquivo SQL:** `academia_completo.sql`
> 🗓️ **Versão:** 1.0 — Março/2026
> ✉️ Dúvidas ou extensões? Consulte a seção de Stored Procedures para adicionar novas regras de negócio sem alterar a estrutura das tabelas.
