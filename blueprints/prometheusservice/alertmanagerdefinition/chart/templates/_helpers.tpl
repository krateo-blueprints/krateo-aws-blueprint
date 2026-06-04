{{/*
Common labels applied to the ACK AlertManagerDefinition resource.
*/}}
{{- define "aws-prometheusservice-alertmanagerdefinition.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
