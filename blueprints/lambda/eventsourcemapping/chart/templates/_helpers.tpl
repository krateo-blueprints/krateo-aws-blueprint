{{/*
Common labels applied to the ACK EventSourceMapping resource.
*/}}
{{- define "aws-lambda-eventsourcemapping.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
