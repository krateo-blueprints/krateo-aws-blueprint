{{/*
Common labels applied to the ACK TransitGateway resource.
*/}}
{{- define "aws-ec2-transitgateway.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
