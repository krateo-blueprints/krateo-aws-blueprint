{{/*
Common labels applied to the ACK Repository resource.
*/}}
{{- define "aws-ecr-repository.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
