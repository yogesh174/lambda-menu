#!/bin/bash

# Assumption: AWS configured
sudo apt-get update
sudo apt-get install zip --assume-yes
sudo apt-get install jq --assume-yes
sudo apt-get install python3 --assume-yes
sudo apt install nodejs --assume-yes
sudo apt-get install git --assume-yes

# Main options

function CreateLambdaFunction {
    functionName=$1

    echo -e "\t1. From zip file\n"
    echo -e "\t2. From github\n"
    echo -e "\t0. To return to previous menu\n\n"
    echo -e "Enter option: "

    read option
    if [ $option -eq 1 ]
    then
        clear
        CreateLambdaFunctionFromZip $functionName
    elif [ $option -eq 2 ]
    then
        clear
        CreateLambdaFunctionFromGitHub $functionName
    fi   
}

function InvokeLambdaFunction {
    functionName=$1

    # TODO: change the payload to accept a file
    echo -e "Enter the payload: "
    echo "Example payload: { \"name\": \"Bob\" }"
    read payload
    payload=`echo $payload | base64`

    aws lambda invoke --function-name $functionName \
                      --payload $payload \
                        response.json
    
    echo "Output stored in response.json file"
}


function UpdateLambdaFunction {
    functionName=$1

    echo -e "\t1. From zip file\n"
    echo -e "\t2. From github\n"
    echo -e "\t0. To return to previous menu\n\n"
    echo -e "Enter option: "

    read option
    if [ $option -eq 1 ]
    then
        clear
        UpdateLambdaFunctionFromZip $functionName
        UpdateLambdaFunction
    elif [ $option -eq 2 ]
    then
        clear
        UpdateLambdaFunctionFromGitHub $functionName
        UpdateLambdaFunction
    fi
}

function DeleteLambdaFunction {
    functionName=$1

    echo "Deleting Function $functionName ..."

    aws lambda delete-function --function-name $functionName
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is deleted"
    fi
}


