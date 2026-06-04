{{/*
Common labels applied to the ACK TrainingJob resource.
*/}}
{{- define "aws-sagemaker-trainingjob.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
