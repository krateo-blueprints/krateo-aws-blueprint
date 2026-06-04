{{/*
Common labels applied to the ACK CertificateAuthorityActivation resource.
*/}}
{{- define "aws-acmpca-certificateauthorityactivation.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
