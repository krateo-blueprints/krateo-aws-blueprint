{{/*
Common labels applied to the ACK RestAPI resource.
*/}}
{{- define "aws-apigateway-restapi.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
