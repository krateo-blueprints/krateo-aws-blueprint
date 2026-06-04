{{/*
Common labels applied to the ACK ResourceDataSync resource.
*/}}
{{- define "aws-ssm-resourcedatasync.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
