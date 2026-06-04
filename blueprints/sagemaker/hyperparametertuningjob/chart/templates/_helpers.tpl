{{/*
Common labels applied to the ACK HyperParameterTuningJob resource.
*/}}
{{- define "aws-sagemaker-hyperparametertuningjob.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
