{{/*
Common labels applied to the ACK DataQualityJobDefinition resource.
*/}}
{{- define "aws-sagemaker-dataqualityjobdefinition.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
