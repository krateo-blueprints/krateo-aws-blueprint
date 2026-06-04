{{/*
Common labels applied to the ACK ModelPackage resource.
*/}}
{{- define "aws-sagemaker-modelpackage.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
