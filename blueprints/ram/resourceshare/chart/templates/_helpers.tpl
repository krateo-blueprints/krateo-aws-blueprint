{{/*
Common labels applied to the ACK ResourceShare resource.
*/}}
{{- define "aws-ram-resourceshare.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
