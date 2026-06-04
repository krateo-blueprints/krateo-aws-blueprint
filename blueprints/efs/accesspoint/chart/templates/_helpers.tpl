{{/*
Common labels applied to the ACK AccessPoint resource.
*/}}
{{- define "aws-efs-accesspoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
