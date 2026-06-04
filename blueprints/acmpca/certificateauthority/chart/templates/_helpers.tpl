{{/*
Common labels applied to the ACK CertificateAuthority resource.
*/}}
{{- define "aws-acmpca-certificateauthority.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
