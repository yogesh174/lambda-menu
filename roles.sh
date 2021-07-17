
echo -e "Enter Role name: "
read roleName

#command to create the executable role
aws iam create-role --role-name $roleName --assume-role-policy-document file://trust-policy.json

#command to add AWSLambdaBasicExecutionRole into existing role
aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo -e "Enter account number: "
read accountNumber

sed -i "s@execRoleName@$roleName@" menu.sh
sed -i "s@accountNumber@$accountNumber@" menu.sh