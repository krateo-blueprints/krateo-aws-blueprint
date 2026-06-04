{{/*
Common labels applied to the ACK PackageGroup resource.
*/}}
{{- define "aws-codeartifact-packagegroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
