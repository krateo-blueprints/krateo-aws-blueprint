{{/*
Common labels applied to the ACK AutoScalingGroup resource.
*/}}
{{- define "aws-autoscaling-autoscalinggroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
