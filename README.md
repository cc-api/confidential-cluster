
# Trusted Cluster enhanced by CC API & CCNP

## 1. Definitions

**Confidential Cluster** is defined by:

- [Redhat](https://www.redhat.com/en/blog/confidential-computing-use-cases): A confidential cluster (CCl) is a cluster of confidential virtual machines, which are considered to be part of a single trust domain
- [Google](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes): Confidential GKE Nodes is built on top of Compute Engine Confidential VM, which encrypts the memory contents of VMs in-use. Confidential GKE Nodes can be enabled as a cluster-level security setting or a node pool-level security setting.
- [Edgeless](https://www.edgeless.systems/products/constellation/): Leverages confidential computing to isolate entire Kubernetes clusters from the infrastructure.

**Trusted Cluster** is End-to-End measurement for Confidential Cluster:

![](/docs/trusted_kubernetes_cluster.png)

In above diagram:

- **CCNP** is used to calculate the measurement for node, namespace,
POD and cluster level.
- **CC Trusted API** provided unified API to tenant to access measurement, event log
and quote (report).

## 2. Confidential Cluster

### 2.1 Existing CSPs

|          | Google GKE    | Azure AKS |
| -------- | ------------- | --------- |
| Resource | [N2D(AMD EPYC)](https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machines)/[C3(Intel Sapphire Rapids)](https://cloud.google.com/compute/docs/general-purpose-machines#c3_series) | DCasv5/ECasv5(AMD), [DCesv5/ECesv5(Intel)](https://learn.microsoft.com/en-us/azure/virtual-machines/ecesv5-ecedsv5-series) |
| OS       | [CentOS/ContainerOS/Debian/Fedora/RHEL/...](https://cloud.google.com/compute/docs/images/os-details#limited_operating_system_support) | Ubuntu Server 22.04 LTS/SUSE Linux Enterprise Server/Red Hat Enterprise Linux |
| CPU Accelerator | [AMX](https://cloud.google.com/compute/docs/cpu-platforms#intel-amx) | AMX |
| Full Disk Encryption | [Yes](https://cloud.google.com/compute/docs/disks/customer-managed-encryption) | [Yes](https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption-overview) |
| Key | customer-managed encryption keys (CMEK) | PMK (platform-managed key) and CMK (customer-managed key) |
| Attestation | [Google Managed vTPM](https://cloud.google.com/confidential-computing/confidential-vm/docs/attestation) | [Microsoft Azure Attestation](https://azure.microsoft.com/en-us/products/azure-attestation/)/[Intel® Trust Authority](https://www.intel.com/content/www/us/en/security/trust-authority.html) |
| Tutorial | [Here](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes#enabling_in_a_new_cluster) | [here](https://learn.microsoft.com/en-us/azure/confidential-computing/confidential-vm-overview)

## 3. Deploy
