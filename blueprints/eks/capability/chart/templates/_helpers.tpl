{{/*
Common labels applied to the ACK Capability resource.
*/}}
{{- define "aws-eks-capability.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
