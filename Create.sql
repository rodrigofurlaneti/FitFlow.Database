-- ============================================================
-- SISTEMA DE GERENCIAMENTO DE ACADEMIA - MySQL Completo
-- Versão: 1.0 | Modelagem completa com regras de negócio
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS academia_db;
CREATE DATABASE academia_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE academia_db;

-- ============================================================
-- 1. ENDEREÇOS
-- ============================================================
CREATE TABLE enderecos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cep             CHAR(8)      NOT NULL,
    logradouro      VARCHAR(150) NOT NULL,
    numero          VARCHAR(10)  NOT NULL,
    complemento     VARCHAR(60),
    bairro          VARCHAR(80)  NOT NULL,
    cidade          VARCHAR(80)  NOT NULL,
    uf              CHAR(2)      NOT NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. UNIDADES DA ACADEMIA
-- ============================================================
CREATE TABLE unidades (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    cnpj            CHAR(14)     NOT NULL UNIQUE,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(120) NOT NULL,
    endereco_id     INT UNSIGNED NOT NULL,
    capacidade_max  SMALLINT UNSIGNED NOT NULL DEFAULT 100
                        COMMENT 'Número máximo de alunos simultâneos',
    ativa           TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_unid_end  FOREIGN KEY (endereco_id) REFERENCES enderecos(id)
);

-- ============================================================
-- 3. FUNCIONÁRIOS (Recepcionistas, Gerentes, etc.)
-- ============================================================
CREATE TABLE cargos (
    id              TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(60) NOT NULL UNIQUE,
    descricao       TEXT
);

CREATE TABLE funcionarios (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    cpf             CHAR(11)     NOT NULL UNIQUE,
    rg              VARCHAR(20),
    data_nascimento DATE         NOT NULL,
    sexo            ENUM('M','F','O') NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    senha_hash      VARCHAR(255) NOT NULL,
    cargo_id        TINYINT UNSIGNED NOT NULL,
    unidade_id      INT UNSIGNED NOT NULL,
    endereco_id     INT UNSIGNED NOT NULL,
    salario         DECIMAL(10,2) NOT NULL CHECK (salario > 0),
    data_admissao   DATE         NOT NULL,
    data_demissao   DATE,
    ativo           TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_func_cargo  FOREIGN KEY (cargo_id)    REFERENCES cargos(id),
    CONSTRAINT fk_func_unid   FOREIGN KEY (unidade_id)  REFERENCES unidades(id),
    CONSTRAINT fk_func_end    FOREIGN KEY (endereco_id) REFERENCES enderecos(id),
    CONSTRAINT chk_func_dem   CHECK (data_demissao IS NULL OR data_demissao >= data_admissao)
);

-- ============================================================
-- 4. INSTRUTORES / PERSONAL TRAINERS
-- ============================================================
CREATE TABLE especialidades (
    id              TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(80)  NOT NULL UNIQUE  -- ex.: Musculação, Pilates, Spinning
);

CREATE TABLE instrutores (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    funcionario_id  INT UNSIGNED NOT NULL UNIQUE,
    cref            VARCHAR(20)  NOT NULL UNIQUE  COMMENT 'Registro no Conselho Regional de Educação Física',
    bio             TEXT,
    nota_media      DECIMAL(3,2) DEFAULT NULL     COMMENT 'Média das avaliações (0-5)',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inst_func FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
    CONSTRAINT chk_inst_nota CHECK (nota_media IS NULL OR (nota_media >= 0 AND nota_media <= 5))
);

CREATE TABLE instrutor_especialidades (
    instrutor_id      INT UNSIGNED    NOT NULL,
    especialidade_id  TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (instrutor_id, especialidade_id),
    CONSTRAINT fk_ie_inst  FOREIGN KEY (instrutor_id)     REFERENCES instrutores(id),
    CONSTRAINT fk_ie_esp   FOREIGN KEY (especialidade_id) REFERENCES especialidades(id)
);

-- ============================================================
-- 5. PLANOS E MODALIDADES
-- ============================================================
CREATE TABLE modalidades (
    id              TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(80)  NOT NULL UNIQUE, -- Musculação, Natação, Spinning…
    descricao       TEXT,
    ativa           TINYINT(1)   NOT NULL DEFAULT 1
);

CREATE TABLE planos (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome                VARCHAR(80)   NOT NULL,
    descricao           TEXT,
    duracao_meses       TINYINT UNSIGNED NOT NULL CHECK (duracao_meses > 0),
    valor               DECIMAL(10,2) NOT NULL CHECK (valor >= 0),
    valor_adesao        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    permite_congelamento TINYINT(1)   NOT NULL DEFAULT 0,
    max_congelamentos   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    dias_congelamento   SMALLINT UNSIGNED NOT NULL DEFAULT 0
                            COMMENT 'Máximo de dias de congelamento por período',
    numero_acessos_dia  TINYINT UNSIGNED NOT NULL DEFAULT 1
                            COMMENT '0 = ilimitado',
    ativo               TINYINT(1)    NOT NULL DEFAULT 1,
    created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE plano_modalidades (
    plano_id        SMALLINT UNSIGNED NOT NULL,
    modalidade_id   TINYINT UNSIGNED  NOT NULL,
    PRIMARY KEY (plano_id, modalidade_id),
    CONSTRAINT fk_pm_plano FOREIGN KEY (plano_id)     REFERENCES planos(id),
    CONSTRAINT fk_pm_mod   FOREIGN KEY (modalidade_id) REFERENCES modalidades(id)
);

-- ============================================================
-- 6. ALUNOS
-- ============================================================
CREATE TABLE alunos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    cpf             CHAR(11)     NOT NULL UNIQUE,
    rg              VARCHAR(20),
    data_nascimento DATE         NOT NULL,
    sexo            ENUM('M','F','O') NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    senha_hash      VARCHAR(255) NOT NULL,
    foto_url        VARCHAR(255),
    endereco_id     INT UNSIGNED NOT NULL,
    unidade_id      INT UNSIGNED NOT NULL  COMMENT 'Unidade de matrícula principal',
    indicado_por    INT UNSIGNED            COMMENT 'Aluno que indicou',
    ativo           TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_alun_end  FOREIGN KEY (endereco_id) REFERENCES enderecos(id),
    CONSTRAINT fk_alun_unid FOREIGN KEY (unidade_id)  REFERENCES unidades(id),
    CONSTRAINT fk_alun_ind  FOREIGN KEY (indicado_por) REFERENCES alunos(id)
);

