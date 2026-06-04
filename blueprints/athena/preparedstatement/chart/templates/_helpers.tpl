{{/*
Common labels applied to the ACK PreparedStatement resource.
*/}}
{{- define "aws-athena-preparedstatement.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
