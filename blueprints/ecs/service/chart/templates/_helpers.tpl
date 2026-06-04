{{/*
Common labels applied to the ACK Service resource.
*/}}
{{- define "aws-ecs-service.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
