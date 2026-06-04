{{/*
Common labels applied to the ACK ServerlessCacheSnapshot resource.
*/}}
{{- define "aws-elasticache-serverlesscachesnapshot.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
