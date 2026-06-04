{{/*
Common labels applied to the ACK RuleGroup resource.
*/}}
{{- define "aws-wafv2-rulegroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
