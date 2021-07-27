{{- define "chartlib.configmap" -}}
{{- if hasKey .Values "configmap" }}
{{- if or .Values.configmap.enabled (not (hasKey .Values.configmap "enabled")) -}}
apiVersion: v1
kind: ConfigMap
metadata:
  {{- if hasKey .Values.configmap "name" }}
  name:  {{ .Values.configmap.name }}
  {{- else }}
  name: {{ include "local.fullname" . }}
  {{- end }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
  {{- with .Values.configmap.data }}
data:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
