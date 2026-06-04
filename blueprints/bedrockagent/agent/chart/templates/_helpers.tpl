{{/*
Common labels applied to the ACK Agent resource.
*/}}
{{- define "aws-bedrockagent-agent.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
