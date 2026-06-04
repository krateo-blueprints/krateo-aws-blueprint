{{/*
Common labels applied to the ACK SecurityPolicy resource.
*/}}
{{- define "aws-opensearchserverless-securitypolicy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
