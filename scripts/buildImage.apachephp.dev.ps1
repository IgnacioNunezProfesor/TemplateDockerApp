Get-Content ./env/apache+php.dev.env | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$") {
        $name=$matches[1]; $value=$matches[2]
        [System.Environment]::SetEnvironmentVariable($name,$value)
    }
}
docker build `
    --build-arg APACHE_DOCUMENT_ROOT=$env:APACHE_DOCUMENT_ROOT `
    --build-arg APP_PORT=$env:APP_PORT `
    --build-arg php_cgi_path=$env:php_cgi_path `
    -t apachephpdevimage:latest -f .\docker\apache+php\apache-php.dev.dockerfile .