{{/*
Common labels applied to the ACK ConfigurationSet resource.
*/}}
{{- define "aws-ses-configurationset.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
