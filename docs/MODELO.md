# Modelo e dicionario de dados

## Modelo conceitual

Um cliente possui uma ou mais contas-correntes; uma conta pertence a exatamente
um cliente. Uma conta registra uma ou mais movimentacoes; uma movimentacao
pertence a exatamente uma conta. Cada movimentacao e um deposito ou um saque.

As cardinalidades minimas de uma conta por cliente e uma movimentacao por conta
sao regras do cenario. As FKs garantem que o registro dependente tenha um pai
existente; elas, isoladamente, nao obrigam um cliente recem-cadastrado a ja ter
uma conta nem uma conta recem-cadastrada a ja ter movimentos. A massa inicial
completa atende ao enunciado: cada cliente possui uma conta, cada conta tem tres movimentos.

## Modelo fisico

### Clientes

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `idCliente` | `INT UNSIGNED` | PK, AUTO_INCREMENT, obrigatorio |
| `nome` | `VARCHAR(120)` | Obrigatorio, nao vazio |
| `CPF` | `CHAR(11)` | Obrigatorio, UNIQUE, onze digitos; sem validacao dos digitos verificadores |

### ContasCorrentes

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `idConta` | `INT UNSIGNED` | PK, AUTO_INCREMENT, obrigatorio |
| `idCliente` | `INT UNSIGNED` | FK para Clientes.idCliente, obrigatorio |
| `numeroConta` | `VARCHAR(20)` | Obrigatorio, UNIQUE, nao vazio |
| `saldo` | `DECIMAL(12,2)` | Obrigatorio, DEFAULT 0.00, saldo >= -limiteCredito |
| `limiteCredito` | `DECIMAL(12,2)` | Obrigatorio, DEFAULT 0.00, limite >= 0 |

### Movimentacoes

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `idMovimentacao` | `INT UNSIGNED` | PK, AUTO_INCREMENT, obrigatorio |
| `idConta` | `INT UNSIGNED` | FK para ContasCorrentes.idConta, obrigatorio |
| `tipoMovimentacao` | `ENUM('DEPOSITO','SAQUE')` | Obrigatorio, somente os dois tipos validos |
| `valor` | `DECIMAL(12,2)` | Obrigatorio, estritamente positivo |
| `data` | `DATETIME` | Data e hora obrigatorias |

Todos os campos sao `NOT NULL`. As tabelas usam InnoDB e o banco usa utf8mb4.
As duas FKs usam `ON UPDATE RESTRICT ON DELETE RESTRICT`, evitando apagar
clientes com contas ou contas com historico. O indice `(idConta, data)` ajuda
consultas de historico por conta e periodo.

## Saldo e conta especial

`disponivel = saldo + limiteCredito`

`saldo >= -limiteCredito`

Conta convencional tem limite zero. A conta especial da massa de dados tem
limite de R$ 5.000,00 e pode atingir saldo de -R$ 5.000,00. Somente a massa
inicial e limitada a uma conta especial; o modelo permite outros cadastros
conforme os privilegios concedidos pelo enunciado.

Toda conta comeca com saldo zero. O saldo e armazenado na conta e atualizado
pelos movimentos. Deve ser igual a soma dos depositos menos a soma dos saques.
`Consultas.sql` inclui uma consulta que identifica divergencias.

## Gatilhos

| Gatilho | Momento | Efeito |
| --- | --- | --- |
| `trg_contas_bi` | Antes de inserir conta | Exige saldo inicial zero |
| `trg_movimentacoes_bi` | Antes de inserir movimento | Valida o movimento e aplica seu efeito ao saldo |
| `trg_movimentacoes_bu` | Antes de atualizar movimento | Aplica a diferenca entre o efeito novo e o anterior; impede troca de conta |
| `trg_movimentacoes_bd` | Antes de excluir movimento | Desfaz o efeito anterior, respeitando o limite |

O `UPDATE` condicional na conta combina teste do limite e alteracao do saldo
numa operacao que bloqueia a linha. Se dois saques disputarem fundos,
somente os que couberem no disponivel poderao concluir. Um `SIGNAL SQLSTATE
'45000'` explica a rejeicao; com InnoDB, o erro desfaz os efeitos daquele comando.

O definidor dos gatilhos e `Administrador@localhost`. Por isso, o perfil
correntista insere movimentos sem receber privilegio direto de UPDATE.

Referencias: [gatilhos](https://dev.mysql.com/doc/refman/8.4/en/trigger-syntax.html),
[contexto do definidor](https://dev.mysql.com/doc/refman/8.4/en/stored-objects-security.html),
[CHECK](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html).

## Escopo dos privilegios

O administrador tem `ALL PRIVILEGES` em `ContaCorrente.*`; o correntista tem
`SELECT, INSERT` no mesmo banco. Nenhum recebe privilegios globais pelo script.
O script de instalacao deve ser executado por outra conta que possa criar
usuarios e atribuir o definidor dos gatilhos, como o root do ambiente academico.

O administrador tem acesso suficiente para alterar diretamente o saldo ou
a estrutura. A consistencia entre saldo e historico depende de usar as
movimentacoes para operacoes financeiras; privilegio administrativo permite
manutencao fora desse fluxo. A aplicacao nao implementa acesso individual por
cliente, autorizacao de concessao de credito ou validacao bancaria de CPF.

## Idempotencia

A estrategia e reinicializacao de um ambiente de demonstracao: remover o banco
e os dois usuarios locais do trabalho, recriar a estrutura e reinserir a mesma
massa fixa. O resultado final e repetivel; dados acrescentados entre execucoes
sao intencionalmente removidos. Nao e uma migracao de producao.
