{{/*
Common labels applied to the ACK Nodegroup resource.
*/}}
{{- define "aws-eks-nodegroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
