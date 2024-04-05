nano aws-credentials.txt


#save the followint to the file with name aws-credentials.txt.  Replace the aws_access_key_id & aws_secret_access_key  values
[default]
aws_access_key_id = ***********
aws_secret_access_key = ***************************

kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./aws-credentials.txt