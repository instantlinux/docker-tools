{{- define "chartlib.statefulset" -}}
{{- if hasKey .Values "statefulset" }}
{{- if or .Values.statefulset.enabled (not (hasKey .Values "statefulset.enabled")) }}
{{- include "local.podSpec" (dict "pod" .Values.statefulset "kind" "StatefulSet" "Chart" .Chart "Release" .Release "Values" .Values) }}
  serviceName: {{ include "local.fullname" . }}
  {{- if hasKey .Values "volumeClaimTemplates" }}
  volumeClaimTemplates:
    {{- toYaml .Values.volumeClaimTemplates | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
