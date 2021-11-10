<style>
    #import_data_existing_form, #uploadBox, {
        padding: 20px;
    }
    #category_indicators thead tr, #new_form_indicators thead tr
        background-color: rgb(185, 185, 185);
    }
    #category_indicators thead tr th, #new_form_indicators thead tr th
        padding: 7px;
    }
    #category_indicators td, #new_form_indicators td
        padding: 7px;
    }
    .modalBackground {
        width: 100%;
        height: 100%;
        z-index: 5;
        position: absolute;
        background-color: grey;
        margin-top: 0px;
        margin-left: 0px;
        opacity: 0.5;
    }
</style>
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/SheetJS/js-xlsx@1eb1ec/dist/xlsx.full.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/SheetJS/js-xlsx@64798fd/shim.js"></script>
<script type="text/javascript" src="js/lz-string/lz-string.min.js"></script>
<script src="../../../libs/js/jquery/jquery-ui.custom.min.js"></script>
<script src="../../../libs/js/promise-pollyfill/polyfill.min.js"></script>

<div id="status" style="background-color: black; color: white; font-weight: bold; font-size: 140%"></div>
<div id="uploadBox">
    <h4>Choose a Spreadsheet</h4>
    The first row of the file must be headers for the columns.
    <br/>
    <input id="sheet_upload" type="file"/>
    <br />
    <br />
</div>

<div id="import_data_existing_form" style="display: none;">
    <h4>Select a Form</h4>
    <select id="category_select"></select>
    <button id="import_btn_existing" type="button">Import</button>
    <input id="preserve_existing" type="checkbox" name="preserve_existing"/>
    <label for="preserve_existing">Preserve Row Order?</label>
    <br/><br/>

    <label for="title_input_existing"><b>Title of Requests</b></label>
    <input type="text" id="title_input_existing" />
    (Required) This will be the title for all imported requests.
    <br/><br/>

    <table id="category_indicators">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Format</th>
                <th>Description</th>
                <th>Required</th>
                <th>Sensitive</th>
                    <th>Sheet Column</th>
            </tr>
        </thead>
        <tbody></tbody>
    </table>
</div>
<div id="testContent"></div>

<div id="request_status" style="padding: 20px;"></div>

<!--{include file="site_elements/generic_confirm_xhrDialog.tpl"}-->
            <div id="dialog" title="Import Status" style="z-index:100;">
                <div class="progress-label">Starting import...</div>
                <div id="progressbar"></div>
            </div>
<div id="modal-background"></div>


