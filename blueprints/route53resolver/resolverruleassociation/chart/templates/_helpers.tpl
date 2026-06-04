{{/*
Common labels applied to the ACK ResolverRuleAssociation resource.
*/}}
{{- define "aws-route53resolver-resolverruleassociation.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
