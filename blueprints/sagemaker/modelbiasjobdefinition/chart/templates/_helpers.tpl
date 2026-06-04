{{/*
Common labels applied to the ACK ModelBiasJobDefinition resource.
*/}}
{{- define "aws-sagemaker-modelbiasjobdefinition.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
