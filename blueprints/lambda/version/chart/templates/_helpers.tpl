{{/*
Common labels applied to the ACK Version resource.
*/}}
{{- define "aws-lambda-version.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
