{{/*
Common labels applied to the ACK ParameterGroup resource.
*/}}
{{- define "aws-memorydb-parametergroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
