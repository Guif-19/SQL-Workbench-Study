-- Consultas para a apresentacao e para as perguntas da pagina 5.
USE ContaCorrente;
SET @idCliente = 1;
SET @idConta = 1;
SET @inicio = '2026-09-01 00:00:00';
-- Limite superior EXCLUSIVO inclui todos os horarios do dia 30/11.
SET @fimExclusivo = '2026-12-01 00:00:00';

-- 1. Saldos, limites e dinheiro disponivel de todas as contas.
SELECT c.nome, cc.numeroConta, cc.saldo, cc.limiteCredito,
       cc.saldo + cc.limiteCredito AS disponivel
FROM Clientes c
JOIN ContasCorrentes cc ON cc.idCliente = c.idCliente
ORDER BY cc.idConta;

-- 2. Pergunta 6: contas com limite superior a R$ 3.000,00.
SELECT idConta, numeroConta, saldo, limiteCredito
FROM ContasCorrentes
WHERE limiteCredito > 3000.00;

-- 3. Pergunta 12: historico completo de uma conta.
SELECT idMovimentacao, tipoMovimentacao, valor, data
FROM Movimentacoes
WHERE idConta = @idConta
ORDER BY data, idMovimentacao;

-- 4. Pergunta 13: debitos e creditos por cliente em um periodo.
-- LEFT JOIN mantem o cliente mesmo se nao houver movimentos no periodo.
SELECT c.idCliente, c.nome,
       COALESCE(SUM(CASE WHEN m.tipoMovimentacao = 'DEPOSITO'
                         THEN m.valor ELSE 0.00 END), 0.00) AS totalCreditos,
       COALESCE(SUM(CASE WHEN m.tipoMovimentacao = 'SAQUE'
                         THEN m.valor ELSE 0.00 END), 0.00) AS totalDebitos
FROM Clientes c
LEFT JOIN ContasCorrentes cc ON cc.idCliente = c.idCliente
LEFT JOIN Movimentacoes m
       ON m.idConta = cc.idConta
      AND m.data >= @inicio AND m.data < @fimExclusivo
WHERE c.idCliente = @idCliente
GROUP BY c.idCliente, c.nome;

-- 5. Conferencia dos quatro clientes e do minimo de tres movimentos por conta.
SELECT (SELECT COUNT(*) FROM Clientes) AS clientes,
       COUNT(*) AS contas,
       SUM(limiteCredito = 5000.00) AS especiaisDe5000,
       SUM(limiteCredito = 0.00) AS convencionais
FROM ContasCorrentes;

SELECT cc.idConta, COUNT(m.idMovimentacao) AS movimentos
FROM ContasCorrentes cc
LEFT JOIN Movimentacoes m ON m.idConta = cc.idConta
GROUP BY cc.idConta
ORDER BY cc.idConta;

-- 6. Esta consulta deve retornar ZERO linhas: detecta saldo inconsistente.
SELECT cc.idConta, cc.saldo AS gravado,
       COALESCE(SUM(IF(m.tipoMovimentacao = 'DEPOSITO', m.valor, -m.valor)), 0.00)
           AS calculado
FROM ContasCorrentes cc
LEFT JOIN Movimentacoes m ON m.idConta = cc.idConta
GROUP BY cc.idConta, cc.saldo
HAVING gravado <> calculado;

-- 7. Exemplo da pergunta 10, DESATIVADO para preservar a massa da entrega.
-- Executar como Administrador somente se o professor pedir e depois desfazer:
-- START TRANSACTION;
-- UPDATE ContasCorrentes SET limiteCredito = 10000.00 WHERE idConta = 1;
-- SELECT * FROM ContasCorrentes WHERE idConta = 1;
-- ROLLBACK;
