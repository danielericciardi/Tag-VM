######################################
##  versione:   1.0                 ##
##  autore  :   Daniele Ricciardi   ##
##	data	:	15/04/2021			##
######################################
#
# Lo script permette di taggare multiple VM.
#

#connect to vCenter
Connect-viserver <vcenter FQDN> -user <vCenter User> -pass <vCenter password>

#load file with data
$CMDBInfo = Import-CSV "path.to\file.csv"
 
# Get the header names to use as tag category names
$TagCatNames = $cmdbinfo | Get-Member | Where {$_.MemberType -eq "NoteProperty"} | Select -Expand Name

# Create the Tag Category if it doesnt exist
Foreach ($Name in ($TagCatNames | Where {$_ -ne "Name"})) {
  Try {
   $tCat = Get-TagCategory $Name -ErrorAction Stop
  }

  Catch {
   Write-Host "Creating Tag Category $Name"
   $tCat = New-TagCategory -Name $Name -Description "$Name from CMDB"
  }

  # Create Tags under the Tag Categories
  $UniqueTags = $cmdbinfo | Select -expand $Name | Get-Unique

  Foreach ($Tag in $UniqueTags) {
   Try {
   $tTag = Get-Tag $Tag -Category $tCat -ErrorAction Stop
   }

   Catch {
   Write-Host "..Creating Tag under $Name of $Tag"
   $tTag = New-Tag -Name $Tag -Category $tCat -Description "$Tag from CMDB".
   }

   # Assign the Tags to the VMs/Hosts
   $CMDBInfo | Where {$_.($Name) -eq $Tag} | Foreach {
   Write-Host ".... Assigning $Tag in Category of $Name to $($_.Name)"
   New-TagAssignment -Entity $($_.Name) -Tag $tTag | Out-Null
   } 
  }
}
Disconnect-VIServer