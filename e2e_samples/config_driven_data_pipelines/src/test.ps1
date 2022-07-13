$TARGETDIR = "coverage"
cd src
if(!(Test-Path -Path $TARGETDIR )){
    New-Item -ItemType directory -Path $TARGETDIR
}
cd coverage
pytest
exit $LASTEXITCODE