function ListLambdaFunctions {
    list=`aws lambda list-functions --output "json" | jq '.Functions | map(.FunctionName)'`

    list=(${list//[\[\],]/})

    for i in ${!list[@]}
    do 
        printf "%s\t%s\n $i: ${list[$i]}"
    done

    max=$((${#list[@]} - 1))
}


# Sub options for creating lambda function

function CreateLambdaFunctionFromZip {
    functionName=$1

    echo "Enter the zip path of the function: "
    echo "Example: Zipfile.zip "
    read zipPath

    echo "Removing Temp folder if any ..."
    if [ -d Temp ]
    then
        rm -rf Temp
    fi

    unzip $zipPath -d Temp
    cd Temp

    GetConfiguration

    cd ..
    rm -rf Temp

    aws lambda create-function --function-name $functionName \
                                --zip-file "fileb://$zipPath" \
                                --handler $handler \
                                --runtime $runtime \
                                --role arn:aws:iam::accountNumber:role/execRoleName \
                                --memory-size $memory \
                                --timeout $timeout
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is created!"
    fi
}

function CreateLambdaFunctionFromGitHub {
    functionName=$1

    echo "Enter github repo name: "
    read githubName
    echo "Enter github repo owner: "
    read githubOwner
    echo "Enter github branch: "
    read githubBranch
    echo "Enter the github personal access token of the user: "
    read githubPAT

    echo "Removing $githubName folder if any ..."
    if [ -d $githubName ]
    then
        rm -rf $githubName
    fi
    
    git clone "https://$githubPAT@github.com/$githubOwner/$githubName.git"
    cd $githubName && git checkout $githubBranch

    GetConfiguration
    

    if [[ $runtime == *"python"* ]]
    then
        if [ -f requirements.txt ]
        then
            pip3 install --target ./package -r requirements.txt
        fi
    elif [[ $runtime == *"node"* ]]
    then
        npm i
    fi

    zip lambda.zip *

    aws lambda create-function --function-name $functionName \
                                --zip-file "fileb://lambda.zip" \
                                --handler $handler \
                                --runtime $runtime \
                                --role arn:aws:iam::accountNumber:role/execRoleName \
                                --memory-size $memory \
                                --timeout $timeout
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is created!"
    fi

    cd ..
    rm -rf $githubName
}

function UpdateLambdaFunctionFromZip {
    functionName=$1

    echo "Enter the zip path of the function: "
    echo "Example: Zipfile.zip "
    read zipPath

    echo "Removing Temp folder if any ..."
    if [ -d Temp ]
    then
        rm -rf Temp
    fi

    unzip $zipPath -d Temp
    cd Temp

    GetConfiguration

    cd ..
    rm -rf Temp

    aws lambda update-function-code --function-name $functionName \
                                    --zip-file "fileb://$zipPath"
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function's code is updated"
    fi

    aws lambda update-function-configuration --function-name  $functionName \
                                             --handler $handler \
                                             --runtime $runtime \
                                             --memory-size $memory \
                                             --timeout $timeout

    if [ $? -eq 0 ]
    then
        echo "The $functionName function's configuration is updated"
    fi
}

function UpdateLambdaFunctionFromGitHub {
    functionName=$1

    echo "Enter github repo name: "
    read githubName
    echo "Enter github repo owner: "
    read githubOwner
    echo "Enter github branch: "
    read githubBranch
    echo "Enter the github personal access token of the user: "
    read githubPAT

    echo "Removing $githubName folder if any ..."
    if [ -d $githubName ]
    then
        rm -rf $githubName
    fi
    
    git clone "https://$githubPAT@github.com/$githubOwner/$githubName.git"
    cd $githubName && git checkout $githubBranch

    GetConfiguration

    if [[ $runtime == *"python"* ]]
    then
        if [ -f requirements.txt ]
        then
            pip3 install --target ./package -r requirements.txt
        fi
    elif [[ $runtime == *"node"* ]]
    then
        npm i
    fi

    zip lambda.zip *

    aws lambda update-function-code --function-name $functionName \
                                    --zip-file "fileb://lambda.zip"
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function's code is updated"
    fi

    aws lambda update-function-configuration --function-name  $functionName \
                                             --handler $handler \
                                             --runtime $runtime \
                                             --memory-size $memory \
                                             --timeout $timeout

    if [ $? -eq 0 ]
    then
        echo "The $functionName function's configuration is updated"
    fi

    cd ..
    rm -rf $githubName
}

# Helper functions

function ChooseLambdaFunction {
    ListLambdaFunctions
    echo -e "\nChoose a lambda function with key (max: $max): "
    read functionKey

    # Assuming a number input
    while [ $functionKey -gt $max ] || [ $functionKey -lt 0 ]
    do
        ListLambdaFunctions
        echo -e "\nChoose a lambda function with key (max: $max): "
        read functionKey
    done

    functionName=`echo ${list[functionKey]} | sed -e 's/^"//' -e 's/"$//'`
}

function GetConfiguration {
    runtime=`cat configure.json | jq '.runtime' | sed -e 's/^"//' -e 's/"$//'`
    handler=`cat configure.json | jq '.handler' | sed -e 's/^"//' -e 's/"$//'`
    memory=`cat configure.json | jq '.memory'`
    timeout=`cat configure.json | jq '.timeout'`
}

# Main menu function

function menu {
	clear
	echo -e "\t\t\tMain Menu\n\n"
	echo -e "\t1. Create a Lambda function\n"
	echo -e "\t2. Invoke a Lambda function\n"
	echo -e "\t3. Update a Lambda function\n"
	echo -e "\t4. Delete a Lambda function\n"
    echo -e "\t5. List all Lambda functions\n"
    echo -e "\t0. To Exit\n\n"
	echo -e "Enter option: "

	read option
	
	if [ $option -eq 1 ]
	then
        clear
        echo "Enter a function name: "
        read functionName
        CreateLambdaFunction $functionName
        menu

	elif [ $option -eq 2 ]
	then
        clear
        ChooseLambdaFunction
        echo "Invoking $functionName ..."
        InvokeLambdaFunction $functionName
        menu

    elif [ $option -eq 3 ]
	then
        clear
        ChooseLambdaFunction
        echo "Updating $functionName ..."
        UpdateLambdaFunction $functionName
        menu

	elif [ $option -eq 4 ]
	then
        clear
        ChooseLambdaFunction
        DeleteLambdaFunction $functionName
        echo -e "\nPress enter to continue ..."
        read temp
        menu
	
    elif [ $option -eq 5 ]
	then
        clear
        ListLambdaFunctions
        echo -e "\nPress enter to continue ..."
        read temp
        menu
	fi
}

menu