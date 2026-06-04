{{/*
Common labels applied to the ACK ElasticIPAddress resource.
*/}}
{{- define "aws-ec2-elasticipaddress.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
