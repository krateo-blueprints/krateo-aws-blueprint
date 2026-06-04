{{/*
Common labels applied to the ACK NotebookInstanceLifecycleConfig resource.
*/}}
{{- define "aws-sagemaker-notebookinstancelifecycleconfig.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
