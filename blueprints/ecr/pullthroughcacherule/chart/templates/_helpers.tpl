{{/*
Common labels applied to the ACK PullThroughCacheRule resource.
*/}}
{{- define "aws-ecr-pullthroughcacherule.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
