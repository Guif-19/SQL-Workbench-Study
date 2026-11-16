-- DDL de modelagem extraido de ContaCorrente.sql; nao substitui o script de entrega.
CREATE DATABASE IF NOT EXISTS ContaCorrente
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ContaCorrente;

CREATE TABLE Clientes (
    idCliente INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    CPF CHAR(11) NOT NULL,
    CONSTRAINT pk_clientes PRIMARY KEY (idCliente),
    CONSTRAINT uq_clientes_cpf UNIQUE (CPF),
    CONSTRAINT ck_clientes_nome CHECK (CHAR_LENGTH(TRIM(nome)) > 0),
    CONSTRAINT ck_clientes_cpf CHECK (
        CHAR_LENGTH(CPF) = 11 AND CPF NOT REGEXP '[^0-9]'
    )
) ENGINE = InnoDB;

CREATE TABLE ContasCorrentes (
    idConta INT UNSIGNED NOT NULL AUTO_INCREMENT,
    idCliente INT UNSIGNED NOT NULL,
    numeroConta VARCHAR(20) NOT NULL,
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    limiteCredito DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_contas PRIMARY KEY (idConta),
    CONSTRAINT uq_contas_numero UNIQUE (numeroConta),
    CONSTRAINT ck_contas_numero CHECK (CHAR_LENGTH(TRIM(numeroConta)) > 0),
    CONSTRAINT ck_contas_limite CHECK (limiteCredito >= 0.00),
    CONSTRAINT ck_contas_saldo CHECK (saldo >= -limiteCredito),
    INDEX ix_contas_cliente (idCliente),
    CONSTRAINT fk_contas_cliente FOREIGN KEY (idCliente)
        REFERENCES Clientes (idCliente)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE Movimentacoes (
    idMovimentacao INT UNSIGNED NOT NULL AUTO_INCREMENT,
    idConta INT UNSIGNED NOT NULL,
    tipoMovimentacao ENUM('DEPOSITO', 'SAQUE') NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    data DATETIME NOT NULL,
    CONSTRAINT pk_movimentacoes PRIMARY KEY (idMovimentacao),
    CONSTRAINT ck_movimentacoes_valor CHECK (valor > 0.00),
    CONSTRAINT ck_movimentacoes_tipo CHECK (
        tipoMovimentacao IN ('DEPOSITO', 'SAQUE')
    ),
    INDEX ix_movimentacoes_conta_data (idConta, data),
    CONSTRAINT fk_movimentacoes_conta FOREIGN KEY (idConta)
        REFERENCES ContasCorrentes (idConta)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB;

