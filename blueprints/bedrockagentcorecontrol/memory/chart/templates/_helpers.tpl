{{/*
Common labels applied to the ACK Memory resource.
*/}}
{{- define "aws-bedrockagentcorecontrol-memory.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
