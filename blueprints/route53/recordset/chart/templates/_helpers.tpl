{{/*
Common labels applied to the ACK RecordSet resource.
*/}}
{{- define "aws-route53-recordset.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
