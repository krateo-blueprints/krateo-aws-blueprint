{{/*
Common labels applied to the ACK ServerlessCache resource.
*/}}
{{- define "aws-elasticache-serverlesscache.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
