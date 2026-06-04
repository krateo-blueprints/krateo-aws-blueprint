{{/*
Common labels applied to the ACK GatewayTarget resource.
*/}}
{{- define "aws-bedrockagentcorecontrol-gatewaytarget.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