-- Contatos de emergência
CREATE TABLE aluno_contatos_emergencia (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT UNSIGNED    NOT NULL,
    nome        VARCHAR(120)    NOT NULL,
    parentesco  VARCHAR(50)     NOT NULL,
    telefone    VARCHAR(20)     NOT NULL,
    CONSTRAINT fk_ace_aluno FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE
);

-- Restrições médicas
CREATE TABLE aluno_restricoes_medicas (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT UNSIGNED NOT NULL,
    descricao   TEXT         NOT NULL,
    data_inicio DATE         NOT NULL,
    data_fim    DATE,
    ativa       TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_arm_aluno FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE,
    CONSTRAINT chk_arm_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ============================================================
-- 7. MATRÍCULAS E ASSINATURAS
-- ============================================================
CREATE TABLE matriculas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    plano_id        SMALLINT UNSIGNED NOT NULL,
    unidade_id      INT UNSIGNED    NOT NULL,
    funcionario_id  INT UNSIGNED    NOT NULL  COMMENT 'Quem cadastrou',
    data_inicio     DATE            NOT NULL,
    data_fim        DATE            NOT NULL,
    data_cancelamento DATE,
    motivo_cancelamento VARCHAR(255),
    status          ENUM('ativa','suspensa','cancelada','expirada','congelada')
                    NOT NULL DEFAULT 'ativa',
    renovacao_auto  TINYINT(1)      NOT NULL DEFAULT 0,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_mat_aluno FOREIGN KEY (aluno_id)     REFERENCES alunos(id),
    CONSTRAINT fk_mat_plano FOREIGN KEY (plano_id)     REFERENCES planos(id),
    CONSTRAINT fk_mat_unid  FOREIGN KEY (unidade_id)   REFERENCES unidades(id),
    CONSTRAINT fk_mat_func  FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
    CONSTRAINT chk_mat_datas CHECK (data_fim > data_inicio)
);

-- Congelamentos de matrícula
CREATE TABLE congelamentos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    matricula_id    INT UNSIGNED NOT NULL,
    data_inicio     DATE         NOT NULL,
    data_fim        DATE         NOT NULL,
    motivo          TEXT         NOT NULL,
    aprovado_por    INT UNSIGNED NOT NULL  COMMENT 'Funcionário que aprovou',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cong_mat  FOREIGN KEY (matricula_id) REFERENCES matriculas(id),
    CONSTRAINT fk_cong_func FOREIGN KEY (aprovado_por) REFERENCES funcionarios(id),
    CONSTRAINT chk_cong_dat CHECK (data_fim > data_inicio)
);

-- ============================================================
-- 8. FINANCEIRO — COBRANÇAS E PAGAMENTOS
-- ============================================================
CREATE TABLE formas_pagamento (
    id      TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(50) NOT NULL UNIQUE  -- PIX, Cartão Crédito, Débito, Boleto, Dinheiro
);

CREATE TABLE cobrancas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    matricula_id    INT UNSIGNED    NOT NULL,
    aluno_id        INT UNSIGNED    NOT NULL,
    descricao       VARCHAR(150)    NOT NULL,
    valor           DECIMAL(10,2)   NOT NULL CHECK (valor > 0),
    desconto        DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    valor_final     DECIMAL(10,2)   GENERATED ALWAYS AS (valor - desconto) STORED,
    data_vencimento DATE            NOT NULL,
    data_pagamento  DATE,
    status          ENUM('pendente','pago','atrasado','cancelado') NOT NULL DEFAULT 'pendente',
    forma_pagamento_id TINYINT UNSIGNED,
    multa           DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    juros           DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    comprovante_url VARCHAR(255),
    funcionario_id  INT UNSIGNED    COMMENT 'Quem registrou o pagamento',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cob_mat  FOREIGN KEY (matricula_id)     REFERENCES matriculas(id),
    CONSTRAINT fk_cob_alun FOREIGN KEY (aluno_id)         REFERENCES alunos(id),
    CONSTRAINT fk_cob_fp   FOREIGN KEY (forma_pagamento_id) REFERENCES formas_pagamento(id),
    CONSTRAINT fk_cob_func FOREIGN KEY (funcionario_id)   REFERENCES funcionarios(id),
    CONSTRAINT chk_cob_desc CHECK (desconto >= 0 AND desconto <= valor)
);

-- Histórico de estornos
CREATE TABLE estornos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cobranca_id INT UNSIGNED    NOT NULL,
    motivo      TEXT            NOT NULL,
    valor       DECIMAL(10,2)   NOT NULL CHECK (valor > 0),
    realizado_por INT UNSIGNED  NOT NULL,
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_est_cob  FOREIGN KEY (cobranca_id)  REFERENCES cobrancas(id),
    CONSTRAINT fk_est_func FOREIGN KEY (realizado_por) REFERENCES funcionarios(id)
);

-- ============================================================
-- 9. CONTROLE DE ACESSO / CATRACAS
-- ============================================================
CREATE TABLE acessos (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    unidade_id      INT UNSIGNED    NOT NULL,
    matricula_id    INT UNSIGNED    NOT NULL,
    entrada         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saida           DATETIME,
    negado          TINYINT(1)      NOT NULL DEFAULT 0,
    motivo_negado   VARCHAR(150),
    CONSTRAINT fk_ac_alun  FOREIGN KEY (aluno_id)    REFERENCES alunos(id),
    CONSTRAINT fk_ac_unid  FOREIGN KEY (unidade_id)  REFERENCES unidades(id),
    CONSTRAINT fk_ac_mat   FOREIGN KEY (matricula_id) REFERENCES matriculas(id),
    CONSTRAINT chk_ac_sai  CHECK (saida IS NULL OR saida >= entrada)
);

