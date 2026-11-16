-- Banco de Dados - Trabalho Avaliativo A1
-- Equipe: Renan Dos Santos; Gustavo Ruffato; Nyck Michel.
-- RGMs: acrescentar ao cabecalho se o professor solicitar.
-- Alvo: MySQL 8.0.16 ou superior, com InnoDB e CHECK efetivamente aplicado.
-- Execucao: abrir no Workbench com uma conexao de instalacao (ex.: root)
-- e executar o arquivo INTEIRO pelo comando de executar tudo.
-- ATENCAO: reinicializa APENAS o banco ContaCorrente e os dois usuarios
-- locais de demonstracao abaixo. Os dados anteriores desse banco sao apagados.
-- Senhas abaixo sao exclusivas deste trabalho academico local.

SET @a1_sql_mode_anterior = @@SESSION.sql_mode;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4;

-- 1. Recriacao controlada: a segunda execucao restaura o mesmo estado inicial.
DROP DATABASE IF EXISTS ContaCorrente;
DROP USER IF EXISTS 'Administrador'@'localhost', 'Correntista'@'localhost';

CREATE DATABASE ContaCorrente
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ContaCorrente;

-- 2. Perfis de acesso. Os privilegios ficam limitados a este banco.
CREATE USER 'Administrador'@'localhost' IDENTIFIED BY 'Admin_A1#2026!';
CREATE USER 'Correntista'@'localhost' IDENTIFIED BY 'Conta_A1#2026!';
GRANT ALL PRIVILEGES ON ContaCorrente.* TO 'Administrador'@'localhost';
GRANT SELECT, INSERT ON ContaCorrente.* TO 'Correntista'@'localhost';

-- 3. Estrutura e integridade referencial.
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

-- 4. Regras financeiras. O DEFINER permite ao correntista inserir movimentos
-- sem conceder UPDATE direto em ContasCorrentes.
-- Os gatilhos e as tabelas InnoDB participam da MESMA operacao: um erro na
-- insercao/edicao/exclusao desfaz tambem o efeito financeiro daquele comando.
DELIMITER $$

CREATE DEFINER = 'Administrador'@'localhost' TRIGGER trg_contas_bi
BEFORE INSERT ON ContasCorrentes
FOR EACH ROW
BEGIN
    IF NEW.saldo IS NULL OR NEW.saldo <> 0.00 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A conta deve iniciar com saldo zero; registre um deposito.';
    END IF;
END$$

CREATE DEFINER = 'Administrador'@'localhost' TRIGGER trg_movimentacoes_bi
BEFORE INSERT ON Movimentacoes
FOR EACH ROW
BEGIN
    DECLARE v_efeito DECIMAL(12,2);

    IF NEW.valor IS NULL OR NEW.valor <= 0.00 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O valor da movimentacao deve ser positivo.';
    END IF;
    IF NEW.tipoMovimentacao IS NULL
       OR NEW.tipoMovimentacao NOT IN ('DEPOSITO', 'SAQUE') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tipo de movimentacao invalido.';
    END IF;

    SET v_efeito = IF(NEW.tipoMovimentacao = 'DEPOSITO', NEW.valor, -NEW.valor);

    -- UPDATE condicional adquire bloqueio exclusivo na conta: dois saques
    -- concorrentes nao podem gastar o mesmo saldo disponivel.
    UPDATE ContasCorrentes
       SET saldo = saldo + v_efeito
     WHERE idConta = NEW.idConta
       AND saldo + v_efeito >= -limiteCredito;

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Conta inexistente ou saldo e limite insuficientes.';
    END IF;
END$$

-- O administrador pode corrigir uma movimentacao; aplica-se somente a
-- diferenca entre o efeito novo e o anterior, preservando o saldo.
CREATE DEFINER = 'Administrador'@'localhost' TRIGGER trg_movimentacoes_bu
BEFORE UPDATE ON Movimentacoes
FOR EACH ROW
BEGIN
    DECLARE v_diferenca DECIMAL(13,2);

    IF NEW.idConta <> OLD.idConta THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A conta de uma movimentacao existente nao pode ser alterada.';
    END IF;
    IF NEW.valor IS NULL OR NEW.valor <= 0.00 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O valor da movimentacao deve ser positivo.';
    END IF;
    IF NEW.tipoMovimentacao IS NULL
       OR NEW.tipoMovimentacao NOT IN ('DEPOSITO', 'SAQUE') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tipo de movimentacao invalido.';
    END IF;

    SET v_diferenca =
        IF(NEW.tipoMovimentacao = 'DEPOSITO', NEW.valor, -NEW.valor)
        - IF(OLD.tipoMovimentacao = 'DEPOSITO', OLD.valor, -OLD.valor);

    IF v_diferenca <> 0.00 THEN
        UPDATE ContasCorrentes
           SET saldo = saldo + v_diferenca
         WHERE idConta = OLD.idConta
           AND saldo + v_diferenca >= -limiteCredito;

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A correcao ultrapassaria o saldo e o limite disponiveis.';
        END IF;
    END IF;
