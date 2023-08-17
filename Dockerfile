FROM centos:7
ENV container docker

# Remover alguns arquivos para ativar o systemd
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum clean all && \
    yum update -y && yum install -y \
    python3 \
    rsync \
    net-tools \
    vim \
    nano \
    sudo \
    sshpass \
    wget \
    make \
    unzip \
    tomcat \
    tomcat-webapps \
    tomcat-admin-webapps \
    yum install -y autoconf automake libtool \
    yum install -y gcc gcc-c++ cmake \
    yum install -y zlib-devel \
    yum install -y openssl-devel \
    yum install -y snappy snappy-devel \
    yum install -y bzip2 bzip2-devel \
    yum -y install openssh-server openssh-clients initscripts

# Cria grupo hadoop
RUN groupadd hadoop
# Cria usuário para a instalação do Hadoop e define a senha
RUN useradd -m hduser && echo "hduser:hduser" | chpasswd
# Adiciona o usuário criado ao grupo padrão wheel do super usuário do CentOS
RUN usermod -aG wheel hduser
# Adiciona usuário ao grupo hadoop
RUN usermod -aG hadoop hduser
# Transforma o usuário criado em um super usuário
RUN echo "hduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copia o arquivo de configuração do ssh
# StrictHostKeyChecking no = Desabilita pergunta / checagem de confiança de chave
# UserKnownHostsFile /dev/null = Não salva o nome do host, assim caso mude não corre o risco de fazer a pergunta de checagem
RUN echo '        StrictHostKeyChecking no' >> /etc/ssh/ssh_config
RUN echo '        UserKnownHostsFile=/dev/null' >> /etc/ssh/ssh_config

# Muda o usuário
USER hduser

# SSH - Configuração
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys

######### JAVA JDK 1.8 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - INÍCIO #########

# Copia os binários do JDK
ADD ./binarios/jdk /home/hduser/jdk

# Variáveis de ambiente JDK
ENV JAVA_HOME=/home/hduser/jdk
ENV PATH=$PATH:$JAVA_HOME:$JAVA_HOME/bin

# Variáveis de ambiente
RUN echo "PATH=$PATH:$JAVA_HOME/bin" >> ~/.bash_profile

######### JAVA JDK 1.8 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - FIM #########

######### HBASE 2.5.5 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - INÍCIO #########

# Copia os binários
ADD ./binarios/hbase /home/hduser/hbase

# Variáveis de ambiente
ENV HBASE_HOME=/home/hduser/hbase
ENV PATH=$PATH:$HBASE_HOME
ENV PATH=$PATH:$HBASE_HOME/bin
ENV CLASSPATH=$CLASSPATH:$HBASE_HOME/lib/*:.

# Pastas para os arquivos do Zookeeper
RUN mkdir /home/hduser/zookeeper

# Copia os arquivos de configuração
ADD ./config-files/backup-masters $HBASE_HOME/conf
ADD ./config-files/hbase-env.sh $HBASE_HOME/conf
ADD ./config-files/hbase-site.xml $HBASE_HOME/conf
ADD ./config-files/regionservers $HBASE_HOME/conf

######### HBASE 2.5.5 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - FIM #########

######### APACHE PHOENIX 5.1.3 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - INÍCIO #########

# Copia os binários
ADD ./binarios/phoenix /home/hduser/phoenix

# Variáveis de ambiente
ENV PHOENIX_HOME=/home/hduser/phoenix
ENV PATH=$PATH:$PHOENIX_HOME/bin

# Copia a biblioteca para HBase
RUN sudo cp /home/hduser/phoenix/phoenix-server-hbase-*.jar /home/hduser/hbase/lib/

######### APACHE PHOENIX 5.1.3 (BINÁRIOS E VARIÁVEIS DE AMBIENTE) - FIM #########

# Adiciona scripts
COPY script.sh /home/hduser
RUN sudo chmod +x /home/hduser/script.sh
# Executa script
RUN /bin/bash -c '/home/hduser/script.sh'

# Portas que poderão ser usadas
EXPOSE 16010 16020 16030 2181

# # Volta para usuário root, pois alguns processos são iniciados através dele
USER root
# setup new root password
RUN echo root:root | chpasswd

# Muda configuração do sistema
RUN echo '* soft nofile 102400' >> /etc/security/limits.conf
RUN echo '* hard nofile 409600' >> /etc/security/limits.conf
RUN echo 'session    required     /lib64/security/pam_limits.so' >> /etc/pam.d/login

CMD ["/usr/sbin/init"]

