# Remote-Lab

This project consists in a remote lab with access to a remote FPGA. This remote lab makes possible the remote configuration, visualization and manipulation of the remote FPGA. 

Um aluno, ao aceder ao site, necessita de autenticar-se. Pode criar conta ou fazer login. Caso crie conta precisa de um código gerado pelo Professor. Em ambos os casos, caso haja sucesso na autenticação, o Aluno é reencaminhado para uma home page. 

Na home page terá acesso à sua conta onde poderá fazer as alterações necessárias e logout (baseado no Moodle). No dashboard existe laboratórios que o Aluno está inscrito pelo Professor. O Aluno pode entrar no laboratório. Se o laboratório tiver livre o Aluno entra na sessão. Caso esteja ocupado entra numa fila de espera. Caso tenha marcado previamente uma sessão entra. 

# Initial Ideas
> - [ ] Uso de um código para criação de conta. Este código é gerado pelo Professor. Código único para cada aluno.
> - [ ] No dashboard existir um calendário. Este calendário possibilitará a marcação de sessões nos laboratórios.
> - [ ] Fila de espera para os laboratórios.
> - [ ] Caso o Aluno tenha marcado uma sessão, tem de estar na fila de espera para entrar na mesma para ganhar prioridade.

# Roles

Existem as seguintes roles: Aluno, Professor e Administrador. 
Cada role tem permissões únicas e as roles acima herdam as permissões das de baixo.

## Aluno
> Role mais baixa. Tem as permissões necessárias para configurar
