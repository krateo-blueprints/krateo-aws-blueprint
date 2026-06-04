{{/*
Common labels applied to the ACK CodeSigningConfig resource.
*/}}
{{- define "aws-lambda-codesigningconfig.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
