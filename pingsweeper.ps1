$os = Get-WmiObject -Class Win32_OperatingSystem
if ($os.ProductType -ne 3) {
    Write-Error "Este script só pode correr em Windows Server!"
    exit 1
}

# vai buscar o ip da nic Eth0 e calcula o prefixo 
$ip = Get-NetIPAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4
$ipAddress = $ip.IPAddress
$prefixLength = $ip.PrefixLength


# converter o ip para inteiro??
$ipBytes = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()
[Array]::Reverse($ipBytes)
$ipInt = [System.BitConverter]::ToUInt32($ipBytes, 0)


# calculo da mascara
$netmask = ([UInt32]::MaxValue) -shl (32 - $prefixLength) -band [UInt32]::MaxValue

# first = (addr & netmask)
$firstInt = $ipInt -band $netmask
# last = (addr & netmask) + !netmask
$lastInt = ($ipInt -band $netmask) + (-bnot $netmask -band [UInt32]::MaxValue)


# array de ips e limites
$activeIPs = @()
$startRange = $firstInt + 100
$endRange = $firstInt + 102

Write-Host "A testar IPs de .100 a .102" -ForegroundColor Cyan

for ($i = $startRange; $i -le $endRange; $i++) {
    $bytes = [System.BitConverter]::GetBytes($i)
    [Array]::Reverse($bytes)
    $currentIP = [System.Net.IPAddress]::new($bytes).ToString()
    
    Write-Host "Testando: $currentIP" -ForegroundColor Gray
    
    # ignora o prop
    if ($currentIP -eq $ipAddress) { 
        Write-Host "  (este servidor - ignorado)" -ForegroundColor Yellow
        continue 
    }
    
    $pingResult = Test-NetConnection -ComputerName $currentIP -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($pingResult) {
        Write-Host "Responde a ICMP" -ForegroundColor Green
        $activeIPs += $currentIP
    }
    else {
        Write-Host "Sem resposta ICMP" -ForegroundColor Red
        try { #tenta ver se ta on mas com firewall
            $wmi = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $currentIP -ErrorAction Stop
            if ($wmi) {
                Write-Host "ativo mas tem firewall"
                $activeIPs += $currentIP
            }
        }
        catch {
            Write-Host "        nao consigo ver se esta on com firewall" -ForegroundColor Red
        }
    }
}

Write-Host "`nIPs ativos encontrados:" -ForegroundColor Green
foreach ($foundIP in $activeIPs) {
    Write-Host $foundIP
}