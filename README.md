## Instructions

- Run the roles.sh file once before running the menu.sh
- Ensure that the AWS cli has been configured
- If the function has to be created from a zip then the packages must already be installed as directories
- Must have a `configure.json` and the the file containing `handler` in the root directory

## `Configure.json`

Must have a `configure.json` file in the repository with the following necessary parameters:

- runtime
- memory
- timeout
- handler

### Example

- `Node.js` example
```
{
    "runtime": "nodejs12.x",
    "handler": "index.handler",
    "memory": 256,
    "timeout": 60
}
```

- `Python` example
```
{
    "runtime": "python3.7",
    "handler": "lambda.function",
    "memory": 256,
    "timeout": 30
}
```

### Parameters description

- The possible values of the `runtime` in which the code will be executed are:
    ```
        nodejs
        nodejs4.3
        nodejs6.10
        nodejs8.10
        nodejs10.x
        nodejs12.x
        nodejs14.x
        java8
        java8.al2
        java11
        python2.7
        python3.6
        python3.7
        python3.8
        dotnetcore1.0
        dotnetcore2.0
        dotnetcore2.1
        dotnetcore3.1
        nodejs4.3-edge
        go1.x
        ruby2.5
        ruby2.7
        provided
        provided.al2
    ```

- The `handler` specifies the function you want to run. For instance if you want to run the function named as "function" and file named as "file", then the handler would be `file.function`. Note that the signature of handler should have two arguments which are event and context.

- The `memory` parameter is the amount of memory you want to allocate in MB.

- The `timeout` parameter as the name implies is the maximum amount of time you want the function to run.