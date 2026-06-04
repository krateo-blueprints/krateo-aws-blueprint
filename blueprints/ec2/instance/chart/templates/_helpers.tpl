{{/*
Common labels applied to the ACK Instance resource.
*/}}
{{- define "aws-ec2-instance.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
