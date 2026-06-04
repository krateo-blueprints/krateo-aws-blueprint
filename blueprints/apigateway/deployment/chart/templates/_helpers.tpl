{{/*
Common labels applied to the ACK Deployment resource.
*/}}
{{- define "aws-apigateway-deployment.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
