# GNIS-Deployment

- **License**: [Apache 2](http://opensource.org/licenses/Apache-2.0)
- [**Submit Bugs and feature requests**](https://github.com/DataONEorg/gnis-deployment/issues)


Helm chart for deploying the gnis-ld project to Kubernetes.

## Architecture

The deployment takes place as a single deployment with a single pod, which in turn contains a container for each stack component. For example, there's a container for the triplifier, for the webapp, etc. The webapp is the only pod that communicates with the outside world and has it's port mapping specified in the gnis-service.yaml file. The other containers (triplifier, GraphDB) communicate though `localhost` instead of services _because they're in the same pod_.

Because all of the containers exist in the same pod, each container can be accessed from another with `localhost:port`. For example, the webapp gnis-ld can communicate with GraphDB via `localhost:7200`. This is opposed to a service based communication model, which would be appropriate if the containers were in separate pods. This is exploited in the reverse proxy logic in the webapp, where GraphDB is contacted from the webapp.

## Deployment

To install the chart (creating the `gnis` namespace if it doesn't exist),

`helm install gnis helm/ -n gnis --create-namespace`

By default the chart creates the static CephFS PersistentVolume and its PersistentVolumeClaim. Creating a PV is a cluster-admin operation; if you are installing as a non-admin user, have an administrator pre-create the PV/PVC and point the chart at the existing claim instead:

`helm install gnis helm/ -n gnis --set persistence.pv.enabled=false --set persistence.existingClaim=cephfs-gnis-pvc`

To check for a valid PVC before installing, run `kubectl get pvc -n gnis` — a bound claim shows State 'Bound'.

Common configuration lives in [helm/values.yaml](helm/values.yaml): the public hostname (`host`), container images, env vars, ingress/TLS settings, and the quarterly graph-update CronJob (`updateCronJob.enabled`, off by default).

To apply configuration changes,

`helm upgrade gnis helm/ -n gnis`

To perform a rolling update (this also re-runs the triplifier's graph update),

 `kubectl rollout restart deployment gnis`

#### Debugging
There are a few commands that will come in handy while debugging the stack.

Get the logs of a gnis container,

`kubectl logs <pod> <container-name>`

If a container has restarted, the previous logs can be obtained with the `--previous` flag.

`kubectl logs --previous <pod> <container-name>`

To get a shell in a running pod, run

`kubectl exec -i -t <pod> bash`

To get a shell in a container, inside a pod, run

`kubectl exec -n gnis -it pod/<pod-name> -c <container-name> -- /bin/sh`

For debugging networking, the following are useful

`kubectl describe virtualserver -n nginx-ingress`

`kubectl describe virtualserverroute -n gnis`

`kubectl describe service/gnis -n gnis`

An alternative to the rolling update is uninstalling and reinstalling the release. This doesn't delete the PV & PVC data (the PV uses a `Retain` reclaim policy)

```
helm uninstall gnis -n gnis
helm install gnis helm/ -n gnis
```

##### Debugging GraphDB
In the case that the GraphDB instance needs debugging and access to the GraphDB Workbench is needed, re-configure the gnis service to direct traffic to GraphDB (`helm upgrade gnis helm/ -n gnis --set service.targetPort=7200`). This will allow you to access the workbench; be sure to change the port back to the gnis-ld port before re-deploying.

[![dataone_footer](https://www.dataone.org/sites/all/images/DataONE_LOGO.jpg)](https://www.dataone.org)