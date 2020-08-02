INSTALL_K8S_AMBIENTE
=========

Instala o k8s nas instâncias criadas.

Requisitos
------------

Ter 3 instâncias na aws criadas.

Role Variables
--------------
Necessário adicionar os ips das máquinas criadas no arquivo hosts.
[k8s-master] ip público
K8S_MASTER_NODE_IP= Ip privado da mesma instância

[k8s-workers] ip público das outras intâncias


Dependências
------------

Realiza a instalação das dependencias pelo pretask nas três máquinas;


Example Playbook
----------------

- hosts: all
  become: yes
  user: ubuntu
  gather_facts: no
  pre_tasks:
  - name: 'Atualizando o repo'
    raw: 'apt-get update'
  - name: 'Instalando o Python'
    raw: 'apt-get install -y python'
  roles:
  - { role: install-k8s, tags: ["install_k8s_role"]  }

- hosts: k8s-master
  become: yes
  user: ubuntu
  roles:
  - { role: create-cluster, tags: ["create_cluster_role"] }

- hosts: k8s-workers
  become: yes
  user: ubuntu
  roles:
  - { role: join-workers, tags: ["join_workers_role"] }

- hosts: k8s-master
  become: yes
  user: ubuntu
  roles:
  - { role: install-helm, tags: ["install_helm3_role"] }

- hosts: k8s-master
  become: yes
  user: ubuntu
  roles:
  - { role: install-monit-tools, tags: ["install_monit_tools_role"] }

