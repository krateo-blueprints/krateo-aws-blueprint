{{/*
Common labels applied to the ACK LogGroup resource.
*/}}
{{- define "aws-cloudwatchlogs-loggroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