-- ============================================================
-- 10. EQUIPAMENTOS
-- ============================================================
CREATE TABLE categorias_equipamento (
    id      TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE equipamentos (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    unidade_id          INT UNSIGNED     NOT NULL,
    categoria_id        TINYINT UNSIGNED NOT NULL,
    nome                VARCHAR(120)     NOT NULL,
    marca               VARCHAR(80),
    modelo              VARCHAR(80),
    numero_serie        VARCHAR(80)      UNIQUE,
    data_aquisicao      DATE             NOT NULL,
    valor_aquisicao     DECIMAL(12,2),
    vida_util_anos      TINYINT UNSIGNED,
    status              ENUM('ativo','em_manutencao','desativado') NOT NULL DEFAULT 'ativo',
    proxima_manutencao  DATE,
    created_at          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_eq_unid FOREIGN KEY (unidade_id)   REFERENCES unidades(id),
    CONSTRAINT fk_eq_cat  FOREIGN KEY (categoria_id) REFERENCES categorias_equipamento(id)
);

CREATE TABLE manutencoes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipamento_id  INT UNSIGNED    NOT NULL,
    tipo            ENUM('preventiva','corretiva') NOT NULL,
    descricao       TEXT            NOT NULL,
    data_inicio     DATETIME        NOT NULL,
    data_fim        DATETIME,
    custo           DECIMAL(10,2),
    tecnico_nome    VARCHAR(120),
    tecnico_contato VARCHAR(80),
    realizada_por   INT UNSIGNED    COMMENT 'Funcionário responsável',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_man_eq   FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id),
    CONSTRAINT fk_man_func FOREIGN KEY (realizada_por)  REFERENCES funcionarios(id),
    CONSTRAINT chk_man_dat CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ============================================================
-- 11. AULAS COLETIVAS
-- ============================================================
CREATE TABLE salas (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    unidade_id  INT UNSIGNED     NOT NULL,
    nome        VARCHAR(60)      NOT NULL,
    capacidade  SMALLINT UNSIGNED NOT NULL CHECK (capacidade > 0),
    ativa       TINYINT(1)       NOT NULL DEFAULT 1,
    CONSTRAINT fk_sala_unid FOREIGN KEY (unidade_id) REFERENCES unidades(id)
);

CREATE TABLE aulas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    modalidade_id   TINYINT UNSIGNED NOT NULL,
    instrutor_id    INT UNSIGNED     NOT NULL,
    sala_id         INT UNSIGNED     NOT NULL,
    nome            VARCHAR(100)     NOT NULL,
    descricao       TEXT,
    dia_semana      TINYINT UNSIGNED NOT NULL CHECK (dia_semana BETWEEN 0 AND 6)
                        COMMENT '0=Domingo … 6=Sábado',
    horario_inicio  TIME             NOT NULL,
    horario_fim     TIME             NOT NULL,
    vagas           SMALLINT UNSIGNED NOT NULL CHECK (vagas > 0),
    nivel           ENUM('iniciante','intermediario','avancado','todos') NOT NULL DEFAULT 'todos',
    ativa           TINYINT(1)       NOT NULL DEFAULT 1,
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_aul_mod  FOREIGN KEY (modalidade_id) REFERENCES modalidades(id),
    CONSTRAINT fk_aul_inst FOREIGN KEY (instrutor_id)  REFERENCES instrutores(id),
    CONSTRAINT fk_aul_sala FOREIGN KEY (sala_id)       REFERENCES salas(id),
    CONSTRAINT chk_aul_hor CHECK (horario_fim > horario_inicio)
);

CREATE TABLE agendamentos_aula (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT UNSIGNED    NOT NULL,
    aula_id     INT UNSIGNED    NOT NULL,
    data_aula   DATE            NOT NULL,
    status      ENUM('confirmado','cancelado','presente','ausente') NOT NULL DEFAULT 'confirmado',
    cancelado_em DATETIME,
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_agend (aluno_id, aula_id, data_aula),
    CONSTRAINT fk_ag_alun FOREIGN KEY (aluno_id) REFERENCES alunos(id),
    CONSTRAINT fk_ag_aula FOREIGN KEY (aula_id)  REFERENCES aulas(id)
);

-- Lista de espera
CREATE TABLE lista_espera_aulas (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT UNSIGNED NOT NULL,
    aula_id     INT UNSIGNED NOT NULL,
    data_aula   DATE         NOT NULL,
    posicao     SMALLINT UNSIGNED NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_le (aluno_id, aula_id, data_aula),
    CONSTRAINT fk_le_alun FOREIGN KEY (aluno_id) REFERENCES alunos(id),
    CONSTRAINT fk_le_aula FOREIGN KEY (aula_id)  REFERENCES aulas(id)
);

-- ============================================================
-- 12. AVALIAÇÕES FÍSICAS
-- ============================================================
CREATE TABLE avaliacoes_fisicas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    instrutor_id    INT UNSIGNED    NOT NULL,
    data_avaliacao  DATE            NOT NULL,
    peso_kg         DECIMAL(5,2)    CHECK (peso_kg > 0),
    altura_cm       DECIMAL(5,2)    CHECK (altura_cm > 0),
    imc             DECIMAL(4,2)    GENERATED ALWAYS AS
                        (ROUND(peso_kg / POW(altura_cm / 100, 2), 2)) STORED,
    percentual_gordura DECIMAL(4,2) CHECK (percentual_gordura >= 0 AND percentual_gordura <= 100),
    massa_muscular_kg  DECIMAL(5,2) CHECK (massa_muscular_kg >= 0),
    -- Circunferências em cm
    circ_torax      DECIMAL(5,2),
    circ_cintura    DECIMAL(5,2),
    circ_quadril    DECIMAL(5,2),
    circ_braco_d    DECIMAL(5,2),
    circ_braco_e    DECIMAL(5,2),
    circ_coxa_d     DECIMAL(5,2),
    circ_coxa_e     DECIMAL(5,2),
    vo2_max         DECIMAL(5,2)    COMMENT 'VO² máximo ml/kg/min',
    observacoes     TEXT,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_af_alun FOREIGN KEY (aluno_id)    REFERENCES alunos(id),
    CONSTRAINT fk_af_inst FOREIGN KEY (instrutor_id) REFERENCES instrutores(id)
);

