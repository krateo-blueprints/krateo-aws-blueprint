{{/*
Common labels applied to the ACK ScalableTarget resource.
*/}}
{{- define "aws-applicationautoscaling-scalabletarget.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
