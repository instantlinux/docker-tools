{{- define "chartlib.service" -}}
{{- if hasKey .Values "service" }}
{{- if or .Values.service.enabled (not (hasKey .Values.service "enabled")) }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "local.fullname" . }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
spec:
  {{- if hasKey .Values.service "clusterIP" }}
  clusterIP: {{ .Values.service.clusterIP }}
  {{- end }}
  type: {{ .Values.service.type }}
  {{- with .Values.service.ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    {{- include "local.selectorLabels" . | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
