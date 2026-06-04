{{/*
Common labels applied to the ACK VPC resource.
*/}}
{{- define "aws-ec2-vpc.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
