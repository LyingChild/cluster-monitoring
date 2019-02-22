local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';

local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') +
           (import 'image_sources_versions.jsonnet') +
  {
  _config+:: {
    namespace: 'monitoring',
  },

  metallb+:: {
    serviceMonitor:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'metallb',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'metallb-controller',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          selector: {
            matchLabels: {
              'k8s-app': 'metallb-controller',
            },
          },
          endpoints: [
            {
              port: 'http',
              scheme: 'http',
              interval: '30s',
            },
          ],
          namespaceSelector: {
              matchNames: [
                'metallb-system',
              ]
            },

        },
      },

    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local metallbPort = servicePort.newNamed('http', 7472, 7472);

      service.new('metallb-controller', {"app": "metallb", "component": "controller"}, metallbPort) +
      service.mixin.metadata.withNamespace('metallb-system') +
      service.mixin.metadata.withLabels({ 'k8s-app': 'metallb-controller' }) +
      service.mixin.spec.withClusterIp('None'),
  },
};

{ ['metallb-' + name]: kp.metallb[name] for name in std.objectFields(kp.metallb) }