{{- define "liblocal.ingresstotp" -}}
{{- if hasKey .Values "ingressTOTP" -}}
{{- if .Values.ingressTOTP.enabled -}}
{{- $fullName := include "local.fullname" . -}}
{{- $svcPort := .Values.service.port -}}
{{- if and .Values.ingressTOTP.className (not (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion)) }}
  {{- if not (hasKey .Values.ingressTOTP.annotations "kubernetes.io/ingress.class") }}
  {{- $_ := set .Values.ingressTOTP.annotations "kubernetes.io/ingress.class" .Values.ingressTOTP.className}}
  {{- end }}
{{- end }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}-totp
  labels:
    {{- include "local.labels" . | nindent 4 }}
  annotations:
    {{- if .Values.ingressTOTP.annotations }}
    {{- toYaml .Values.ingressTOTP.annotations | nindent 4 }}
    {{- else }}
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/auth-url: http://{{ .Values.authelia.ip }}/api/verify
    nginx.ingress.kubernetes.io/auth-signin: https://{{ .Values.authelia.fqdn }}
    nginx.ingress.kubernetes.io/use-regex: "true"
    {{- end }}
spec:
  ingressClassName: {{ .Values.ingressTOTP.className }}
  {{- if .Values.ingressTOTP.tls }}
  tls:
    {{- range .Values.ingressTOTP.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingressTOTP.hosts }}
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
{{- end }}
{{- end }}
{{- end }}