-- ============================================================
-- 13. TREINOS E FICHAS
-- ============================================================
CREATE TABLE fichas_treino (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    instrutor_id    INT UNSIGNED    NOT NULL,
    nome            VARCHAR(100)    NOT NULL,
    objetivo        VARCHAR(200),
    data_inicio     DATE            NOT NULL,
    data_fim        DATE,
    ativa           TINYINT(1)      NOT NULL DEFAULT 1,
    observacoes     TEXT,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ft_alun FOREIGN KEY (aluno_id)    REFERENCES alunos(id),
    CONSTRAINT fk_ft_inst FOREIGN KEY (instrutor_id) REFERENCES instrutores(id),
    CONSTRAINT chk_ft_dat CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

CREATE TABLE exercicios (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(120)    NOT NULL,
    grupo_muscular  VARCHAR(80)     NOT NULL,
    descricao       TEXT,
    video_url       VARCHAR(255),
    equipamento_necessario VARCHAR(120)
);

CREATE TABLE ficha_exercicios (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ficha_id        INT UNSIGNED    NOT NULL,
    exercicio_id    INT UNSIGNED    NOT NULL,
    dia_treino      CHAR(1)         NOT NULL COMMENT 'A, B, C, D…',
    ordem           TINYINT UNSIGNED NOT NULL DEFAULT 1,
    series          TINYINT UNSIGNED NOT NULL CHECK (series > 0),
    repeticoes      VARCHAR(20)     NOT NULL COMMENT 'Ex.: 10-12 ou 15',
    carga_kg        DECIMAL(5,2),
    descanso_seg    SMALLINT UNSIGNED,
    observacoes     TEXT,
    CONSTRAINT fk_fe_ficha FOREIGN KEY (ficha_id)    REFERENCES fichas_treino(id) ON DELETE CASCADE,
    CONSTRAINT fk_fe_exer  FOREIGN KEY (exercicio_id) REFERENCES exercicios(id)
);

-- Registro de execução dos treinos
CREATE TABLE execucoes_treino (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    ficha_id        INT UNSIGNED    NOT NULL,
    data_execucao   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duracao_min     SMALLINT UNSIGNED,
    observacoes     TEXT,
    CONSTRAINT fk_et_alun  FOREIGN KEY (aluno_id) REFERENCES alunos(id),
    CONSTRAINT fk_et_ficha FOREIGN KEY (ficha_id) REFERENCES fichas_treino(id)
);

CREATE TABLE execucao_series (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    execucao_id     INT UNSIGNED    NOT NULL,
    ficha_exercicio_id INT UNSIGNED NOT NULL,
    serie_numero    TINYINT UNSIGNED NOT NULL,
    repeticoes_feitas TINYINT UNSIGNED NOT NULL,
    carga_usada_kg  DECIMAL(5,2),
    CONSTRAINT fk_es_exec FOREIGN KEY (execucao_id)        REFERENCES execucoes_treino(id) ON DELETE CASCADE,
    CONSTRAINT fk_es_fe   FOREIGN KEY (ficha_exercicio_id) REFERENCES ficha_exercicios(id)
);

-- ============================================================
-- 14. PERSONAL TRAINER — SESSÕES AVULSAS
-- ============================================================
CREATE TABLE sessoes_personal (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    instrutor_id    INT UNSIGNED    NOT NULL,
    data_hora       DATETIME        NOT NULL,
    duracao_min     SMALLINT UNSIGNED NOT NULL DEFAULT 60,
    status          ENUM('agendada','realizada','cancelada','falta_aluno','falta_instrutor')
                    NOT NULL DEFAULT 'agendada',
    valor           DECIMAL(10,2)   NOT NULL CHECK (valor > 0),
    cobranca_id     INT UNSIGNED,
    observacoes     TEXT,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sp_alun FOREIGN KEY (aluno_id)    REFERENCES alunos(id),
    CONSTRAINT fk_sp_inst FOREIGN KEY (instrutor_id) REFERENCES instrutores(id),
    CONSTRAINT fk_sp_cob  FOREIGN KEY (cobranca_id)  REFERENCES cobrancas(id)
);

-- ============================================================
-- 15. PRODUTOS / LOJA (Suplementos, Acessórios)
-- ============================================================
CREATE TABLE categorias_produto (
    id      TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE produtos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categoria_id    TINYINT UNSIGNED NOT NULL,
    unidade_id      INT UNSIGNED     COMMENT 'NULL = disponível em todas',
    nome            VARCHAR(120)     NOT NULL,
    descricao       TEXT,
    preco_custo     DECIMAL(10,2)    NOT NULL CHECK (preco_custo >= 0),
    preco_venda     DECIMAL(10,2)    NOT NULL CHECK (preco_venda >= 0),
    estoque         INT              NOT NULL DEFAULT 0,
    estoque_minimo  INT              NOT NULL DEFAULT 5,
    unidade_medida  VARCHAR(20)      NOT NULL DEFAULT 'un',
    ativo           TINYINT(1)       NOT NULL DEFAULT 1,
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_prod_cat  FOREIGN KEY (categoria_id) REFERENCES categorias_produto(id),
    CONSTRAINT fk_prod_unid FOREIGN KEY (unidade_id)   REFERENCES unidades(id)
);

CREATE TABLE vendas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED     COMMENT 'NULL se venda para não-aluno',
    funcionario_id  INT UNSIGNED    NOT NULL,
    unidade_id      INT UNSIGNED    NOT NULL,
    data_venda      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total           DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    desconto        DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    total_final     DECIMAL(12,2)   GENERATED ALWAYS AS (total - desconto) STORED,
    forma_pagamento_id TINYINT UNSIGNED NOT NULL,
    status          ENUM('concluida','cancelada','devolvida') NOT NULL DEFAULT 'concluida',
    CONSTRAINT fk_vend_alun  FOREIGN KEY (aluno_id)          REFERENCES alunos(id),
    CONSTRAINT fk_vend_func  FOREIGN KEY (funcionario_id)    REFERENCES funcionarios(id),
    CONSTRAINT fk_vend_unid  FOREIGN KEY (unidade_id)        REFERENCES unidades(id),
    CONSTRAINT fk_vend_fp    FOREIGN KEY (forma_pagamento_id) REFERENCES formas_pagamento(id)
);

