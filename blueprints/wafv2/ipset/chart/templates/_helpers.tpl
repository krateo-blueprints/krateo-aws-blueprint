{{/*
Common labels applied to the ACK IPSet resource.
*/}}
{{- define "aws-wafv2-ipset.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
