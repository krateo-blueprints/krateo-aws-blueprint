{{/*
Common labels applied to the ACK OriginRequestPolicy resource.
*/}}
{{- define "aws-cloudfront-originrequestpolicy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
