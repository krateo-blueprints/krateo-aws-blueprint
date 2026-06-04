{{/*
Common labels applied to the ACK VPCLink resource.
*/}}
{{- define "aws-apigateway-vpclink.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
