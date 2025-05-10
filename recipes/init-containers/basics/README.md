# Introduction to Init Containers

Apart from the *main containers* that run the app logic, the most popular types of additional helper containers in Kubernetes ecosystem are:
- Init containers
- Sidecar containers

![](../../img/init_containers.png)

**Init containers** in Kubernetes are specialized containers that **run and complete before the main application containers** in a Pod start. They are defined in the Pod's specification and are used to perform setup tasks, such as initializing configurations, downloading dependencies, or ensuring prerequisites are met.

**Key Characteristics:**
- **Sequential Execution**: Init containers run one at a time, in the order defined, and each must complete successfully before the next starts or the main containers begin.
- **One-Time Tasks**: They are designed for short-lived tasks and terminate after completion. If an init container fails, the Pod restarts (subject to its restart policy) until the init container succeeds.
- **Separate Images**: Init containers can use different container images from the main application containers, allowing for modular setup tasks.
- **Shared Resources**: They share the same Pod environment (e.g., volumes, network namespace) as the main containers, enabling them to prepare the environment or populate shared volumes.

## Use Cases

Most often init containers used for:
- **Wait for a database service to be ready** before starting the app.
- **Inject configuration files or secrets** into a shared volume for the main app container.
- **Perform database schema migrations** before launching the main app.
- Init containers can **load and configure dependencies** needed by the main application container before it starts running.
- You can **warm up a cache** using the init container. For example, preloading some frequently used data into the Redis cache.
- Init containers can handle tasks such as **establishing network configuration** or **establishing connections to external services**.
- Init containers can **clone Git repositories** or **write files into attached pod volumes**
- Init containers can **perform security checks**, such as vulnerability scanning or TLS certificate verification, before starting the main application container.
- Init containers can handle tasks such as creating directories, applying permissions, or running custom scripts to **set up the environment for the main application**.

Let's consider **secret injection use case**. Imagine you have an application that requires a secret to connect to an external API. Due to compliance rules, you can’t hardcode this secret into the app or store it in Kubernetes secrets. Instead, you can use an init container to retrieve the secret from a secret management tool like Vault or AWS Secrets Manager and place it in a specific location within the pod, where the main application container can then access it.

![](../../img/init_containers_secret_injection.png)

This way when the application pod starts, it will have access to the secret to connect to the API.

In short, init containers ensure your applications are always properly configured and initialized before they are started.

## How Init Containers Work?

* The **kubelet** runs init containers **sequentially**, following the order they are listed in the Pod spec, making sure each one completes before starting the next - so only one init container runs at a time.
* Init containers always run **before** the main application containers start.
* If the Pod is **restarted**, all init containers will execute again.
* In the Pod’s **lifecycle**, init containers run to completion during the **pending phase**.
* Although init containers use the same container spec format, they **do not support** `lifecycle`, `livenessProbe`, `readinessProbe`, or `startupProbe` fields (except when using the native sidecar alpha feature).

![](../../img/init_containers_workings.gif)

## Specification of Init Containers

Init containers are defined in the [`pod.spec.initContainers`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/?_gl=1*s79r4m*_gcl_au*MTAyNzIwODM1MS4xNzQ2Nzk4MDA4*_ga*MTExOTUwMTk0Ny4xNzQ2Nzk4MDA4*_ga_4RQQZ3WGE9*czE3NDY3OTgwMDgkbzEkZzEkdDE3NDY3OTgyMjUkajQzJGwwJGgxNjgwNjk1MzIx#containers) field of a Pod’s manifest. This is similar to a regular [`pod.spec.containers`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/?_gl=1*n1blso*_gcl_au*MTAyNzIwODM1MS4xNzQ2Nzk4MDA4*_ga*MTExOTUwMTk0Ny4xNzQ2Nzk4MDA4*_ga_4RQQZ3WGE9*czE3NDY3OTgwMDgkbzEkZzEkdDE3NDY3OTgyNzUkajYwJGwwJGgxNjgwNjk1MzIx#containers) definition. We can define as many containers under `initContainers` section. [Here](https://github.com/kubernetes/kubernetes/blob/e6c093d87ea4cbb530a7b2ae91e54c0842d8308a/pkg/apis/core/types.go#L2813) is the example of type implementation in Go of Kubernetes project.

## Practice Example

In this example we will create two init containers, where the first container gets it's Pod IP and then writes into the attached volume. The second init container mounts the volume, reads the IP address and writes it into the `index.html` page. Third main container runs `nginx` web server, mounts the volume and serves the `index.html` webpage with the pod IP.

![](../../img/init_containers_example.png)

To create a cluster, use Minikube:
```bash
minikube start
```

To create Pod:
```bash
kubectl apply -f init-container.yaml
```

The `init-container.yaml` create two init containers: `write-ip` and `create-html`. To check the logs of these containers:
```bash
kubectl logs web-server-pod -c write-ip
kubectl logs web-server-pod -c create-html
```

To verify if the Nginx pod is serving the mounted `index.html` web page:
```bash
kubectl port-forward pod/web-server-pod 8080:80
curl localhost:8080
```

## CPU Requests Pitfall

If a pod has multiple init containers, Kubernetes calculates the **effective init resource request/limit** as the **highest value set for any of the init containers** (for each resource type, like CPU or memory).
This means that during the init phase, the pod’s resource footprint is determined by the maximum request/limit among all init containers - not the sum.

Additionally, if an init container has no limit or request set, it can consume up to the maximum defined by the pod’s effective init request/limit for that resource.

> [!CAUTION] 
> Ensure that the sum of resources requested by Init Containers and main containers does not exceed the available resources on cluster nodes. 

## Best Practices Checklist

- **Design init containers for small, focused tasks**  
  Keep them lightweight to minimize startup time and resource use.

- **Use separate init containers for distinct tasks**  
  Break down initialization into multiple containers for easier management and debugging.

- **Plan for init container failures**  
  Implement retries, exponential back-off, and clear, actionable error messages.

- **Understand lifecycle differences**  
  Remember that init containers don’t support lifecycle hooks or probes; they must run to completion on their own.

- **Protect sensitive data**  
  Use Kubernetes Secrets, environment variables, or mounted volumes securely - never hardcode sensitive values.

- **Allocate sufficient resources**  
  Define `resources.requests` and `resources.limits` to avoid scheduling or starvation issues.

- **Minimize dependencies on external services**  
  Ensure external systems needed during initialization are reliably available.

- **Monitor performance and logs**  
  Regularly check metrics, logs, and Kubernetes events to detect bottlenecks or failures.

- **Optimize image size**  
  Use minimal base images (like `alpine` or `distroless`) to reduce pull times and the security surface.

- **Coordinate execution order carefully**  
  Init containers run sequentially; plan the ordering if tasks depend

## References
- [Kubernetes Docs: Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [DevOpsCube Blog: Init Containers](https://devopscube.com/kubernetes-init-containers/)
- [Habr Blog: Init Containers](https://habr.com/ru/companies/oleg-bunin/articles/761662/)
- [Loft Blog: Deep Dive Into Kubernetes Init Containers](https://www.loft.sh/blog/kubernetes-init-containers)