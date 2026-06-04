{{/*
Common labels applied to the ACK Collection resource.
*/}}
{{- define "aws-opensearchserverless-collection.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
