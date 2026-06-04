{{/*
Common labels applied to the ACK AgentRuntimeEndpoint resource.
*/}}
{{- define "aws-bedrockagentcorecontrol-agentruntimeendpoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
