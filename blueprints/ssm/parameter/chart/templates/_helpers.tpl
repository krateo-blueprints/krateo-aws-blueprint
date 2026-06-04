{{/*
Common labels applied to the ACK Parameter resource.
*/}}
{{- define "aws-ssm-parameter.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
