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

http_proxy=${http_proxy:-}
https_proxy=${https_proxy:-}
no_proxy=${no_proxy:-}

tdx_repo_url="https://github.com/canonical/tdx"
tdx_repo="tdx-repo-dir"

image_rewriter_url="https://github.com/cc-api/cvm-image-rewriter/"
image_rewriter_repo="/tmp/image-writer-dir"

cima_url="https://github.com/cc-api/container-integrity-measurement-agent"
cima_repo="/tmp/cima_repo"

cloud_img_url="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
cloud_img="/tmp/noble-server-cloudimg-amd64.img"

CURR_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GUEST_IMG="tdx-guest-ubuntu-24.04-intel.qcow2"

cleanup() {
	# Todo: Kill any VMS
	return
}

create_tdx_image() {
	# Install pre-requisites
	sudo apt -y install git
	sudo apt --no-install-recommends -y install qemu-utils guestfs-tools virtinst genisoimage libvirt-daemon-system libvirt-daemon

	rm -rf "${tdx_repo}"
	mkdir "${tdx_repo}"
	git clone "${tdx_repo_url}" "${tdx_repo}"

	pushd "${tdx_repo}/guest-tools/image"
	# create tdx-guest-ubuntu-24.04-generic.qcow2
	sudo -E ./create-td-image.sh
	popd

	# image is created under ${tdx_repo/guest-tools/image/tdx-guest-ubuntu-24.04-generic.qcow2"
	img_name="tdx-guest-ubuntu-24.04-generic.qcow2"
	mv "${tdx_repo}/guest-tools/image/${img_name}" /tmp/${GUEST_IMG}
}

create_tdx_image_cc_image_writer() {
	# TODO generate image using the cc-image-writer (https://github.com/cc-api/cvm-image-rewriter)
	# TODO: clone and create plugin to install k8s dependencies

	rm -rf "${cima_repo}"
	mkdir "${cima_repo}"
	git clone "${cima_repo_url}" "${cima_repo}"

	pushd ${cima_repo}/tools/build
	sudo -E ./build.sh
	popd

	rm -rf "${image_rewriter_repo}"
	mkdir "${image_rewriter_repo}"
	git clone "${image_rewriter_url}" "${image_rewriter_repo}"

	curl --output "${cloud_img}" "${cloud_img_url}"

	pushd "${image_rewriter_repo}"
	touch plugins/98-ima-example/NOT_RUN
	export CVM_TDX_GUEST_REPO="${cima_reo}/tools/build/output"
	./run.sh -i "${cloud_img}"  -t 15
}

setup_guest_image() {
    virt-customize -a ${image_rewriter_repo}/output.qcow2 \
       --mkdir /tmp/tdx/ \
       --copy-in ${CURR_DIR}/install_dependencies.sh:/tmp/tdx/ \
       --copy-in ${CURR_DIR}/create_k8s_node.sh:/home/tdx/ \
       --run-command "http_proxy=${http_proxy} https_proxy=${https_proxy} no_proxy=${no_proxy} /tmp/tdx/install_dependencies.sh"
    if [ $? -eq 0 ]; then
        ok "Setup guest image..."
    else
        error "Failed to setup guest image"
    fi
}

check_tdx_version() {
	# Check for tdx version in demesg?
	# version seems to be relaible only on Ubuntu, not on Centos
	local tdx_line=$(sudo sh -c 'dmesg | grep "TDX module"')
	if [ -n "$tdx_line" ]; then
		local major_version=$(echo $tdx_line | grep -oP 'major_version \K[0-9]+')
		local minor_version=$(echo $tdx_line | grep -oP 'minor_version \K[0-9]+')
		local build_date=$(echo $tdx_line | grep -oP 'build_date \K[0-9]+')
		local build_num=$(echo $tdx_line | grep -oP 'build_num \K[0-9]+')
		
  		echo "Major Version: $major_version"
  		echo "Minor Version: $minor_version"
  		echo "Build date: $build_date"
  		echo "Minor Version: $build_num"
	else
		echo "Could not determine TDX version"
	fi
}

launch_cc_k3s() {
	# Start k3s cluster within TD VM
}

launch_cc_k8s() {
	# Starts k8s cluster within TD VM
	# 1) Start qemu VM
	# 2) ssh into the VM
	# 3) Start a single node k8s cluster with master marked as worker
}

install_pre_reqs() {
	sudo -E apt install -y qemu-utils guestfs-tools virtinst genisoimage libvirt-daemon-system libvirt-daemon cloud-init
	sudo usermod -aG libvirt $USER
	sudo chmod o+r /boot/vmlinuz-*

	cat <<-EOF | sudo tee -a "/etc/libvirt/qemu.conf"
user = "root"
group = "root"
dynamic_ownership = 0
	EOF

	sudo systemctl daemon-reload
	sudo systemctl restart libvirt
}


main() {
	trap cleanup EXIT

	echo "http_proxy: " "${http_proxy}"
	echo "https_proxy: " "${https_proxy}"
	echo "no_proxy: " "${no_proxy}"

	launch_with_k3s=${launch_with_k3s:-false}

	# Check tdx version and warn if using obsolete
	check_tdx_version()

	# Install dependencies for building tdx image
	install_pre_reqs()

	# Creates a VM image with TDX support
	create_tdx_image()

	# Installs dependencies in the guest image including k3s, k8s, docker, helm
	# and configures proxy for each one
	setup_guest_image()

	if launch_with_k3s == true {
		launch_cc_k3s()
	else {
		launch_cc_k8s()
	}
}

main $@    

