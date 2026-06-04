{{/*
Common labels applied to the ACK ElasticsearchDomain resource.
*/}}
{{- define "aws-elasticsearchservice-elasticsearchdomain.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
