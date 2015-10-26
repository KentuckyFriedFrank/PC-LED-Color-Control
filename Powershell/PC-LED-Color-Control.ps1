#Change to continue to ahve values printed to console
$VerbosePreference = 'Continue'

$ErrorActionPreference = 'Stop'

Function ConvertRange{
	param(
		$originalStart, 
		$originalEnd, 
		$newStart, 
		$newEnd,
		$value 
	)
	$scale = ($newEnd - $newStart) / ($originalEnd - $originalStart);
	return  ([math]::Round(($newStart + (($value - $originalStart) * $scale))))
}

$global:arrayPosition = 0
$global:previousLedValue = 0
Function Cool-To-Hot {
    param(
        [byte]$currentLedValue
    )
    $pixel = New-Object Byte[] 3
    If($global:arrayPosition -lt $currentLedValue){
       $global:arrayPosition++
    }
    ElseIf($global:arrayPosition -gt $currentLedValue){
       $global:arrayPosition--
    }
    Write-Verbose ('arrayPosition ' + $arrayPosition | Out-String)
    $pixel = $ColorArray[$global:arrayPosition]

    #take one pixel color ( 3 bytes ) and copy it to the rest of the LEDData array ( 3bytes * NumLEDs)
    For($j = 0; $j -lt ($LEDData.count); $j = $j+3 ){
        For($i = 0; $i -lt 3; $i++){
            #Write-Verbose '$LEDData[' ($j + $i) '] = $pixel['$i']'
            $LEDData[$j + $i] = $pixel[$i] 
        }
    }
}

$ColorArray = @(0)*256
Function Create-ColorObject {
    For($i = 0; $i -lt 256; $i++){
        [byte]$RedVal = $i
        [byte]$BlueVal = [math]::Abs($i - 255)
        [byte]$GreenVal = 0
        $ColorArray[$i] =  (0, $RedVal, $BlueVal)
    }
}
Create-ColorObject 



#Min and Max LED values
[Int32]$MinLED = 0
[Int32]$MaxLED = 255
$NumLEDs = 40
[byte]$Brightness = 255


#Serial communocation setup
$LEDData = New-Object Byte[] ($NumLEDs*3)
$previousLEDData = New-Object Byte[] ($NumLEDs*3)
$pixel = New-Object Byte[] 3
$COMs = [System.IO.Ports.SerialPort]::getportnames()
Write-Verbose  ($COMs | Out-String)
if(!($port.IsOpen)){
    $COM = 'COM5'
    $Port = New-Object System.IO.Ports.SerialPort $COM,9600,None,8,one
    $port.open()
}

[Int32]$MinSensorVal = (Get-WmiObject -Namespace 'root/OpenHardwareMonitor' -Class sensor | Where-Object { ($_.Name -like "GPU Fan") } | Select -First 1).Min
[Int32]$MaxSensorVal = (Get-WmiObject -Namespace 'root/OpenHardwareMonitor' -Class sensor | Where-Object { ($_.Name -like "GPU Fan") } | Select -First 1).Max
if($MinSensorVal -eq $MaxSensorVal){
    $MaxSensorVal++
}

$foo = 0
$test = $false

do{
	#$Sensor = Get-WmiObject -Namespace 'root/OpenHardwareMonitor' -Class sensor | Where-Object { ($_.Name -like "*GPU*") -and ($_.SensorType -like 'Temperature') }  | Select -First 1
	
    #get fan info
    $Sensor = Get-WmiObject -Namespace 'root/OpenHardwareMonitor' -Class sensor | Where-Object { ($_.Name -like "GPU Fan") } | Select -First 1

    if($Sensor){
        Write-Verbose ( $Sensor | Select Value,Min,Max | FT | Out-String )
	    [Int32]$CurrentVal = $Sensor.Value
        If($Sensor.Max -Gt $MaxSensorVal){
            $MaxSensorVal = $Sensor.Max
        }
        If($Sensor.Min -lt $MinSensorVal){
            $MinSensorVal = $Sensor.Min
        }

		[byte]$LEDvalue = ConvertRange -originalStart $MinSensorVal -originalEnd $MaxSensorVal -newStart $MinLED -newEnd $MaxLED -value $CurrentVal
        Write-Verbose ('LEDvalue '+ $LEDvalue | Out-String)       
        Cool-To-Hot $LEDvalue 

        <#
        If(!(Compare-Object $LEDData $previousLEDData)){
            
        }
        Else{
        #>
            $previousLEDData  = $LEDData.Clone() 
		    # Send LED value
		    If($Port.IsOpen){ 
			    Write-Verbose ('sending byte ' + $byte)
                $port.Write('*')
			    $port.Write( $LEDData, 0,  $LEDData.Count)
		    }
            Else{
			    Write-Verbose 'COM Port is no longer open.'
		    }
       # }
	}
	Else{
		Write-Verbose 'Unable to retrieve sensor informationl. Is HardwareMonitor running?'
	}
	Sleep -Milliseconds 10

}
While($true)
