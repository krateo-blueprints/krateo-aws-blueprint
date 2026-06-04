{{/*
Common labels applied to the ACK Authorizer resource.
*/}}
{{- define "aws-apigateway-authorizer.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
