#!/bin/bash

set -e

http_proxy=${http_proxy:-}
https_proxy=${https_proxy:-}
no_proxy=${no_proxy:-}

function setup_proxy {
	cat <<-EOF | sudo tee -a "/tmp/environment"
http_proxy = "${http_proxy}"
https_proxy = "${https_proxy}"
no_proxy = "${no_proxy}"
HTTP_PROXY = "${http_proxy}"
HTTPS_PROXY = "${https_proxy}"
NO_PROXY = "${no_proxy}"
EOF


	#cat <<-EOF | sudo tee -a "/etc/profile.d/myenvvar.sh"
	cat <<-EOF | sudo tee -a "/tmp/myenvvar.sh"
http_proxy = "${http_proxy}"
https_proxy = "${https_proxy}"
no_proxy = "${no_proxy}"
EOF

	sudo sh -c 'systemctl set-environment http_proxy="${http_proxy}"'
	sudo sh -c 'systemctl set-environment https_proxy="${https_proxy}"'
	sudo sh -c 'systemctl set-environment no_proxy="${no_proxy}"'
}

function install_docker {
	# install GPG key
	install -m 0755 -d /etc/apt/keyrings
	rm -f /etc/apt/keyrings/docker.gpg
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	chmod a+r /etc/apt/keyrings/docker.gpg

	# install repo
	echo \
	"deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt-get update > /dev/null

	# install docker
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	systemctl enable docker

	add_docker_proxy_for_builds
	
	# Add proxy for docker and containerd. This proxy is used in docker pull

	services=("containerd" "docker")
        add_systemd_service_proxy "${services[@]}"
}

function add_docker_proxy_for_builds() {
	mkdir -p /home/tdx/.docker
	cat <<-EOF | sudo tee  "/home/tdx/.docker/config.json"
{
 "proxies": {
   "default": {
     "httpProxy": "${http_proxy}", 
     "httpsProxy": "${https_proxy}",
     "noProxy": "${no_proxy}"
   }
 }
}
EOF
}

function install_helm {
    # install repo
    curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
    tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
    apt-get update > /dev/null

    # install helm
    apt-get install -y helm
}


function install_pip {
	# install python3-pip
	apt install -y python3-pip 
}

function install_k3s {
	 curl -sfL https://get.k3s.io | sh -

	#configure proxy
	local k3s_env_file="/etc/systemd/system/k3s.service.env"
	cat <<-EOF | sudo tee -a $k3s_env_file
HTTP_PROXY="${http_proxy}"
HTTPS_PROXY="${https_proxy}"
NO_PROXY="${no_proxy}"
EOF

}

function install_k8s {
	sudo -E bash -c 'apt-get -y clean'

	# Install Kubernetes:
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo -E apt update
	sudo -E apt install -y kubelet kubeadm kubectl

	# Packets traversing the bridge should be sent to iptables for processing
	echo br_netfilter | sudo -E tee /etc/modules-load.d/k8s.conf
	sudo -E bash -c 'echo "net.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/k8s.conf'
	sudo -E bash -c 'echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf'
	sudo -E bash -c 'echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf'
	sudo -E sysctl --system

	# disable swap
	swapoff -a
	sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

	services=("kubelet")
	add_systemd_service_proxy "${services[@]}"
}

function add_systemd_service_proxy() {
	local components=("$@")
	 # Config proxy
	local HTTPS_PROXY="$HTTPS_PROXY"
	local https_proxy="$https_proxy"
	if [ -z "$HTTPS_PROXY" ]; then
		HTTPS_PROXY="$https_proxy"
	fi

	local HTTP_PROXY="$HTTP_PROXY"
	local http_proxy="$http_proxy"
	if [ -z "$HTTP_PROXY" ]; then
		HTTP_PROXY="$http_proxy"
	fi

	local NO_PROXY="$NO_PROXY"
	local no_proxy="$no_proxy"
	if [ -z "$NO_PROXY" ]; then
		NO_PROXY="$no_proxy"
	fi

	if [[ -n $HTTP_PROXY ]] || [[ -n $HTTPS_PROXY ]] || [[ -n $NO_PROXY ]]; then
		for component in "${components[@]}"; do
			echo "component: " "${component}"
			mkdir -p /etc/systemd/system/"${component}.service.d"/
			tee /etc/systemd/system/"${component}.service.d"/http-proxy.conf <<EOF
[Service]
Environment=\"HTTP_PROXY=${HTTP_PROXY}\"
Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"
Environment=\"NO_PROXY=${NO_PROXY}\"
EOF
			systemctl daemon-reload
			systemctl restart ${component}
		done
	fi
}



function main {
	setup_proxy
	
	# install pre-reqs
	sudo -E bash -c 'apt-get update && sudo -E apt install -y curl'
	
	install_docker
	install_helm
	#install_pip
	install_k8s
	install_k3s
}

main $@
