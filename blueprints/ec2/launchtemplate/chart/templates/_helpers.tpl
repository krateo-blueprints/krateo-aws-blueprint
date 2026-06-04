{{/*
Common labels applied to the ACK LaunchTemplate resource.
*/}}
{{- define "aws-ec2-launchtemplate.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
