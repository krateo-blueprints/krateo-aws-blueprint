{{/*
Common labels applied to the ACK InferenceComponent resource.
*/}}
{{- define "aws-sagemaker-inferencecomponent.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
