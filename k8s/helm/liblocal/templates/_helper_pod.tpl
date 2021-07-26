{{/*
Common definitions for pods created by deployment or statefulset
*/}}
{{- define "local.podSpec" }}
apiVersion: apps/v1
kind: {{ .kind }}
metadata:
  name: {{ include "local.fullname" . }}
  labels:
    {{- include "local.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  {{- if hasKey .pod "replicas" }}
  replicas: {{ .pod.replicas }}
  {{- else }}
  replicas: 1
  {{- end }}
  {{- end }}
  {{- if or .pod.strategy (not (hasKey .pod "strategy")) }}
  {{- with .pod.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "local.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .pod.annotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "local.selectorLabels" . | nindent 8 }}
    spec:
      {{- if hasKey .Values "imagePullSecrets" }}
      imagePullSecrets:
        {{- toYaml .Values.imagePullSecrets | nindent 8 }}
      {{- end }}
      {{- if .Values.serviceAccount.enabled }}
      serviceAccountName: {{ include "local.serviceAccountName" . }}
      {{- end }}
      {{- if (hasKey .pod "podSecurityContext") }}
      securityContext:
        {{- toYaml .pod.podSecurityContext | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          {{- if hasKey .pod "command" }}
          command:
            {{- toYaml .pod.command | nindent 12 }}
          {{- end }}
          {{- if hasKey .pod "args" }}
          args:
            {{- toYaml .pod.args | nindent 12 }}
          {{- end }}
          {{- if or (hasKey .pod "env") (hasKey .pod "xenv") }}
          env:
          {{- end }}
          {{- if (hasKey .pod "env") }}
          {{- range $name, $value := .pod.env }}
          - { name: {{ $name | upper -}}, value: "{{ $value }}" }
          {{ end }}
          {{- end }}
          {{- if (hasKey .pod "xenv") }}
          {{- toYaml .pod.xenv | nindent 10 }}
          {{- end }}
          {{- if (hasKey .pod "securityContext") }}
          securityContext:
            {{- toYaml .pod.securityContext | nindent 12 }}
          {{- end }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- if hasKey .pod "containerPorts" }}
          ports:
            {{- toYaml .pod.containerPorts | nindent 12 }}
          {{- end }}
          {{- if hasKey .Values "livenessProbe" }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if hasKey .Values "readinessProbe" }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if hasKey .pod "resources" }}
          resources:
            {{- toYaml .pod.resources | nindent 12 }}
          {{- end }}
          {{- if hasKey .Values "volumeMounts" }}
          volumeMounts:
            {{- toYaml .Values.volumeMounts | nindent 12 }}
          {{- end }}
      {{- if hasKey .pod "dnsConfig" }}
      dnsConfig:
        {{- toYaml .pod.dnsConfig | nindent 8 }}
      {{- end }}
      {{- if hasKey .pod "hostNetwork" }}
      {{- if .pod.hostNetwork }}
      hostNetwork: true
      {{- end }}
      {{- end }}
      {{- if hasKey .pod "hostAliases" }}
      hostAliases:
        {{- toYaml .pod.hostAliases | nindent 8 }}
      {{- end }}
      {{- if hasKey .pod "hostname" }}
      hostname: {{ .pod.hostname }}
      {{- end }}
      {{- if hasKey .pod "nodeSelector" }}
      nodeSelector:
        {{- toYaml .pod.nodeSelector | nindent 8 }}
      {{- end }}
      {{- if hasKey .pod "affinity" }}
      affinity:
        {{- toYaml .pod.affinity | nindent 8 }}
      {{- end }}
      {{- if hasKey .pod "terminationGracePeriodSeconds" }}
      terminationGracePeriodSeconds: {{ .pod.terminationGracePeriodSeconds }}
      {{- end }}
      {{- if hasKey .pod "tolerations" }}
      tolerations:
        {{- toYaml .pod.tolerations | nindent 8 }}
      {{- end }}
      {{- if hasKey .Values "volumes" }}
      volumes:
        {{- toYaml .Values.volumes | nindent 8 }}
      {{- end }}
{{- end }}
