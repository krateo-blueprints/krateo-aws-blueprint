{{/*
Common labels applied to the ACK TransformJob resource.
*/}}
{{- define "aws-sagemaker-transformjob.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
