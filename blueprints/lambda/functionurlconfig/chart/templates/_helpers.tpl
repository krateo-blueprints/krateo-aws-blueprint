{{/*
Common labels applied to the ACK FunctionURLConfig resource.
*/}}
{{- define "aws-lambda-functionurlconfig.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
