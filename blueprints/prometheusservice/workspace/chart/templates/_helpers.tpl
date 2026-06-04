{{/*
Common labels applied to the ACK Workspace resource.
*/}}
{{- define "aws-prometheusservice-workspace.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
