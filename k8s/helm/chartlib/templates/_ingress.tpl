{{- define "chartlib.ingress" -}}
{{- if hasKey .Values "ingress" -}}
{{- if .Values.ingress.enabled | default true -}}
{{- $fullName := include "local.fullname" . -}}
{{- $svcPort := .Values.ingress.port | default (index .Values.service.ports 0).port -}}
{{- if and .Values.ingress.className (not (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion)) }}
  {{- if not (hasKey .Values.ingress.annotations "kubernetes.io/ingress.class") }}
  {{- $_ := set .Values.ingress.annotations "kubernetes.io/ingress.class" .Values.ingress.className}}
  {{- end }}
{{- end }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
  annotations:
    {{- if hasKey .Values.ingress "annotations" }}
    {{- toYaml .Values.ingress.annotations | nindent 4 }}
    {{- else }}
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    {{- end }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  {{- if hasKey .Values.ingress "tls" }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- else if hasKey .Values "tlsHostname" }}
  tls:
    - hosts:
      - {{ .Values.tlsHostname }}
      secretName: tls-{{ $fullName }}
  {{- end }}
  rules:
    {{- if hasKey .Values.ingress "rules" }}
    {{- with .Values.ingress.rules }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- else }}
    {{- if hasKey .Values.ingress "hosts" }}
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ $fullName }}
                port:
                  number: {{ $svcPort }}
          {{- end }}
    {{- end }}
    {{- else if hasKey .Values "tlsHostname" }}
    - host: {{ .Values.tlsHostname }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $fullName }}
                port:
                  number: {{ $svcPort }}
    {{- end }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
