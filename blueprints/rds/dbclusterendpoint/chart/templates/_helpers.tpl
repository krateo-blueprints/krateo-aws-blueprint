{{/*
Common labels applied to the ACK DBClusterEndpoint resource.
*/}}
{{- define "aws-rds-dbclusterendpoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
