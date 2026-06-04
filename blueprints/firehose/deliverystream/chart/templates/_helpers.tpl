{{/*
Common labels applied to the ACK DeliveryStream resource.
*/}}
{{- define "aws-firehose-deliverystream.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
