{{/*
Common labels applied to the ACK GlobalTable resource.
*/}}
{{- define "aws-dynamodb-globaltable.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
