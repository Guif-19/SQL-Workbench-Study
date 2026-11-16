# Relatorio de validacao

Execucao real em 16/11/2026 16:34:08 -03:00. Servidor: MySQL 8.4.13, Windows x64.

**44 verificacoes aprovadas; nenhuma falha.**

O arquivo principal foi executado inteiro pelo cliente nativo MySQL tres vezes. O banco terminou restaurado com 4 clientes, 4 contas e 12 movimentacoes.

- [x] Script completo pelo cliente nativo MySQL, sem erros
- [x] Segunda execucao completa, sem erros
- [x] Reexecucao preserva registros, saldos e permissoes
- [x] 4 clientes, 4 contas e 12 movimentacoes
- [x] 1 conta especial de 5000 e 3 convencionais
- [x] Minimo de 3 movimentacoes por conta
- [x] Saldos calculados com centavos exatos
- [x] Conta especial aceita saldo exatamente -5000
- [x] Conta convencional aceita saque ate saldo zero
- [x] Deposito em saldo negativo atualiza corretamente
- [x] Especial rejeita excesso de um centavo; nenhum efeito parcial
- [x] Convencional rejeita saldo negativo; nenhum efeito parcial
- [x] Rejeita valor zero; nenhum efeito parcial
- [x] Rejeita valor negativo; nenhum efeito parcial
- [x] Rejeita valor nulo; nenhum efeito parcial
- [x] Rejeita tipo invalido; nenhum efeito parcial
- [x] Rejeita conta inexistente; nenhum efeito parcial
- [x] Chave duplicada nao altera saldo pelo gatilho; nenhum efeito parcial
- [x] CPF duplicado e rejeitado; nenhum efeito parcial
- [x] CPF fora do formato e rejeitado; nenhum efeito parcial
- [x] Conta exige cliente existente; nenhum efeito parcial
- [x] Conta inicia somente com saldo zero; nenhum efeito parcial
- [x] Limite negativo e rejeitado; nenhum efeito parcial
- [x] Numero da conta e unico; nenhum efeito parcial
- [x] Nao permite reduzir limite abaixo da divida; nenhum efeito parcial
- [x] Correntista nao tem UPDATE; nenhum efeito parcial
- [x] Correntista nao tem DELETE; nenhum efeito parcial
- [x] Correntista nao tem CREATE; nenhum efeito parcial
- [x] Correntista nao tem DROP; nenhum efeito parcial
- [x] Correntista nao consulta tabelas administrativas; nenhum efeito parcial
- [x] Referencia impede apagar cliente com contas; nenhum efeito parcial
- [x] Referencia impede apagar conta com movimentos; nenhum efeito parcial
- [x] Correntista insere nas tres tabelas; cliente pode ter varias contas
- [x] Administrador corrige/exclui movimentos com ajuste do saldo
- [x] Correcao administrativa respeita limite
- [x] Exclusao de deposito sem fundos e rejeitada
- [x] Movimentacao nao troca de conta silenciosamente
- [x] Administrador cria, altera, manipula e remove objetos
- [x] INSERT de varias linhas e atomico quando uma delas falha
- [x] Testes transacionais preservam os registros iniciais
- [x] Consultas da apresentacao executam sem erros
- [x] Dois saques simultaneos: somente um usa os mesmos fundos
- [x] Reexecucao remove dados de teste e restaura a demonstracao
- [x] Estado final igual a primeira execucao

## Limites da validacao

- SQL testado no servidor e cliente nativo MySQL; o modelo visual e a interface do Workbench sao conferidos separadamente.
- As credenciais sao de demonstracao local.
- A reexecucao apaga os dados de ContaCorrente e recria os dois usuarios locais indicados no cabecalho.
- Alterar saldo diretamente como administrador pode produzir divergencia do historico; registrar operacoes financeiras pelas movimentacoes.

## Modelo e entrega

- Modelo .mwb gerado pela API nativa do Workbench 8.0.46, com 3 tabelas, 13 campos e 2 relacionamentos.
- Integridade ZIP/XML do modelo conferida apos a geracao.
- MER e DER exportados em SVG/PNG e conferidos visualmente.
- Abertura e execucao pela interface do Workbench serao conferidas no computador da outra pessoa da equipe, conforme solicitado.
- Servidor temporario de validacao encerrado apos os testes.
