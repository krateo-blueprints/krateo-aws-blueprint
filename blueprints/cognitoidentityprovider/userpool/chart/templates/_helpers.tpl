{{/*
Common labels applied to the ACK UserPool resource.
*/}}
{{- define "aws-cognitoidentityprovider-userpool.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
