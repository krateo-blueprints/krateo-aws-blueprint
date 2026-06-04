{{/*
Common labels applied to the ACK Listener resource.
*/}}
{{- define "aws-elbv2-listener.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
