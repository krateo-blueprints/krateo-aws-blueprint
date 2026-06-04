{{/*
Common labels applied to the ACK Application resource.
*/}}
{{- define "aws-emrserverless-application.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
