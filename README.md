# Cluster Docker Swarm local com Vagrant

Laboratório com quatro VMs Ubuntu 22.04, Docker Engine e provisionamento automático.

| Máquina | IP privado | Papel |
| --- | --- | --- |
| master | 192.168.56.10 | Manager |
| node01 | 192.168.56.11 | Worker |
| node02 | 192.168.56.12 | Worker |
| node03 | 192.168.56.13 | Worker |

## Pré-requisitos

- Computador x86-64 com virtualização habilitada no BIOS/UEFI.
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) e [Vagrant](https://developer.hashicorp.com/vagrant/install) instalados e compatíveis entre si.
- 4 GB de RAM disponíveis para as VMs, além da memória do sistema hospedeiro; recomenda-se um computador com 8 GB ou mais.
- Internet para baixar a box, os pacotes e a imagem do teste opcional.
- Rede 192.168.56.0/24 disponível, sem conflito com VPN ou outra rede local.

O Docker será instalado dentro das VMs. Não é necessário instalar Docker Desktop.

## Executar

Clone o repositório e entre na pasta do projeto:

```powershell
git clone https://github.com/BigodeMarine/desafio-DIO-Clusters.git
cd desafio-DIO-Clusters
vagrant validate
vagrant up master --provider=virtualbox
vagrant up node01 node02 node03 --provider=virtualbox --no-parallel
```

Execute cada comando somente depois que o anterior terminar com sucesso. A primeira inicialização demora devido aos downloads. O manager é iniciado primeiro para publicar o token antes da entrada dos workers.

## Verificar

```powershell
vagrant status
vagrant ssh master -c "sudo docker node ls"
```

Resultado esperado: quatro nós com STATUS `Ready` e AVAILABILITY `Active`. Apenas `master` deve exibir `Leader` em MANAGER STATUS; os workers ficam com essa coluna vazia.

Para verificar um worker:

```powershell
vagrant ssh node01 -c "sudo docker info"
```

Procure `Swarm: active` e `Is Manager: false`.

## Teste opcional com um serviço

```powershell
vagrant ssh master -c "sudo docker service create --name web --replicas 3 --publish published=8080,target=80 nginx:stable-alpine"
vagrant ssh master -c "sudo docker service ls"
vagrant ssh master -c "sudo docker service ps web"
```

Aguarde `3/3` réplicas em execução. Abra http://192.168.56.10:8080 no navegador do computador hospedeiro. O Swarm pode agendar tarefas também no manager; isso é permitido neste laboratório.

Remova o serviço após o teste:

```powershell
vagrant ssh master -c "sudo docker service rm web"
```

## Como a automação funciona

1. O Vagrantfile define nomes, IPs, memória e CPU das quatro VMs.
2. `install-docker.sh` configura o repositório oficial, instala o Docker e habilita o serviço.
3. No master, `configure-swarm.sh` executa `docker swarm init` e obtém um token de worker.
4. A pasta do projeto é compartilhada em `/vagrant`. O token passa para os workers por `.swarm/worker-token`.
5. Cada worker executa `docker swarm join` com seu próprio IP privado.

O token é uma credencial do laboratório: `.swarm/` está no `.gitignore` e não deve ser publicado. Esta troca por pasta compartilhada destina-se ao ambiente local. Os comandos usam `sudo`, sem adicionar o usuário ao grupo docker.

Os scripts podem ser executados novamente sem reinicializar um Swarm ativo. Um worker já ativo é preservado; o script não migra automaticamente um nó de outro cluster. Para conferir se todos pertencem ao cluster correto, use `docker node ls` no master.

## Comandos de manutenção

Desligar sem excluir:

```powershell
vagrant halt
```

Religar as VMs existentes:

```powershell
vagrant up --provider=virtualbox --no-parallel
```

Reexecutar o provisionamento, se necessário:

```powershell
vagrant provision master
vagrant provision node01 node02 node03
```

Recriar o laboratório inteiro (exclui VMs e dados internos):

```powershell
vagrant destroy -f
Remove-Item -Recurse -Force .swarm -ErrorAction SilentlyContinue
vagrant up master --provider=virtualbox
vagrant up node01 node02 node03 --provider=virtualbox --no-parallel
```

Ao recriar somente o manager, os workers antigos não entram no novo cluster automaticamente. Para este laboratório, prefira recriar as quatro VMs juntas.

## Problemas comuns

- Se a rede escolhida estiver em uso, ajuste todos os IPs no Vagrantfile e recrie as VMs.
- Se um worker falhar, confira o master e repita `vagrant provision node01` (ou o nome correspondente).
- O firewall da rede privada deve permitir 2377/TCP (gerenciamento), 7946/TCP e UDP (descoberta) e 4789/UDP (overlay) entre as VMs. Para o teste web, permita também 8080/TCP entre o host e as VMs. Não exponha essas portas à internet.
- Arquivos `.sh` devem usar finais de linha LF; o `.gitattributes` registra essa configuração para Git.
- A box e os pacotes não estão fixados em versões específicas; o ambiente depende da disponibilidade dos downloads no momento da execução.

## Validação desta entrega

A sintaxe Bash foi verificada com `bash -n`. O ambiente usado para preparar estes arquivos não possui Vagrant/VirtualBox, portanto as VMs e o cluster não foram executados aqui. A validação funcional deve ser feita pelos comandos acima.

## Referências

- https://developer.hashicorp.com/vagrant/docs/multi-machine
- https://docs.docker.com/engine/install/ubuntu/
- https://docs.docker.com/engine/swarm/swarm-tutorial/
