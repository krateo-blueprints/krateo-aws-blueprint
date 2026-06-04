{{/*
Common labels applied to the ACK ServiceLinkedRole resource.
*/}}
{{- define "aws-iam-servicelinkedrole.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
