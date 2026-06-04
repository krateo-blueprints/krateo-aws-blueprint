{{/*
Common labels applied to the ACK Route resource.
*/}}
{{- define "aws-apigatewayv2-route.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
