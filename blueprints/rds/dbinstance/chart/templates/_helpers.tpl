{{/*
Common labels applied to the ACK DBInstance resource.
*/}}
{{- define "aws-rds-dbinstance.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
