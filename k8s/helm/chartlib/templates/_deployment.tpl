{{- define "chartlib.deployment" -}}
{{- if hasKey .Values "deployment" }}
{{- if or .Values.deployment.enabled (not (hasKey .Values "deployment.enabled")) }}
{{- include "local.podSpec" (dict "pod" .Values.deployment "kind" "Deployment" "Chart" .Chart "Release" .Release "Values" .Values) }}
{{- end }}
{{- end }}
{{- end }}
