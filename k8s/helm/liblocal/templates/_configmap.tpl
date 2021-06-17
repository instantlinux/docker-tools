{{- define "liblocal.configmap" -}}
{{- if hasKey .Values "configmap" }}
{{- if or .Values.configmap.enabled (not (hasKey .Values.configmap "enabled")) -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.configmap.name }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
  {{- with .Values.configmap.data }}
data:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
