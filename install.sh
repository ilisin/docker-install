#!/bin/sh

set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

create_docker_compose_file() {
        dyf=$@

        if [ -f "$dyf" ]; then
                echo "$dyf exist,skip create it"
                return
        fi

        echo "nginx:" >> $dyf
        echo "        image: 192.168.10.40:5000/nginx" >> $dyf
        echo "        ports:" >> $dyf
        echo "                - 80:80" >> $dyf
        echo "$dyf had created!!"
}

create_docker_compose_service(){
        dyf=$1
        dcsf=$2
        if [ -f "$dcsf" ]; then
                echo "$dcsf exist,skip create it"
                return
        fi
        echo "[Unit]" >> $dcsf
        echo "Description=Docker Compose" >> $dcsf
        echo "Documentation=http://imooly.net/gaoguangting/docker-install" >> $dcsf
        echo "After=docker.service" >> $dcsf
        echo "Requires=docker.service" >> $dcsf
        echo "" >> $dcsf
        echo "[Service]" >> $dcsf
        echo "Type=notify" >> $dcsf
        echo "ExecStart=/usr/bin/docker-compose -f $dyf up -d" >> $dcsf
        echo "MountFlags=slave" >> $dcsf
        echo "LimitNOFILE=1048576" >> $dcsf
        echo "LimitNPROC=1048576" >> $dcsf
        echo "LimitCORE=infinity" >> $dcsf
        echo "" >> $dcsf
        echo "[Install]" >> $dcsf
        echo "WantedBy=multi-user.target" >> $dcsf
}

do_install() {

	if command_exists docker; then
		cat >&2 <<-'EOF'
			docker had been installed,skip it
		EOF
	else
		curl -sSL https://get.docker.com/ | sh
		cat >&2 <<-'EOF'
			docker install success!
		EOF
	fi

	sed -ri 's/(^ExecStart=\/usr\/bin\/docker\ daemon).*/\1 --insecure-registry 192.168.10.40:5000 -H fd:\/\//' /usr/lib/systemd/system/docker.service
	systemctl daemon-reload
	echo "add insecure registry to docker config!!"

	systemctl enable docker.service
	echo "docker enalbe after boot!!"

	systemctl stop firewalld.service
	echo "firewall been stoped!!"

	systemctl disable firewalld.service
	echo "firewall disable after boot!!"

	sed -ri 's/(^SELINUX=).*/\1disabled/' /etc/sysconfig/selinux	
	echo "selinux disable ofter boot!!"

	if command_exists docker-compose; then
		echo "docker compose had been installed,skip it"
	else
		echo "installing docker-compose"
		yum -y install epel-release
		yum -y install python-pip
		pip install docker-compose
		echo "docker-compose been installed!"
	fi
	
	dcf="/root/docker-compose.yml"
	create_docker_compose_file $dcf

	dcsf="/usr/lib/systemd/system/docker-compose.service"
	create_docker_compose_service $dcf $dcsf

	systemctl daemon-reload
	systemctl enable docker-compose

	echo "complete!!,plase reboot now"
}

do_install
