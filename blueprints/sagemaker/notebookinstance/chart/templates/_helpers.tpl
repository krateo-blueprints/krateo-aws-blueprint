{{/*
Common labels applied to the ACK NotebookInstance resource.
*/}}
{{- define "aws-sagemaker-notebookinstance.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
