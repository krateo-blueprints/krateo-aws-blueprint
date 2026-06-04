{{/*
Common labels applied to the ACK InstanceProfile resource.
*/}}
{{- define "aws-iam-instanceprofile.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