END$$

-- A exclusao administrativa desfaz o efeito financeiro, se houver fundos.
CREATE DEFINER = 'Administrador'@'localhost' TRIGGER trg_movimentacoes_bd
BEFORE DELETE ON Movimentacoes
FOR EACH ROW
BEGIN
    DECLARE v_estorno DECIMAL(12,2);
    SET v_estorno = IF(OLD.tipoMovimentacao = 'DEPOSITO', -OLD.valor, OLD.valor);

    UPDATE ContasCorrentes
       SET saldo = saldo + v_estorno
     WHERE idConta = OLD.idConta
       AND saldo + v_estorno >= -limiteCredito;

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A exclusao ultrapassaria o saldo e o limite disponiveis.';
    END IF;
END$$

DELIMITER ;

-- 5. Massa fixa. Os CPFs abaixo sao identificadores FICTICIOS de teste,
-- sem validacao de digitos verificadores. Nao representam documentos reais.
-- As datas foram sorteadas previamente com semente 20261116 e fixadas,
-- para preservar o resultado identico nas proximas execucoes.
START TRANSACTION;

INSERT INTO Clientes (idCliente, nome, CPF) VALUES
    (1, 'Renan Dos Santos', '00000000001'),
    (2, 'Gustavo Ruffato',  '00000000002'),
    (3, 'Nyck Michel',     '00000000003'),
    (4, 'Ana Oliveira (cliente ficticio)', '00000000004');

INSERT INTO ContasCorrentes
    (idConta, idCliente, numeroConta, saldo, limiteCredito) VALUES
    (1, 1, '0001-1', 0.00, 5000.00),
    (2, 2, '0002-0', 0.00,    0.00),
    (3, 3, '0003-8', 0.00,    0.00),
    (4, 4, '0004-6', 0.00,    0.00);

INSERT INTO Movimentacoes
    (idMovimentacao, idConta, tipoMovimentacao, valor, data) VALUES
    ( 1, 1, 'DEPOSITO', 1000.00, '2026-09-27 14:32:00'),
    ( 2, 1, 'SAQUE',    2000.00, '2026-09-28 14:36:00'),
    ( 3, 1, 'DEPOSITO',  300.00, '2026-10-22 09:32:00'),
    ( 4, 2, 'DEPOSITO', 1500.50, '2026-09-01 17:40:00'),
    ( 5, 2, 'SAQUE',     250.25, '2026-09-25 18:23:00'),
    ( 6, 2, 'DEPOSITO',  100.00, '2026-11-06 17:15:00'),
    ( 7, 3, 'DEPOSITO', 2000.00, '2026-10-26 17:22:00'),
    ( 8, 3, 'SAQUE',     500.00, '2026-11-06 17:16:00'),
    ( 9, 3, 'DEPOSITO',  250.75, '2026-11-12 09:14:00'),
    (10, 4, 'DEPOSITO',  800.40, '2026-10-22 16:41:00'),
    (11, 4, 'SAQUE',     300.10, '2026-10-26 10:50:00'),
    (12, 4, 'DEPOSITO',   50.20, '2026-11-13 16:57:00');

COMMIT;

-- 6. Conferencias que nao provocam erros nem alteram a massa inicial.
SELECT c.nome, cc.numeroConta, cc.saldo, cc.limiteCredito,
       cc.saldo + cc.limiteCredito AS disponivel
FROM Clientes AS c
JOIN ContasCorrentes AS cc ON cc.idCliente = c.idCliente
ORDER BY cc.idConta;

SELECT cc.idConta, COUNT(m.idMovimentacao) AS quantidadeMovimentacoes,
       cc.saldo AS saldoGravado,
       COALESCE(SUM(IF(m.tipoMovimentacao = 'DEPOSITO', m.valor, -m.valor)), 0.00)
           AS saldoCalculado
FROM ContasCorrentes AS cc
LEFT JOIN Movimentacoes AS m ON m.idConta = cc.idConta
GROUP BY cc.idConta, cc.saldo
ORDER BY cc.idConta;

SHOW GRANTS FOR 'Administrador'@'localhost';
SHOW GRANTS FOR 'Correntista'@'localhost';

SET SESSION sql_mode = @a1_sql_mode_anterior;
