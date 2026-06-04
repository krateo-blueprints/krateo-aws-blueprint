{{/*
Common labels applied to the ACK JobRun resource.
*/}}
{{- define "aws-emrcontainers-jobrun.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
