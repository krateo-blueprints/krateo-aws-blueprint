{{/*
Common labels applied to the ACK Account resource.
*/}}
{{- define "aws-organizations-account.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
