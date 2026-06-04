{{/*
Common labels applied to the ACK WebACL resource.
*/}}
{{- define "aws-wafv2-webacl.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
