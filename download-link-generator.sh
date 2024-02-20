$startYear = 2007
$endYear = 2022

$baseUrl = "https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_pentad/tifs"
$outputFilePath = "C:\dls\chirps_urls.txt"
$downloadUrls = @()
foreach ($year in $startYear..$endYear) {
    foreach ($month in 1..12) {
        $monthFormatted = "{0:D2}" -f $month
        foreach ($pentad in 1..6) {
            $url = "$baseUrl/chirps-v2.0.$year.$monthFormatted.$pentad.tif.gz"
            $downloadUrls += $url
        }
    }
}
$downloadUrls | Out-File -FilePath $outputFilePath
Write-Host "URLs have been saved to $outputFilePath"
