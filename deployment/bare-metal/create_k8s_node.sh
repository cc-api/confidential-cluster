#!/bin/bash
#
# Copyright (c) 2020 Intel Corporation
# 
# SPDX-License-Identifier: Apache-2.0
# 

#set -o xtrace
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

pod_network_cidr=${pod_network_cidr:-"10.244.0.0/16"}
cni_project=${cni_project:-"calico"}

init_cluster() {
	if [ -d "$HOME/.kube" ]; then
        	rm -rf "$HOME/.kube"
    	fi

	sudo bash -c 'modprobe br_netfilter'
	sudo bash -c 'modprobe overlay'
	sudo bash -c 'swapoff -a'

	# initialize cluster
	#sudo -E kubeadm init --config=./kubeadm.yaml
	kubeadm init --pod-network-cidr=${pod_network_cidr}

	mkdir -p "${HOME}/.kube"
	cp /etc/kubernetes/admin.conf $HOME/.kube/config
        chown $(id -u):$(id -g) $HOME/.kube/config

	# taint master node:
	kubectl taint nodes --all node-role.kubernetes.io/master-
}

install_cni() {

	if [[ $cni_project == "calico" ]]; then
		calico_url="https://projectcalico.docs.tigera.io/manifests/calico.yaml"
		kubectl apply -f $calico_url
	else
		flannel_url="https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
		kubectl apply -f $flannel_url
	fi
}

main() {
	init_cluster
	install_cni
}

main $@ 
