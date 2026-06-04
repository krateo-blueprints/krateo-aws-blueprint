{{/*
Common labels applied to the ACK Trail resource.
*/}}
{{- define "aws-cloudtrail-trail.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
