{{/*
Common labels applied to the ACK Domain resource.
*/}}
{{- define "aws-codeartifact-domain.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
