{{/*
Common labels applied to the ACK DataSet resource.
*/}}
{{- define "aws-quicksight-dataset.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
