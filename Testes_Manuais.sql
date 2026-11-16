-- Executar APENAS os blocos indicados, um de cada vez, no Workbench.
-- Os blocos de rejeicao provocam erros ESPERADOS e nao pertencem ao script
-- principal da entrega. Executar ROLLBACK mesmo quando o Workbench parar no erro.
USE ContaCorrente;

-- A. COMO CORRENTISTA: saque permitido ate o limite especial.
START TRANSACTION;
INSERT INTO Movimentacoes (idConta, tipoMovimentacao, valor, data)
VALUES (1, 'SAQUE', 4300.00, '2026-11-16 18:00:00');
SELECT idConta, saldo, limiteCredito FROM ContasCorrentes WHERE idConta = 1;
-- Esperado: saldo -5000.00.
ROLLBACK;

-- B. COMO CORRENTISTA: ultrapassar o limite deve falhar.
START TRANSACTION;
INSERT INTO Movimentacoes (idConta, tipoMovimentacao, valor, data)
VALUES (1, 'SAQUE', 4300.01, '2026-11-16 18:01:00');
-- Esperado: erro de saldo/limite; conta permanece em -700.00.
ROLLBACK;

-- C. COMO CORRENTISTA: conta convencional sem fundos deve rejeitar o saque.
START TRANSACTION;
INSERT INTO Movimentacoes (idConta, tipoMovimentacao, valor, data)
VALUES (2, 'SAQUE', 1350.26, '2026-11-16 18:02:00');
ROLLBACK;

-- D. COMO CORRENTISTA: deposito em saldo negativo e permitido.
START TRANSACTION;
INSERT INTO Movimentacoes (idConta, tipoMovimentacao, valor, data)
VALUES (1, 'DEPOSITO', 100.00, '2026-11-16 18:03:00');
SELECT idConta, saldo FROM ContasCorrentes WHERE idConta = 1;
-- Esperado: -600.00.
ROLLBACK;

-- E. COMO CORRENTISTA: as tres operacoes abaixo devem ser negadas.
-- Executar cada instrucao separadamente.
-- UPDATE ContasCorrentes SET limiteCredito = 10000.00 WHERE idConta = 1;
-- DELETE FROM Movimentacoes WHERE idMovimentacao = 3;
-- CREATE TABLE OperacaoNaoPermitida (id INT);

-- F. COMO ADMINISTRADOR: corrigir e excluir movimento atualiza o saldo.
START TRANSACTION;
UPDATE Movimentacoes SET valor = 350.00 WHERE idMovimentacao = 3;
SELECT saldo FROM ContasCorrentes WHERE idConta = 1; -- -650.00
DELETE FROM Movimentacoes WHERE idMovimentacao = 3;
SELECT saldo FROM ContasCorrentes WHERE idConta = 1; -- -1000.00
ROLLBACK;
