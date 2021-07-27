## Chart Repo Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add <alias> https://instantlinux.github.io/docker-tools

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> <alias>/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>

See the [Makefile](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile) for the full set of tools for k8s. To use it, clone the repo, add local overrides as `admin/services/values/<chart-name>.yaml` and invoke `make <chart-name>`.
