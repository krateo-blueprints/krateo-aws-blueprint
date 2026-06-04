{{/*
Common labels applied to the ACK VPCPeeringConnection resource.
*/}}
{{- define "aws-ec2-vpcpeeringconnection.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
