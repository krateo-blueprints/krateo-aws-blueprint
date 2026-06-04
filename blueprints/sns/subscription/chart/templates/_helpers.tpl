{{/*
Common labels applied to the ACK Subscription resource.
*/}}
{{- define "aws-sns-subscription.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
