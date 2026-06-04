{{/*
Common labels applied to the ACK EventDataStore resource.
*/}}
{{- define "aws-cloudtrail-eventdatastore.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
