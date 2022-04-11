*** Settings ***
Documentation     Insert the robot details and book robots
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Dialogs
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Robocorp.Vault
Library           RPA.FileSystem

*** Tasks ***
Insert the robot details and book robots
    ${download_link}=    Dialog to read download link
    Download the Excel file    ${download_link}
    ${table}=    Read data from CSV file
    ${secret}=    Get data from vault
    Open the intranet website    ${secret}
    Fill the details for robots    ${table}
    Archive Folder
    Close Browser

*** Keywords ***
Dialog to read download link
    Add heading    Order Bot
    Add text input    file_path    label=Enter download link
    ${dialog}=    Show dialog
    ${results}=    Wait dialog    ${dialog}
    [Return]    ${results.file_path}

Download the Excel file
    [Arguments]    ${download_link}
    Download    ${download_link}    overwrite=True

Read data from CSV file
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

Get data from vault
    ${secret}=    RPA.Robocorp.Vault.Get Secret    pageurl
    Log    ${secret}
    [Return]    ${secret}[url]

Open the intranet website
    [Arguments]    ${filepath}
    Log    ${filepath}
    Open Available Browser    ${filepath}
    Maximize Browser Window
    Click Button    OK

Fill the details for robots
    [Arguments]    ${order_det}
    FOR    ${row}    IN    @{order_det}
        ${orderno}=    Set Variable    ${row}[Order number]
        Log    ${row}[Order number]
        Select From List By Index    head    ${row}[Head]
        Select Radio Button    body    ${row}[Body]
        Input Text    class:form-control    ${row}[Legs]
        Input Text    address    ${row}[Address]
        Click Button    Preview
        Wait Until Keyword Succeeds    10x    3 s    Click Order Button
        Generate PDFFile    ${orderno}
        Add screenshot files to pdf    ${orderno}
        Click Button    order-another
        Click Button    OK
    END

Click Order Button
    Click Button    id:order
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_preview.png
    Is Element Visible    id:receipt    missing_ok=False

Generate PDFFile
    [Arguments]    ${pdfname}
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipts${/}${pdfname}.pdf    overwrite=True

Add screenshot files to pdf
    [Arguments]    ${pdf_name}
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}robot_preview.png
    Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}receipts${/}${pdfname}.pdf    append=True

Archive Folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    receipts.zip
