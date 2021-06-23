{{- define "liblocal.deployment" -}}
{{- if hasKey .Values "deployment" }}
{{- if or .Values.deployment.enabled (not (hasKey .Values "deployment.enabled")) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "local.fullname" . }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  {{- if hasKey .Values "replicaCount" }}
  replicas: {{ .Values.replicaCount }}
  {{- else }}
  replicas: 1
  {{- end }}
  {{- end }}
  {{- if or .Values.strategy (not (hasKey .Values "strategy")) }}
  {{- with .Values.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "local.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "local.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.serviceAccount.enabled }}
      serviceAccountName: {{ include "local.serviceAccountName" . }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          {{- if (hasKey .Values "env") }}
          env:
          {{- range $name, $value := .Values.env }}
          - { name: {{ $name | upper -}}, value: "{{ $value }}" }
          {{ end }}
          {{- end }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- if hasKey .Values "containerPorts" }}
          ports:
          {{- range .Values.containerPorts }}
          - name: http
            containerPort: {{ . -}}
            protocol: TCP
          {{ end }}
          {{- end }}
          {{- if hasKey .Values "livenessProbe" }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if hasKey .Values "readinessProbe" }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if hasKey .Values "volumeMounts" }}
          volumeMounts:
            {{- toYaml .Values.volumeMounts | nindent 12 }}
          {{- end }}
      {{- if hasKey .Values "hostNetwork" }}
      {{- if .Values.hostNetwork }}
      hostNetwork: true
      {{- end }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if hasKey .Values "volumes" }}
      volumes:
        {{- toYaml .Values.volumes | nindent 8 }}
      {{- end }}
{{- end }}
{{- end }}
{{- end }}
