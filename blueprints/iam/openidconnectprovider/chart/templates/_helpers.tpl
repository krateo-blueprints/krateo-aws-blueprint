{{/*
Common labels applied to the ACK OpenIDConnectProvider resource.
*/}}
{{- define "aws-iam-openidconnectprovider.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
