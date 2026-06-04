{{/*
Common labels applied to the ACK TargetGroup resource.
*/}}
{{- define "aws-elbv2-targetgroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
