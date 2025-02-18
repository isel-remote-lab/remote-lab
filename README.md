# Remote Lab

This project consists in a remote lab with access to a remote FPGA. This remote lab makes possible the remote configuration, visualization and manipulation of the remote FPGA.

Um aluno, ao aceder ao site, necessita de autenticar-se. Pode criar conta ou fazer login. Caso crie conta precisa de um código gerado pelo Professor. Em ambos os casos, caso haja sucesso na autenticação, o Aluno é reencaminhado para uma home page.

Na home page terá acesso à sua conta onde poderá fazer as alterações necessárias e logout (baseado no Moodle). No dashboard existem laboratórios que o Aluno está inscrito pelo Professor. O Aluno pode entrar no laboratório. Se o laboratório tiver livre o Aluno entra na sessão. Caso esteja ocupado entra numa fila de espera. Caso tenha marcado previamente uma sessão entra.

Já dentro de um laboratório o Aluno irá, dependendo do laboratório ter acesso ao material fornecido pelo professor para a realização do mesmo. Por exemplo, se o professor definir um laboratório onde se utilize uma FPGA (Intel De10Lite) para a realização do mesmo, o Aluno e/ou o grupo irá conseguir enviar código para a mesma, manipular as suas entradas e ver as suas saídas.

Se o aluno abandonar a sala do laboratório antes do tempo do seu slot terminar, o próximo aluno na fila irá poder entrar então no mesmo laboratório. Antes de este sair do laboratório, se previamente ao fim do seu slot uma mensagem de verificação irá aparecer. Se o aluno exceder o seu slot de tempo, uma mensagem aparece a avisar e o próximo aluno da fila pode então entrar no laboratório.


Um professor, ao aceder ao site, necessita também de se autenticar. Poderá também criar conta ou fazer login. Caso crie uma ocnta precisará, como o aluno, de um código gerado, desta vez por um Administrador. Em ambos os casos, caso haja sucesso na autenticação, o Professor é reencaminhado para a sua home page.

Nesta este terá a possibilidade de, como o aluno ver as definições de conta. Terá também na sua dashboard todas os laboratórios criados. Caso um Professor escolhe um dos laboratórios, este terá as opções de:


# Initial Ideas

> - [ ]  Uso de um código para criação de conta. Este código é gerado pelo Professor. Código único para cada aluno.
> - [ ]  No dashboard existir um calendário. Este calendário possibilitará a marcação de sessões nos laboratórios.
> - [ ]  Fila de espera para os laboratórios.
> - [ ]  Caso o Aluno tenha marcado uma sessão, tem de estar na fila de espera para entrar na mesma para ganhar prioridade.

# Roles

Existem as seguintes roles: Aluno, Professor e Administrador.
Cada role tem permissões únicas e as roles acima herdam as permissões das de baixo.

## Aluno

> Role mais baixa. Tem as permissões necessárias para configurar
