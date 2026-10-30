# GNIS-Deployment

- **License**: [Apache 2](http://opensource.org/licenses/Apache-2.0)
- [**Submit Bugs and feature requests**](https://github.com/DataONEorg/gnis-deployment/issues)


Helm chart for deploying the gnis-ld project to Kubernetes.

## Architecture

The stack is a single Deployment with one pod, and the pod has a container for each stack component. For example there is one container for the triplifier and one for the webapp, all in the same pod. Because all of the containers are in the same pod, each container is reachable from another at `localhost:port`. For example, the webapp reaches GraphDB at `localhost:7200`. A service-based communication model would be appropriate if the containers were in separate pods.

## Deployment

To install the chart while creating the `gnis` namespace if it doesn't exist run,

`helm install gnis helm/ -n gnis --create-namespace --set etl.gdbPassword=<password> --wait --timeout 3h`

The ETL is run once by a post-install Job, and `helm install` returns when that run has finished. In short, the pod won't be ready until the triples have been generated and loaded into GraphDB for the first time. In that run, the legacy releases listed in `etl.env.LEGACY_RELEASES` (the 2021-08-25 legacy dump by default) are built, then the current release is built and loaded into GraphDB. After that the ETL is run by the CronJob on the `etl.schedule`. In each scheduled run, a legacy release whose release file is missing from the archives volume is built before the current release. Set `etl.loadOnInstall=false` to install without the post-install Job.

The images are published to `ghcr.io/dataoneorg/gnis-graphdb` (ETL and GraphDB) and `ghcr.io/dataoneorg/gnis-ld` (website) by the `docker-publish` workflow of each repository. Each image is tagged `latest` from the main branch and `sha-<commit>` for every commit. Set `image.tag` and `webapp.image.tag` to a `sha-` tag to deploy a specific commit.

Two volumes are mounted into the pods. The main volume (`persistence`) contains the GraphDB home directory and the ETL's working files, all of which can be rebuilt by re-running the ETL. The archives volume (`persistence.archives`) contains the published release files, which cannot be rebuilt, so it must be a `ReadWriteMany` volume whose reclaim policy is `Retain`. Set one of `persistence.archives.existingClaim`, `persistence.archives.storageClassName` or `persistence.archives.pv.enabled` (with its own `rootPath`). Without one of them, Helm fails to render the chart.

By default a static CephFS PersistentVolume is created for the main volume. Its `persistence.pv.csi` values identify one cluster's filesystem and one subvolume. Set a different `rootPath` for a second install of the chart on the same cluster (for example a staging instance). Otherwise the single GraphDB home directory gets shared by both installs.

`helm install gnis helm/ -n gnis --set persistence.pv.enabled=false --set persistence.existingClaim=cephfs-gnis-pvc --set persistence.archives.existingClaim=cephfs-gnis-archives-pvc`

To check for valid claims before installing, run `kubectl get pvc -n gnis`. Bound claims have State values of 'Bound'.

Common configuration is in [helm/values.yaml](helm/values.yaml). The public hostname (`host`), container images, env vars, ingress/TLS settings, and the schedule of the quarterly ETL CronJob (`etl.schedule`) are set there.

To apply configuration changes,

`helm upgrade gnis helm/ -n gnis`

To perform a rolling update (the triplifier's graph update is also re-run),

 `kubectl rollout restart deployment gnis`

#### Debugging
The following commands are useful when debugging the stack.

Get the logs of a gnis container,

`kubectl logs <pod> <container-name>`

If a container has restarted, the previous logs can be obtained with the `--previous` flag.

`kubectl logs --previous <pod> <container-name>`

For debugging networking, the following are useful

`kubectl describe virtualserver -n nginx-ingress`

`kubectl describe virtualserverroute -n gnis`

`kubectl describe service/gnis -n gnis`

An alternative to the rolling update is uninstalling and reinstalling the chart. Both PersistentVolumeClaims and the chart's PersistentVolumes are annotated `helm.sh/resource-policy: keep`, so `helm uninstall` leaves them and their data in place and they are bound again on reinstall. A claim created outside the chart is never deleted or modified by Helm.

```
helm uninstall gnis -n gnis
helm install gnis helm/ -n gnis
```

##### Debugging GraphDB
To reach the GraphDB Workbench, re-configure the gnis service to direct traffic to GraphDB (`helm upgrade gnis helm/ -n gnis --set service.targetPort=7200`). Change the port back to the gnis-ld port before re-deploying.

[![dataone_footer](https://www.dataone.org/sites/all/images/DataONE_LOGO.jpg)](https://www.dataone.org)
