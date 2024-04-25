
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

## 2. Deploy
