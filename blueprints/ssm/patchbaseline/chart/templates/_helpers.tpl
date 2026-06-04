{{/*
Common labels applied to the ACK PatchBaseline resource.
*/}}
{{- define "aws-ssm-patchbaseline.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
