{{/*
Common labels applied to the ACK Subnet resource.
*/}}
{{- define "aws-ec2-subnet.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
