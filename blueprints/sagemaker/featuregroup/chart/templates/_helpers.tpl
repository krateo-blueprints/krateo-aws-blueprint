{{/*
Common labels applied to the ACK FeatureGroup resource.
*/}}
{{- define "aws-sagemaker-featuregroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
