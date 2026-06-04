{{/*
Common labels applied to the ACK Integration resource.
*/}}
{{- define "aws-apigateway-integration.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
