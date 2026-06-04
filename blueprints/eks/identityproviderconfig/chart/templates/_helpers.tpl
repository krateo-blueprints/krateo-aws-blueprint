{{/*
Common labels applied to the ACK IdentityProviderConfig resource.
*/}}
{{- define "aws-eks-identityproviderconfig.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
