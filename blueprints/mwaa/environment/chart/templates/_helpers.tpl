{{/*
Common labels applied to the ACK Environment resource.
*/}}
{{- define "aws-mwaa-environment.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
