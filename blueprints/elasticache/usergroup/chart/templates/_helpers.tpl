{{/*
Common labels applied to the ACK UserGroup resource.
*/}}
{{- define "aws-elasticache-usergroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
