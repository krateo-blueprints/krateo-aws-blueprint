{{/*
Common labels applied to the ACK ProcessingJob resource.
*/}}
{{- define "aws-sagemaker-processingjob.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
