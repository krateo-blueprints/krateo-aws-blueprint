{{/*
Common labels applied to the ACK PlatformEndpoint resource.
*/}}
{{- define "aws-sns-platformendpoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
