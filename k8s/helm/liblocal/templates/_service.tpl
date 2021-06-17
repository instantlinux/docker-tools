{{- define "liblocal.service" -}}
{{- if or .Values.service.enabled (not (hasKey .Values.service "enabled")) }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "local.fullname" . }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
spec:
  clusterIP: {{ .Values.service.clusterIP }}
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "local.selectorLabels" . | nindent 4 }}
{{- end }}
{{- end }}
