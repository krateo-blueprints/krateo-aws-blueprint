{{/*
Common labels applied to the ACK Rule resource.
*/}}
{{- define "aws-elbv2-rule.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
