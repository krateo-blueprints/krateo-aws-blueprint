{{/*
Common labels applied to the ACK LabelingJob resource.
*/}}
{{- define "aws-sagemaker-labelingjob.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
