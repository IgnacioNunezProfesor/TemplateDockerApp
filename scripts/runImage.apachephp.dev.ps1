param(
    [Parameter(Position=0)]
    [string]$Name = 'MyPHP',

    [Parameter(Position=1)]
    [int]$Port = 8080,

    [Parameter(Position=2)]
    [string]$Image = 'apachephpdevimage:latest'
)

$existing = docker ps -a --filter "name=$Name" --format "{{.Names}}"

if ($existing -eq $Name) {
    Write-Output "Eliminando contenedor existente: $Name"
    docker rm -f $Name
}

docker run --env-file ./env/apache+php.dev.env --name $Name -v ${PWD}/src:/var/www/html apachephpdevimage:latest