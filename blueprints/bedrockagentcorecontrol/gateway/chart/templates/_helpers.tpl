{{/*
Common labels applied to the ACK Gateway resource.
*/}}
{{- define "aws-bedrockagentcorecontrol-gateway.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
