{{/*
Common labels applied to the ACK RepositoryCreationTemplate resource.
*/}}
{{- define "aws-ecr-repositorycreationtemplate.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