<script>
    var CSRFToken = '<!--{$CSRFToken}-->';
    var orgChartPath = '<!--{$orgchartPath}-->';

    var nexusAPI = LEAFNexusAPI();
    nexusAPI.setBaseURL(orgChartPath + '/api/?a=');
    nexusAPI.setCSRFToken(CSRFToken);

    var portalAPI = LEAFRequestPortalAPI();
    portalAPI.setBaseURL('./api/?a=');
    portalAPI.setCSRFToken(CSRFToken);

    var categorySelect = $('#category_select');
    var categoryIndicators = $('#category_indicators tbody');
    var fileSelect = $('#file_select');
    var importBtnExisting = $('#import_btn_existing');
    var titleInputExisting = $('#title_input_existing');
    var titleInputNew = $('#title_input_new');
    
    var formTitle = $('#formTitleInput');
    var formDescription = $('#formDescription');
    var existingForm = $('#import_data_existing_form');
    
    var requestStatus = $('#request_status');
    var sheetUpload = $('#sheet_upload');
    var nameOfSheet = '';
    var placeInOrder;

    var totalRecords;
    var totalImported = 0;
    var createdRequests = 0;
    var failedRequests = [];
    var currentIndicators = [];
    
    var indicatorArray = [];
    var blankIndicators = [];
    var sheet_data = {};
    var dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    
    function checkFormatExisting(column) {
        for (let i = 1; i < sheet_data.cells.length; i++) {
            let value = typeof (sheet_data.cells[i]) !== "undefined" && typeof (sheet_data.cells[i][column]) !== "undefined" ? sheet_data.cells[i][column].toString() : '';
            if (value.indexOf('@va.gov') === -1 && value.indexOf(' ') === -1 && value.indexOf(',') === -1 && value.indexOf('VHA') === -1 && value.indexOf('VACO') === -1) {
                alert('The column for employees should be either an email, username, or "Last name, First Name".');
                break;
            }
        }
    }
    function buildFormat(spreadSheet) {
        $('#new_form_indicators').remove();
        let table =
            '<table id="new_form_indicators" style="text-align: center;">' +
            '   <thead>' +
            '       <tr>' +
            '           <th> Sheet Column </th>' +
            '           <th> Name </th>' +
            '           <th> Format </th>' +
            '           <th> Required </th>' +
            '           <th> Sensitive </th>' +
            '       </tr>' +
            '   <thead>' +
            '   <tbody>';
        $.each(spreadSheet.headers, function(key, value) {
            let requiredCheckbox = blankIndicators.indexOf(key) === -1 ? '<input type="checkbox"/>' : '<input type="checkbox" onclick="return false;" disabled="disabled" title="Cannot set as required when a row in this column is blank."/>';
            table +=
                '<tr>' +
                '   <td>' + key + '</td>' +
                '   <td>' + value + '</td>' +
                '   <td>' +
                '       <select onchange="checkFormatNew(event, \'' + key + '\')">' +
                '           <option value="text">Single line text</option>' +
                '           <option value="textarea">Multi-line text</option>' +
                '           <option value="number">Numeric</option>' +
                '           <option value="currency">Currency</option>' +
                '           <option value="date">Date</option>' +
                '           <option value="currency">Currency</option>' +
                '           <option value="orgchart_group">Orgchart group</option>' +
                '           <option value="orgchart_position">Orgchart position</option>' +
                '           <option value="orgchart_employee">Orgchart employee</option>' +
                '       </select>' +
                '   </td>' +
                '   <td>' + requiredCheckbox + '</td>' +
                '   <td><input type="checkbox"/></td>' +
                '</tr>';
        });
        table += '</tbody></table>';
    }

    function alphaToNum(alpha) {
        var i = 0,
            num = 0,
            len = alpha.length;
        for (; i < len; i++) {
            num = num * 26 + alpha.charCodeAt(i) - 0x40;
        }
        return num - 1;
    }
    function numToAlpha(num) {
        var alpha = '';
        for (; num >= 0; num = parseInt(num / 26, 10) - 1) {
            alpha = String.fromCharCode(num % 26 + 0x41) + alpha;
        }
        return alpha;
    }
    function _buildColumnsArray(range) {
        var i,
            res = [],
            rangeNum = range.split(':').map(function (val) {
                return alphaToNum(val.replace(/[0-9]/g, ''));
            }),
            start = rangeNum[0],
            end = rangeNum[1] + 1;
        for (i = start; i < end; i++) {
            res.push(numToAlpha(i));
        }
        return res;
    }

    function searchBlankRow(e) {
        if (blankIndicators.indexOf($(e.target).val()) > -1) {
            $(e.target).val("-1");
            alert('Column can\'t be selected because it contains blank entries.');
        }
    }

    /* build the select input with options for the given indicator
    the indicatorID corresponds to the select input id */
    function buildSheetSelect(indicatorID, sheetData, required, format, indicatorOptions) {
        let select = $(document.createElement('select'))
            .attr('id', indicatorID + '_sheet_column')
            .attr('class', 'indicator_column_select');

        if (required === "1") {
            select.attr('onchange', 'searchBlankRow(event);');
        }

        /* "blank" option */
        let option = $(document.createElement('option'))
            .attr('value', '-1')
            .html('');

        select.append(option);

        let keys = Object.keys(sheetData.headers);
        if (indicatorID === "1") {  //'1 preprod, 25 local
            //would be better to enforce form title and indID 1 option naming
            //console.log(indicatorOptions);
            indicatorOptions.forEach(function(opt){
                let option = $(document.createElement('option'))
                    .attr('value', opt)
                    .html(opt);
                select.append(option);
            });
        }
        else {
            for (let i = 0; i < keys.length; i++) {
                let option = $(document.createElement('option'))
                    .attr('value', keys[i])
                    .html(keys[i] + ': ' + sheetData.headers[keys[i]]);
                select.append(option);
            }
        }
        if (format === "orgchart_employee") {
            select.attr('onchange', 'checkFormatExisting($("option:selected", this).val());');
        }

        return select;
    }


    /* build the table row and data (<tr> and <td>) for the given indicator */
    function buildIndicatorRow(indicator, classname) {
        classname = classname || '';
        if (indicator.format === '') {
            return '';
        }

        var row = $(document.createElement('tr'));
        if (classname !== '') {
            row.addClass(classname);
        }

        var iid = $(document.createElement('td'))
            .html(indicator.indicatorID)
            .appendTo(row);

        var indicatorName = $(document.createElement('td'))
            .html(indicator.name)
            .appendTo(row);

        var indicatorFormat = $(document.createElement('td'))
            .html(indicator.format)
            .appendTo(row);

        var indicatorDesc = $(document.createElement('td'))
            .html(indicator.description)
            .appendTo(row);

        var indicatorRequired = $(document.createElement('td'))
            .html(indicator.required === "1" ? "YES" : "NO")
            .appendTo(row);

        var indicatorSensitive = $(document.createElement('td'))
            .html(indicator.is_sensitive === "1" ? "YES" : "NO")
            .appendTo(row);

        var columnSelect = $(document.createElement('td'))
            .append(buildSheetSelect(indicator.indicatorID, sheet_data, indicator.required, indicator.format, indicator.options))
            .appendTo(row);

        indicatorArray.push({'indicatorID': indicator.indicatorID, 'format': indicator.format});

        return row;
    }

    function generateReport(title) {
        urlTitle = "Requests have been generated for each row of the imported spreadsheet";
        urlQueryJSON = '{"terms":[{"id":"title","operator":"LIKE","match":"*' + title + '*"},{"id":"deleted","operator":"=","match":0}],"joins":["service"],"sort":{}}';
        urlIndicatorsJSON = '[{"indicatorID":"","name":"","sort":0},{"indicatorID":"title","name":"","sort":0}]';

        urlTitle = encodeURIComponent(btoa(urlTitle));
        urlQuery = encodeURIComponent(LZString.compressToBase64(urlQueryJSON));
        urlIndicators = encodeURIComponent(LZString.compressToBase64(urlIndicatorsJSON));

        $('#status').html('Data has been imported');
        requestStatus.html(
            'Import Completed! ' + createdRequests + ' requests made, ' + failedRequests.length + ' failures.<br/><br/>' +
            '<a class="buttonNorm" role="button" href="./?a=reports&v=3&title=' + urlTitle + '&query=' + urlQuery + '&indicators=' + urlIndicators + '">View Report<\a>'
        );
        if (failedRequests.length > 0) {
            requestStatus.append(
                '<br/><br/>' +
                'Failed to import values: <br/>' + failedRequests.join("<br/>"))
        }
    }
    //new requests removed.  will log associated info
    function makeRequests(categoryID, requestData) {
        return new Promise(function(resolve, reject){
            var title = titleInputExisting.val();

            if (typeof (requestData['failed']) !== "undefined") {
                failedRequests.push(requestData['failed']);
            } 
            requestStatus.html(createdRequests + ' out of ' + (sheet_data.cells.length - 1) + ' requests completed, ' + failedRequests.length + ' failures.');
            if (failedRequests.length === (sheet_data.cells.length - 1)) {
                requestStatus.html('All requests failed!  See log for details.');
                requestStatus.append(
                    '<br/><br/>' +
                    'Failed to import values: <br/>' + failedRequests.join("<br/>"));
                $('#status').html('Import has failed');
                failedRequests = new Array();
            } else if (createdRequests + failedRequests.length === (sheet_data.cells.length - 1)) {
                generateReport(title);
                createdRequests = 0;
                failedRequests = new Array();
            }
        });
    }

    // Converts Excel Date into a Short Date String
    // param excelDate int date in excel formatted integer field
    // return formattedJSDate MM/DD/YYY formatted string of excel date
    function convertExcelDateToShortString(excelDate) {
        var jsDate = new Date((excelDate - (25567 + 1))*86400*1000);
        var formattedJSDate = (jsDate.getMonth() + 1) + '/' + jsDate.getDate() + '/' + jsDate.getFullYear();
        return formattedJSDate;
    }


    $(function () {
        $("body").prepend($("#modal-background"));
        var progressTimer;
        var progressbar = $( "#progressbar" );
        var progressLabel = $( ".progress-label" );
        var dialog = $( "#dialog" ).dialog({
            autoOpen: false,
            closeOnEscape: false,
            resizable: false,
            open: function() {
                $("#modal-background").addClass("modalBackground");
                 $(".ui-dialog-titlebar-close").hide();
                progressTimer = setTimeout( progress, 2000 );
            },
            close: closeImport
        });

        progressbar.progressbar({
            value: false,
            change: function() {
                progressLabel.text( "Current Progress: " + progressbar.progressbar( "value" ) + "%" );
                
            },
            complete: function() {
                 $(".ui-dialog-titlebar-close").show();
            }
        });

        function closeImport() {
            $("#modal-background").removeClass("modalBackground");
            clearTimeout( progressTimer );
            dialog.dialog( "close" );
            progressbar.progressbar( "value", false );
            progressLabel.text( "Starting import..." );
            progressbar.progressbar( "value", 0);
        }

        function progress() {
            var val = progressbar.progressbar( "value" ) || 0;
            progressbar.progressbar( "value", Math.floor( totalImported/totalRecords *100) );
            if ( val <= 99 ) {
                progressTimer = setTimeout( progress, 50 );
            }
        }

        /*builds select options of workflows */
        portalAPI.Workflow.getAllWorkflows(
            function(msg) {
                if(msg.length > 0) {
                    var buffer = '<label for="workflowID"><b>Workflow of Form</b></label><select id="workflowID">';
                    buffer += '<option value="0">No Workflow</option>';
                    for(var i in msg) {
                        buffer += '<option value="'+ msg[i].workflowID +'">'+ msg[i].description +' (ID: #'+ msg[i].workflowID +')</option>';
                    }
                    buffer += '</select>    This will be the workflow for the custom form.\n';
                    $('#formWorkflowSelect').html(buffer);
                }
            },
            function (err) {
            }
        );

        function importExisting() {
            totalImported = 0;
            $('#status').html('Processing...'); /* UI hint */
            requestStatus.html('Parsing sheet data...');

            function selectRowToAnswer(i) {

                return new Promise(function(resolve,reject){
                var titleIndex = i;
                var completed = 0;
                var row = sheet_data.cells[titleIndex];
                var requestData = new Object();
                function answerQuestions() {
                    return new Promise(function(resolve, reject){

                    if (completed === indicatorArray.length) {
                        requestData['title'] = titleInputExisting.val() + '_' + titleIndex;
                        makeRequests(categorySelect.val(), requestData).then(function(){
                            console.log(requestData); //row data for request builder row.
                            resolve();
                        });
                    } else {
                        var indicatorColumn = $('#' + indicatorArray[completed].indicatorID + '_sheet_column').val();

                        /* skips indicators that aren't set*/
                        if (indicatorColumn === "-1") {
                            completed++;
                            answerQuestions().then(function(){
                                resolve();});
                            
                        } else {
                            var currentIndicator = indicatorArray[completed].indicatorID; //num as str eg "4"
                            var currentFormat = indicatorArray[completed].format;

                            switch (currentFormat) {
                                case 'orgchart_employee':
                                    let sheetEmp = typeof (row[indicatorColumn]) !== "undefined" && row[indicatorColumn] !== null ? row[indicatorColumn].toString().trim() : '';
                                    nexusAPI.Employee.getByEmail(sheetEmp, 
                                        function(user){
                                            if(user){ //console.log('user', user);  object, keys of IDs, property is object with user info
                                                let objKeys = Object.keys(user);
                                                if (objKeys.length > 1){
                                                    requestData['failed'] = indicatorColumn + (titleIndex + 1) + ', Multiple employees found for ' + sheetEmp + '.  Make sure it is in the correct format.';
                                                    completed++;
                                                    answerQuestions().then(function(){
                                                        resolve();
                                                    })
                                                }
                                                else if (objKeys.length === 1){
                                                    let userObj = user[objKeys[0]];
                                                    let userNexID = parseInt(userObj.empUID); //orgchart empUID
                                                    //TODO: modify for backup addition
                                                    //don't want to actually make requests, just want the info after
                                                    requestData['failed'] = indicatorColumn + (titleIndex + 1) + ', employee email, ' + sheetEmp + ', ' + userNexID;
                                                    completed++;
                                                    answerQuestions().then(function(){
                                                        resolve();
                                                    })
                                                } else {
                                                    requestData['failed'] = indicatorColumn + (titleIndex + 1) + ", Error retrieving email for " + sheetEmp; 
                                                    completed++;
                                                    answerQuestions().then(function(){
                                                        resolve();
                                                    })
                                                }
                                            }
                                        }, 
                                        function (err) {
                                                console.log(err);
                                                requestData['failed'] = indicatorColumn + (titleIndex + 1) + ": Error retrieving email for employee on sheet row " + (titleIndex + 1); 
                                                completed++;
                                                answerQuestions().then(function(){
                                                    resolve();
                                                })
                                        }
                                    );
                                default:
                                    break;
                            }
                        }
                    }
                    })
                }
                answerQuestions().then(function(){
                    resolve();})
                });
            }

            /* iterate through the sheet cells, which are organized by row */
            totalRecords = sheet_data.cells.length -1; 
            dialog.dialog( "open" );
            var preserveOrder = $("#preserve_existing").prop("checked");

            if(preserveOrder){
                placeInOrder = 1;
                selectRowToAnswer(placeInOrder).then(iterate);
                function iterate(){
                    placeInOrder++;
                    totalImported++;
                    if(placeInOrder <= sheet_data.cells.length -1){
                        selectRowToAnswer(placeInOrder).then(iterate);
                    }
                }
            }
            else{
                for (let i = 1; i <= sheet_data.cells.length - 1; i+=2) {
                    let doublet = [];
                    doublet.push(selectRowToAnswer(i));
                    
                    let addAnother = i+1 <= sheet_data.cells.length - 1;
                    if(addAnother){
                        doublet.push(selectRowToAnswer(i+1));
                    }
                    Promise.all(doublet).then(function(results){
                        totalImported += results.length;
                    });
                }
            }
            $('#status').html('Data has been imported');
        }

        portalAPI.Forms.getAllForms(
            function (results) {
                /* build a select options for each form */
                let opt = $(document.createElement('option'))
                    .attr('value', '-1')
                    .html('');
                categorySelect.append(opt);
                for (let i = 0; i < results.length; i++) {
                    let category = results[i];
                    let opt = $(document.createElement('option'))
                        .attr('value', category.categoryID)
                        .html(category.categoryName + ' : ' + category.categoryDescription);
                    categorySelect.append(opt);
                }
            },
            function (error) {
            }
        );

        /*  build the rows for the given indicator data, also processes its children if present */
        function buildRows(indicator, classname) {
            classname = classname || '';
            if (typeof (indicator) !== "undefined" && indicator !== null) {
                categoryIndicators.append(buildIndicatorRow(indicator, classname));

                if (typeof (indicator.child) !== "undefined" && indicator.child != null) {
                    let children = Object.keys(indicator.child);
                    for (let i = 0; i < children.length; i++) {
                        let child = indicator.child[children[i]];
                        buildRows(child);
                    }
                }
            }
        }

        importBtnExisting.on('click', function () {
            if (titleInputExisting.val() === '') {
                return alert('Request title is required.');
            }
            dialog_confirm.setContent('Are you sure you want to submit ' + (sheet_data.cells.length - 1) + ' requests?');
            dialog_confirm.setSaveHandler(function () {
                dialog_confirm.hide();
                importExisting();
            });
            dialog_confirm.show();
        });

        categorySelect.on('change', function () {
            categoryIndicators.html('');
            portalAPI.Forms.getIndicatorsForForm(categorySelect.val(),
                function (results) {
                    currentIndicators = results;
                    indicatorArray = new Array();
                    for (let i = 0; i < results.length; i++) {
                        let indicator = results[i];
                        buildRows(indicator);
                    }
                },
                function (error) {
                }
            );
        });

        sheetUpload.on('change', function (e) {
            categorySelect.val("-1");
            categoryIndicators.html('');
            let files = e.target.files,file;
            if (!files || files.length === 0) return;
            file = files[0];
            const fileReader = new FileReader();
            fileReader.onload = function (e) {
                let cells = [];
                let data = new Uint8Array(e.target.result);

                /* passes file through js-xlsx library */
                try {
                    var returnedJSON = XLSX.read(data, {type: 'array'});
                }
                catch (err) {
                    existingForm.css('display', 'none');
                    alert('Unsupported file: could not read');
                    return;
                }
                nameOfSheet = returnedJSON.SheetNames[0];

                /* conforms js-xlsx schema to LEAFPortalApi.js schema
                sheet data is stored in the Sheets property under filename */
                var rawSheet = returnedJSON.Sheets[nameOfSheet];

                /* insures spreadsheet has filename */
                if(typeof (rawSheet) === "undefined"){
                    existingForm.css('display', 'none');
                    alert('Unsupported file: file requires name');
                    return;
                }

                /* reads layout of sheet */
                var columnNames = _buildColumnsArray(rawSheet['!ref']);
                var rows = parseInt(rawSheet['!ref'].substring(rawSheet['!ref'].indexOf(':'), rawSheet['!ref'].length).replace(/:[A-Z]+/g, '')) - 1;
                var headers = new Object();

                /* converts schema */
                for(let i = 0; i <= rows; i++) {
                    if(i !== 0){
                        cells[i.toString()] = {};
                    }
                    for (let j = 0; j < columnNames.length; j++) {
                        if (i === 0){
                            if (typeof (rawSheet[columnNames[j] + (i + 1).toString()]) === "undefined") {                                
                            } else {
                                headers[columnNames[j]] = rawSheet[columnNames[j] + (i + 1).toString()].v;
                            }
                        } else if (typeof (rawSheet[columnNames[j] + (i + 1).toString()]) === "undefined") {
                            cells[i.toString()][columnNames[j]] = '';
                            blankIndicators.push(columnNames[j]);
                        } else {
                            cells[i.toString()][columnNames[j]] = rawSheet[columnNames[j] + (i + 1).toString()].v;
                        }
                    }
                }
                sheet_data = {};
                sheet_data.headers = headers;
                sheet_data.cells = cells;
                if (cells.length > 0) {
                    buildFormat(sheet_data);
                } else {
                    alert('This spreadsheet has no data');
                }
            };
            fileReader.readAsArrayBuffer(file);
            existingForm.css('display', 'block');
        });
    });
</script>