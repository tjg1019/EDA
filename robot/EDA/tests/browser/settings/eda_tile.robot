*** Settings ***
Documentation   Check for EDA tile

Resource        robot/EDA/resources/EDA.robot
Suite Setup     Open test browser
Suite Teardown  Capture screenshot and delete records and close browser

*** Test Cases ***
Verify EDA tile
    Open app launcher
    Verify app exists    EDA