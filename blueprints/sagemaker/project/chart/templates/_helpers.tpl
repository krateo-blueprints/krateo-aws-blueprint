{{/*
Common labels applied to the ACK Project resource.
*/}}
{{- define "aws-sagemaker-project.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
