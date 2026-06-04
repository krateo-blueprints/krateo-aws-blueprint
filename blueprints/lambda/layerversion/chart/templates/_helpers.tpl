{{/*
Common labels applied to the ACK LayerVersion resource.
*/}}
{{- define "aws-lambda-layerversion.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
