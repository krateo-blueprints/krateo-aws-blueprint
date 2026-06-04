{{/*
Common labels applied to the ACK App resource.
*/}}
{{- define "aws-sagemaker-app.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
