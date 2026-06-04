{{/*
Common labels applied to the ACK FirewallPolicy resource.
*/}}
{{- define "aws-networkfirewall-firewallpolicy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
