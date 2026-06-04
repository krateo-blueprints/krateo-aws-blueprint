{{/*
Common labels applied to the ACK APIIntegrationResponse resource.
*/}}
{{- define "aws-apigateway-apiintegrationresponse.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
