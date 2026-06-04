{{/*
Common labels applied to the ACK ResolverRule resource.
*/}}
{{- define "aws-route53resolver-resolverrule.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
