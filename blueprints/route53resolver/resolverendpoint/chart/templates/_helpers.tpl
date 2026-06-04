{{/*
Common labels applied to the ACK ResolverEndpoint resource.
*/}}
{{- define "aws-route53resolver-resolverendpoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
