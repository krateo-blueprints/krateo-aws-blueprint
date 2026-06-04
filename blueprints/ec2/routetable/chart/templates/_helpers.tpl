{{/*
Common labels applied to the ACK RouteTable resource.
*/}}
{{- define "aws-ec2-routetable.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
