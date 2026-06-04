{{/*
Common labels applied to the ACK Certificate resource.
*/}}
{{- define "aws-dms-certificate.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
