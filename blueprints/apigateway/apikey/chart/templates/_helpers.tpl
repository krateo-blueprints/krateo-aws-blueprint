{{/*
Common labels applied to the ACK APIKey resource.
*/}}
{{- define "aws-apigateway-apikey.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
