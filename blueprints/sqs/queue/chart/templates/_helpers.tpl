{{/*
Common labels applied to the ACK Queue resource.
*/}}
{{- define "aws-sqs-queue.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
