{{/*
Common labels applied to the ACK LoadBalancer resource.
*/}}
{{- define "aws-elbv2-loadbalancer.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
