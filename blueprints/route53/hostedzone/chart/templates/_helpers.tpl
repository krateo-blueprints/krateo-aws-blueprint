{{/*
Common labels applied to the ACK HostedZone resource.
*/}}
{{- define "aws-route53-hostedzone.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
