{{- define "chartlib.daemonset" -}}
{{- if hasKey .Values "daemonset" }}
{{- if or .Values.daemonset.enabled (not (hasKey .Values "daemonset.enabled")) }}
{{- include "local.podSpec" (dict "pod" .Values.daemonset "kind" "DaemonSet" "Chart" .Chart "Release" .Release "Values" .Values) }}
{{- end }}
{{- end }}
{{- end }}