CREATE TABLE itens_venda (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venda_id    INT UNSIGNED    NOT NULL,
    produto_id  INT UNSIGNED    NOT NULL,
    quantidade  INT UNSIGNED    NOT NULL CHECK (quantidade > 0),
    preco_unit  DECIMAL(10,2)   NOT NULL CHECK (preco_unit >= 0),
    desconto    DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    subtotal    DECIMAL(12,2)   GENERATED ALWAYS AS (quantidade * preco_unit - desconto) STORED,
    CONSTRAINT fk_iv_vend FOREIGN KEY (venda_id)  REFERENCES vendas(id),
    CONSTRAINT fk_iv_prod FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

-- ============================================================
-- 16. NOTIFICAÇÕES E COMUNICAÇÕES
-- ============================================================
CREATE TABLE notificacoes (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT UNSIGNED    NOT NULL,
    tipo        ENUM('vencimento','cobranca','aula','treino','promo','sistema') NOT NULL,
    titulo      VARCHAR(150)    NOT NULL,
    mensagem    TEXT            NOT NULL,
    lida        TINYINT(1)      NOT NULL DEFAULT 0,
    enviada_em  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    canal       ENUM('app','email','sms','whatsapp') NOT NULL DEFAULT 'app',
    CONSTRAINT fk_not_alun FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE
);

-- ============================================================
-- 17. AVALIAÇÕES DO INSTRUTOR PELO ALUNO
-- ============================================================
CREATE TABLE avaliacoes_instrutor (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aluno_id        INT UNSIGNED    NOT NULL,
    instrutor_id    INT UNSIGNED    NOT NULL,
    nota            TINYINT UNSIGNED NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario      TEXT,
    data_avaliacao  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_av_inst (aluno_id, instrutor_id, DATE(data_avaliacao)),
    CONSTRAINT fk_avi_alun FOREIGN KEY (aluno_id)    REFERENCES alunos(id),
    CONSTRAINT fk_avi_inst FOREIGN KEY (instrutor_id) REFERENCES instrutores(id)
);

-- ============================================================
-- 18. LOGS DE AUDITORIA
-- ============================================================
CREATE TABLE logs_auditoria (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tabela      VARCHAR(60)     NOT NULL,
    registro_id INT UNSIGNED    NOT NULL,
    acao        ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    usuario_id  INT UNSIGNED    COMMENT 'funcionario_id ou aluno_id',
    dados_antes JSON,
    dados_depois JSON,
    ip          VARCHAR(45),
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_log_tab (tabela, registro_id),
    INDEX idx_log_usr (usuario_id)
);

-- ============================================================
-- ÍNDICES ADICIONAIS DE PERFORMANCE
-- ============================================================
CREATE INDEX idx_alunos_cpf          ON alunos(cpf);
CREATE INDEX idx_alunos_email        ON alunos(email);
CREATE INDEX idx_mat_aluno_status    ON matriculas(aluno_id, status);
CREATE INDEX idx_mat_vencimento      ON matriculas(data_fim, status);
CREATE INDEX idx_cob_vencimento      ON cobrancas(data_vencimento, status);
CREATE INDEX idx_cob_aluno           ON cobrancas(aluno_id, status);
CREATE INDEX idx_acessos_aluno_data  ON acessos(aluno_id, entrada);
CREATE INDEX idx_agend_data          ON agendamentos_aula(data_aula, status);
CREATE INDEX idx_func_cpf            ON funcionarios(cpf);
CREATE INDEX idx_prod_estoque        ON produtos(estoque, estoque_minimo);

-- ============================================================
-- VIEWS ÚTEIS
-- ============================================================

-- Alunos com matrícula ativa e dados do plano
CREATE OR REPLACE VIEW vw_alunos_ativos AS
SELECT
    a.id            AS aluno_id,
    a.nome          AS aluno_nome,
    a.cpf,
    a.email,
    a.telefone,
    m.id            AS matricula_id,
    p.nome          AS plano_nome,
    p.valor         AS plano_valor,
    m.data_inicio,
    m.data_fim,
    DATEDIFF(m.data_fim, CURDATE()) AS dias_restantes,
    u.nome          AS unidade
FROM alunos a
JOIN matriculas m  ON m.aluno_id = a.id   AND m.status = 'ativa'
JOIN planos p      ON p.id = m.plano_id
JOIN unidades u    ON u.id = m.unidade_id;

-- Cobranças em atraso
CREATE OR REPLACE VIEW vw_cobrancas_atraso AS
SELECT
    c.id            AS cobranca_id,
    a.nome          AS aluno_nome,
    a.email,
    a.telefone,
    c.valor_final,
    c.data_vencimento,
    DATEDIFF(CURDATE(), c.data_vencimento) AS dias_atraso,
    (c.valor_final * 0.02) + (c.valor_final * 0.001 * DATEDIFF(CURDATE(), c.data_vencimento))
        AS estimativa_multa_juros
FROM cobrancas c
JOIN alunos a ON a.id = c.aluno_id
WHERE c.status = 'pendente'
  AND c.data_vencimento < CURDATE();

-- Ocupação das aulas hoje
CREATE OR REPLACE VIEW vw_ocupacao_aulas_hoje AS
SELECT
    au.id,
    au.nome                     AS aula,
    au.horario_inicio,
    au.horario_fim,
    au.vagas,
    COUNT(ag.id)                AS inscritos,
    au.vagas - COUNT(ag.id)     AS vagas_disponiveis,
    CONCAT(f.nome)              AS instrutor,
    s.nome                      AS sala
FROM aulas au
JOIN instrutores i   ON i.id = au.instrutor_id
JOIN funcionarios f  ON f.id = i.funcionario_id
JOIN salas s         ON s.id = au.sala_id
LEFT JOIN agendamentos_aula ag
    ON ag.aula_id = au.id
   AND ag.data_aula = CURDATE()
   AND ag.status = 'confirmado'
WHERE au.dia_semana = WEEKDAY(CURDATE())
  AND au.ativa = 1
GROUP BY au.id, au.nome, au.horario_inicio, au.horario_fim, au.vagas, f.nome, s.nome;

-- Estoque crítico de produtos
CREATE OR REPLACE VIEW vw_estoque_critico AS
SELECT
    p.id,
    p.nome,
    p.estoque,
    p.estoque_minimo,
    p.estoque - p.estoque_minimo AS diferenca,
    u.nome AS unidade
FROM produtos p
LEFT JOIN unidades u ON u.id = p.unidade_id
WHERE p.estoque <= p.estoque_minimo AND p.ativo = 1;

-- ============================================================
-- STORED PROCEDURES — REGRAS DE NEGÓCIO
-- ============================================================

DELIMITER $$

-- Registra acesso do aluno com validação completa
CREATE PROCEDURE sp_registrar_acesso(
    IN p_aluno_id   INT UNSIGNED,
    IN p_unidade_id INT UNSIGNED,
    OUT p_permitido TINYINT,
    OUT p_msg       VARCHAR(200)
)
BEGIN
    DECLARE v_mat_id        INT UNSIGNED;
    DECLARE v_status        VARCHAR(20);
    DECLARE v_acessos_hoje  TINYINT UNSIGNED;
    DECLARE v_max_acessos   TINYINT UNSIGNED;
    DECLARE v_cobranca_pend TINYINT;

    SET p_permitido = 0;

    -- Verifica matrícula ativa
    SELECT m.id, m.status, p.numero_acessos_dia
    INTO v_mat_id, v_status, v_max_acessos
    FROM matriculas m
    JOIN planos p ON p.id = m.plano_id
    WHERE m.aluno_id = p_aluno_id
      AND m.status = 'ativa'
      AND m.data_fim >= CURDATE()
    LIMIT 1;

    IF v_mat_id IS NULL THEN
        SET p_msg = 'Nenhuma matrícula ativa encontrada.';
        INSERT INTO acessos (aluno_id, unidade_id, matricula_id, negado, motivo_negado)
            VALUES (p_aluno_id, p_unidade_id, 0, 1, p_msg);
        LEAVE sp_registrar_acesso;
    END IF;

    -- Verifica cobranças em atraso (bloqueia acesso)
    SELECT COUNT(*) INTO v_cobranca_pend
    FROM cobrancas
    WHERE aluno_id = p_aluno_id
      AND status = 'pendente'
      AND data_vencimento < CURDATE() - INTERVAL 5 DAY;

    IF v_cobranca_pend > 0 THEN
        SET p_msg = 'Acesso bloqueado: pagamentos em atraso.';
        INSERT INTO acessos (aluno_id, unidade_id, matricula_id, negado, motivo_negado)
            VALUES (p_aluno_id, p_unidade_id, v_mat_id, 1, p_msg);
        LEAVE sp_registrar_acesso;
    END IF;

    -- Verifica limite de acessos diários
    IF v_max_acessos > 0 THEN
        SELECT COUNT(*) INTO v_acessos_hoje
        FROM acessos
        WHERE aluno_id = p_aluno_id
          AND DATE(entrada) = CURDATE()
          AND negado = 0;

        IF v_acessos_hoje >= v_max_acessos THEN
            SET p_msg = CONCAT('Limite diário de ', v_max_acessos, ' acesso(s) atingido.');
            INSERT INTO acessos (aluno_id, unidade_id, matricula_id, negado, motivo_negado)
                VALUES (p_aluno_id, p_unidade_id, v_mat_id, 1, p_msg);
            LEAVE sp_registrar_acesso;
        END IF;
    END IF;

    -- Acesso permitido
    INSERT INTO acessos (aluno_id, unidade_id, matricula_id, negado)
        VALUES (p_aluno_id, p_unidade_id, v_mat_id, 0);

    SET p_permitido = 1;
    SET p_msg = 'Acesso liberado!';
END$$

-- Agenda aluno em aula coletiva (com lista de espera automática)
CREATE PROCEDURE sp_agendar_aula(
    IN p_aluno_id INT UNSIGNED,
    IN p_aula_id  INT UNSIGNED,
    IN p_data     DATE,
    OUT p_status  VARCHAR(50),
    OUT p_msg     VARCHAR(200)
)
BEGIN
    DECLARE v_vagas      SMALLINT;
    DECLARE v_inscritos  SMALLINT;
    DECLARE v_posicao    SMALLINT;
    DECLARE v_existe     TINYINT;

    -- Verifica duplicata
    SELECT COUNT(*) INTO v_existe
    FROM agendamentos_aula
    WHERE aluno_id = p_aluno_id AND aula_id = p_aula_id AND data_aula = p_data
      AND status = 'confirmado';

    IF v_existe > 0 THEN
        SET p_status = 'DUPLICADO';
        SET p_msg = 'Aluno já inscrito nesta aula.';
        LEAVE sp_agendar_aula;
    END IF;

    SELECT vagas INTO v_vagas FROM aulas WHERE id = p_aula_id;

    SELECT COUNT(*) INTO v_inscritos
    FROM agendamentos_aula
    WHERE aula_id = p_aula_id AND data_aula = p_data AND status = 'confirmado';

    IF v_inscritos < v_vagas THEN
        INSERT INTO agendamentos_aula (aluno_id, aula_id, data_aula, status)
            VALUES (p_aluno_id, p_aula_id, p_data, 'confirmado');
        SET p_status = 'CONFIRMADO';
        SET p_msg = 'Inscrição confirmada com sucesso!';
    ELSE
        SELECT COALESCE(MAX(posicao), 0) + 1 INTO v_posicao
        FROM lista_espera_aulas
        WHERE aula_id = p_aula_id AND data_aula = p_data;

        INSERT INTO lista_espera_aulas (aluno_id, aula_id, data_aula, posicao)
            VALUES (p_aluno_id, p_aula_id, p_data, v_posicao);
        SET p_status = 'LISTA_ESPERA';
        SET p_msg = CONCAT('Aula lotada. Você é o nº ', v_posicao, ' na lista de espera.');
    END IF;
END$$

-- Congela matrícula com validações
CREATE PROCEDURE sp_congelar_matricula(
    IN p_matricula_id INT UNSIGNED,
    IN p_data_inicio  DATE,
    IN p_data_fim     DATE,
    IN p_motivo       TEXT,
    IN p_func_id      INT UNSIGNED,
    OUT p_ok          TINYINT,
    OUT p_msg         VARCHAR(200)
)
BEGIN
    DECLARE v_permite    TINYINT;
    DECLARE v_max_cong   TINYINT;
    DECLARE v_max_dias   SMALLINT;
    DECLARE v_cong_usados TINYINT;
    DECLARE v_dias_solicitados SMALLINT;

    SELECT p.permite_congelamento, p.max_congelamentos, p.dias_congelamento
    INTO v_permite, v_max_cong, v_max_dias
    FROM matriculas m JOIN planos p ON p.id = m.plano_id
    WHERE m.id = p_matricula_id AND m.status = 'ativa';

    SET p_ok = 0;

    IF v_permite = 0 THEN
        SET p_msg = 'Plano não permite congelamento.';
        LEAVE sp_congelar_matricula;
    END IF;

    SELECT COUNT(*) INTO v_cong_usados
    FROM congelamentos WHERE matricula_id = p_matricula_id;

    IF v_cong_usados >= v_max_cong THEN
        SET p_msg = CONCAT('Limite de ', v_max_cong, ' congelamento(s) atingido.');
        LEAVE sp_congelar_matricula;
    END IF;

    SET v_dias_solicitados = DATEDIFF(p_data_fim, p_data_inicio);
    IF v_dias_solicitados > v_max_dias THEN
        SET p_msg = CONCAT('Máximo permitido é ', v_max_dias, ' dias de congelamento.');
        LEAVE sp_congelar_matricula;
    END IF;

    INSERT INTO congelamentos (matricula_id, data_inicio, data_fim, motivo, aprovado_por)
        VALUES (p_matricula_id, p_data_inicio, p_data_fim, p_motivo, p_func_id);

    UPDATE matriculas
       SET status   = 'congelada',
           data_fim = DATE_ADD(data_fim, INTERVAL v_dias_solicitados DAY)
     WHERE id = p_matricula_id;

    SET p_ok = 1;
    SET p_msg = 'Matrícula congelada com sucesso. Data de fim ajustada.';
END$$

-- Gera cobranças mensais em lote
CREATE PROCEDURE sp_gerar_cobrancas_mensais(IN p_competencia DATE)
BEGIN
    INSERT INTO cobrancas (matricula_id, aluno_id, descricao, valor, data_vencimento, status)
    SELECT
        m.id,
        m.aluno_id,
        CONCAT('Mensalidade ', DATE_FORMAT(p_competencia, '%m/%Y')),
        p.valor,
        DATE_FORMAT(p_competencia, '%Y-%m-10'),  -- vencimento todo dia 10
        'pendente'
    FROM matriculas m
    JOIN planos p ON p.id = m.plano_id
    WHERE m.status = 'ativa'
      AND m.data_inicio <= p_competencia
      AND m.data_fim    >= p_competencia
      AND NOT EXISTS (
            SELECT 1 FROM cobrancas c2
             WHERE c2.matricula_id = m.id
               AND DATE_FORMAT(c2.data_vencimento, '%Y-%m') = DATE_FORMAT(p_competencia, '%Y-%m')
          );
END$$

-- Baixa de pagamento
CREATE PROCEDURE sp_registrar_pagamento(
    IN p_cobranca_id      INT UNSIGNED,
    IN p_forma_pgto_id    TINYINT UNSIGNED,
    IN p_funcionario_id   INT UNSIGNED,
    OUT p_ok              TINYINT,
    OUT p_msg             VARCHAR(200)
)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM cobrancas WHERE id = p_cobranca_id;
    SET p_ok = 0;

    IF v_status IS NULL THEN
        SET p_msg = 'Cobrança não encontrada.';
        LEAVE sp_registrar_pagamento;
    END IF;
    IF v_status = 'pago' THEN
        SET p_msg = 'Esta cobrança já foi paga.';
        LEAVE sp_registrar_pagamento;
    END IF;
    IF v_status = 'cancelado' THEN
        SET p_msg = 'Cobrança cancelada; não pode ser paga.';
        LEAVE sp_registrar_pagamento;
    END IF;

    UPDATE cobrancas
       SET status             = 'pago',
           data_pagamento     = CURDATE(),
           forma_pagamento_id = p_forma_pgto_id,
           funcionario_id     = p_funcionario_id
     WHERE id = p_cobranca_id;

    SET p_ok = 1;
    SET p_msg = 'Pagamento registrado com sucesso.';
END$$

-- Atualiza nota média do instrutor
CREATE PROCEDURE sp_atualizar_nota_instrutor(IN p_instrutor_id INT UNSIGNED)
BEGIN
    UPDATE instrutores
       SET nota_media = (
           SELECT ROUND(AVG(nota), 2)
           FROM avaliacoes_instrutor
           WHERE instrutor_id = p_instrutor_id
       )
     WHERE id = p_instrutor_id;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGERS — INTEGRIDADE E AUTOMAÇÃO
-- ============================================================

DELIMITER $$

-- Atualiza nota do instrutor após nova avaliação
CREATE TRIGGER trg_after_avaliacao_insert
AFTER INSERT ON avaliacoes_instrutor FOR EACH ROW
BEGIN
    CALL sp_atualizar_nota_instrutor(NEW.instrutor_id);
END$$

-- Desconta estoque ao vender
CREATE TRIGGER trg_after_item_venda_insert
AFTER INSERT ON itens_venda FOR EACH ROW
BEGIN
    UPDATE produtos
       SET estoque = estoque - NEW.quantidade
     WHERE id = NEW.produto_id;
END$$

-- Valida estoque antes de inserir item
CREATE TRIGGER trg_before_item_venda_insert
BEFORE INSERT ON itens_venda FOR EACH ROW
BEGIN
    DECLARE v_estoque INT;
    SELECT estoque INTO v_estoque FROM produtos WHERE id = NEW.produto_id;
    IF v_estoque < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para o produto selecionado.';
    END IF;
END$$

-- Bloqueia edição de acesso negado — apenas INSERT
CREATE TRIGGER trg_before_acesso_update
BEFORE UPDATE ON acessos FOR EACH ROW
BEGIN
    IF OLD.negado = 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Registros de acesso negado são imutáveis.';
    END IF;
END$$

-- Cancela agendamentos de aula quando aluno é desativado
CREATE TRIGGER trg_after_aluno_desativar
AFTER UPDATE ON alunos FOR EACH ROW
BEGIN
    IF NEW.ativo = 0 AND OLD.ativo = 1 THEN
        UPDATE agendamentos_aula
           SET status = 'cancelado', cancelado_em = NOW()
         WHERE aluno_id = NEW.id AND status = 'confirmado' AND data_aula >= CURDATE();
    END IF;
END$$

-- Expira matrículas vencidas automaticamente (chamado por evento)
CREATE TRIGGER trg_before_matricula_update
BEFORE UPDATE ON matriculas FOR EACH ROW
BEGIN
    IF NEW.data_fim < CURDATE() AND NEW.status = 'ativa' THEN
        SET NEW.status = 'expirada';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- EVENTO AGENDADO — MANUTENÇÃO AUTOMÁTICA DIÁRIA
-- ============================================================

SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_manutencao_diaria
ON SCHEDULE EVERY 1 DAY STARTS '2024-01-01 01:00:00'
DO
BEGIN
    -- Expira matrículas vencidas
    UPDATE matriculas
       SET status = 'expirada'
     WHERE status = 'ativa' AND data_fim < CURDATE();

    -- Marca cobranças pendentes como atrasadas
    UPDATE cobrancas
       SET status = 'atrasado'
     WHERE status = 'pendente' AND data_vencimento < CURDATE();

    -- Marca ausentes em aulas do dia anterior
    UPDATE agendamentos_aula
       SET status = 'ausente'
     WHERE status = 'confirmado' AND data_aula = CURDATE() - INTERVAL 1 DAY;
END$$

DELIMITER ;

-- ============================================================
-- DADOS INICIAIS (SEED)
-- ============================================================
INSERT INTO cargos (nome, descricao) VALUES
('Gerente',        'Responsável pela unidade'),
('Recepcionista',  'Atendimento e controle de acesso'),
('Financeiro',     'Gestão de cobranças e pagamentos'),
('TI',             'Suporte técnico');

INSERT INTO formas_pagamento (nome) VALUES
('Dinheiro'),('Cartão de Crédito'),('Cartão de Débito'),('PIX'),('Boleto Bancário');

INSERT INTO especialidades (nome) VALUES
('Musculação'),('Spinning'),('Pilates'),('Yoga'),('Natação'),
('Funcional'),('Crossfit'),('Zumba'),('Boxe');

INSERT INTO modalidades (nome, descricao) VALUES
('Musculação',  'Treino com pesos e máquinas'),
('Spinning',    'Ciclismo indoor'),
('Pilates',     'Condicionamento e alongamento'),
('Yoga',        'Equilíbrio corpo e mente'),
('Natação',     'Atividade aquática'),
('Funcional',   'Treino funcional'),
('Crossfit',    'Treino de alta intensidade'),
('Zumba',       'Dança fitness'),
('Boxe',        'Artes marciais fitness');

INSERT INTO categorias_equipamento (nome) VALUES
('Cardiovascular'),('Musculação'),('Peso Livre'),('Acessórios'),('Aquático');

INSERT INTO categorias_produto (nome) VALUES
('Suplementos'),('Roupas'),('Acessórios'),('Bebidas'),('Outros');

INSERT INTO planos (nome, descricao, duracao_meses, valor, valor_adesao,
                    permite_congelamento, max_congelamentos, dias_congelamento, numero_acessos_dia) VALUES
('Mensal Básico',    'Acesso livre musculação',     1,  99.90,  0.00, 0, 0,  0, 1),
('Trimestral',       'Musculação + 1 aula coletiva',3, 269.70, 0.00, 1, 1, 30, 1),
('Semestral Plus',   'Acesso total + personal',     6, 479.40, 0.00, 1, 2, 45, 0),
('Anual VIP',        'Acesso total ilimitado',      12,839.88, 0.00, 1, 3, 60, 0),
('Diária',           'Acesso por um dia',            0,  25.00, 0.00, 0, 0,  0, 1);

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
