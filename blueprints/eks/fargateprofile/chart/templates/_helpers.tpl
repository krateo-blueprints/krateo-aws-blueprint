{{/*
Common labels applied to the ACK FargateProfile resource.
*/}}
{{- define "aws-eks-fargateprofile.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
