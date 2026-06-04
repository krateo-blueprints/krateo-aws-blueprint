{{/*
Common labels applied to the ACK APIMethodResponse resource.
*/}}
{{- define "aws-apigateway-apimethodresponse.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
