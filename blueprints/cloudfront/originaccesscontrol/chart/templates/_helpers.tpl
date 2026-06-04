{{/*
Common labels applied to the ACK OriginAccessControl resource.
*/}}
{{- define "aws-cloudfront-originaccesscontrol.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
