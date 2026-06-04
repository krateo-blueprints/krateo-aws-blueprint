{{/*
Common labels applied to the ACK AccessPoint resource.
*/}}
{{- define "aws-s3files-accesspoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
