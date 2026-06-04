{{/*
Common labels applied to the ACK Pipeline resource.
*/}}
{{- define "aws-sagemaker-pipeline.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
