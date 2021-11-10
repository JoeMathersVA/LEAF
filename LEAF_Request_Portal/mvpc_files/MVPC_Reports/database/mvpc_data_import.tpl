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
    let numberBaseIndicators = 0;
    var indicatorArray = [];
    var blankIndicators = [];
    var sheet_data = {};
    var dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    let districtInfo = '';  //update with col 1 val;
    
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

    function tagGroup(groupID, tag, text) {
        console.log(text);
        let url = '<!--{$orgchartPath}-->/api/?a=group/'+ groupID + '/tag';
        $.ajax({
            type: 'POST',
            url: url,
            data: {
                tag: tag,
                CSRFToken: '<!--{$CSRFToken}-->'
            },
            success: function() {
                console.log('tagged')
            },
            cache: false
        });
    }

    
    function addMember(groupID, userID) {
        let url = '<!--{$orgchartPath}-->/api/?a=group/'+ groupID + '/employee';
        $.ajax({
            type: 'POST',
            url: url,
            data: {'empUID': userID,
            CSRFToken: '<!--{$CSRFToken}-->'},
            success: function() {
                console.log('posted ', userID, ' to ', groupID);
            },
            cache: false
        });
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

    function makeRequests(categoryID, requestData) {
        return new Promise(function(resolve, reject){
            var title = titleInputExisting.val();

            if (typeof (requestData['failed']) !== "undefined") {
                failedRequests.push(requestData['failed']);
            } else {
                portalAPI.Forms.newRequest(
                    categoryID,
                    requestData,
                    function (recordID) {
                        /* recordID is the recordID of the newly created request, it's 0 if there was an error */
                        if (recordID > 0) {
                            createdRequests++;
                            requestStatus.html(createdRequests + ' out of ' + (sheet_data.cells.length - 1) + ' requests completed, ' + failedRequests.length + ' failures.');
                        } else {
                            failedRequests.push('Error creating request for the following data: ' + requestData);
                        }
                        if (createdRequests + failedRequests.length === (sheet_data.cells.length - 1)) {
                            generateReport(title);
                            createdRequests = 0;
                            failedRequests = new Array();

                        }
                        resolve();
                    },
                    function (error) {
                        failedRequests.push(requestData);
                        resolve();
                    }
                );
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
                                    
                                    //TODO: try getByEmailNational and see if they are already available, ELSE import
                                    
                                    nexusAPI.Employee.getByEmailNational({
                                        'onSuccess': function (user) {
                                            let res = Object.keys(user);
                                            let empUID = res[0];
                                            let emp = user[empUID]; 
                                            //res[0] is national empUID, user[empUID] is object with user info, use emp.userName for import
                                            let groupName = '';
                                        
                                            //switch here for spreadsheet columns associated with facilitiy or region.
                                            //finds the group and add members according to role
                                            switch(indicatorColumn){
                                                case "D": //facility director, 2 designees, MVPC + alt
                                                case "F":
                                                case "H":
                                                case "R":
                                                case "Y":
                                                    //group names are VISN # - facility name OR district - facility name
                                                    groupName = row["B"];
                                                    let prefix;
                                                    let colon_index = row["A"].toString().indexOf(':'); 

                                                    if (colon_index !== -1 ){
                                                        prefix = row["A"].slice(0, colon_index).toString() + ' - '; //visn num -
                                                    } else {
                                                        prefix = row["A"].toString().replace('District', districtInfo); //name district  ---> name VBA/NCA -
                                                        prefix += ' - ';
                                                    }
                                                    groupName = prefix + groupName; //visn # - facil, or district - facil
                                                    
                                                    nexusAPI.Groups.searchGroups({
                                                        'onSuccess': function (groups) {
                                                            if (groups.length === 1) {
                                                                let grp = groups[Object.keys(groups)[0]];
                                                                let grpID = parseInt(grp.groupID);
                                                                
                                                                nexusAPI.Employee.getByEmail(sheetEmp,
                                                                    function (users){
                                                                        if(users){
                                                                            let userObj = users[Object.keys(users)[0]];
                                                                            let userNexID = parseInt(userObj.empUID); //orgchart empUID
                                                                            //console.log('success', 'group: ', grpID, 'userID', userNexID);
                                                                            addMember(grpID, userNexID) //number number //TODO: 082721 test below
                                                                        
                                                                        }
                                                                    }, 
                                                                    function (err){
                                                                        console.log('fail', err)
                                                                    });
                                                                
                                                                
                                                            } else {
                                                                console.log('multiple groups or no group found')
                                                            }
                                                        },
                                                        'onFail': function (err) {
                                                            console.log(err);
                                                        },
                                                        async: true
                                                    }, groupName);
                                                    break;
                                                case "J": //visn or districts. region director, 3 designees
                                                case "L":
                                                case "N":
                                                case "P":
                                                    groupName = row["A"] + " " + districtInfo;
                                                    
                                                    nexusAPI.Groups.searchGroups({
                                                        'onSuccess': function (groups) {
                                                            if (groups.length === 1) {
                                                                let grp = groups[Object.keys(groups)[0]];
                                                                let grpID = parseInt(grp.groupID);
                                                                
                                                                nexusAPI.Employee.getByEmail(sheetEmp,
                                                                    function (users){
                                                                        if (users){
                                                                            let userObj = users[Object.keys(users)[0]];
                                                                            let userNexID = parseInt(userObj.empUID);
                                                                            console.log('success', 'group: ', grpID, 'userID', userNexID);
                                                                            addMember(grpID, userNexID) //number number
                                                                    
                                                                        }
                                                                    }, 
                                                                    function (err){
                                                                        console.log('fail', err)

                                                                    });


                                                            } else {
                                                                console.log('multiple groups or no group found: ', groups)
                                                            }
                                                        },
                                                        'onFail': function (err) {
                                                            console.log(err);
                                                        },
                                                        async: true
                                                    }, groupName); //if it's a visn or district
                                                    break;
                                                
                                                default: 
                                                    console.log("unexpected switch value: ", indicatorColumn);
                                            }

                                            if (typeof (emp) !== "undefined" && emp !== null && res.length === 1) {//one employee

                                                //POST fetchURL = apiURL + '/import/_' + userName;  emp.userName
                                                nexusAPI.Employee.importFromNational({
                                                    'onSuccess': function (results) {
                                                        console.log('import from Nat results', results); //strNumber (national empUID) //TODO: confirm 684console
                                                        if (!isNaN(results)) {
                                                            requestData[currentIndicator] = parseInt(results);
                                                        } else {
                                                            requestData['failed'] = indicatorColumn + titleIndex + ': Employee ' + sheetEmp + ' not found. Error: '+ results;
                                                        }
                                                        completed++;
                                                        answerQuestions().then(function(){
                                                            resolve();})
                                                    },
                                                    'onFail': function (err) {
                                                        requestData['failed'] = indicatorColumn + titleIndex + ": Error retrieving employee on sheet row " + titleIndex + " for indicator " + index;
                                                        completed++;
                                                        answerQuestions().then(function(){
                                                            resolve();})
                                                    },
                                                    'async': true
                                                }, emp.userName);
                                            } else if (res.length > 1) {
                                                requestData['failed'] = indicatorColumn + titleIndex + ': Multiple employees found for ' + sheetEmp + '.  Make sure it is in the correct format.';
                                                completed++;
                                                answerQuestions().then(function(){
                                                    resolve();})
                                            } else {
                                                requestData['failed'] = indicatorColumn + titleIndex + ': Employee ' + sheetEmp + ' not found.';
                                                completed++;
                                                answerQuestions().then(function(){
                                                    resolve();
                                                })
                                            }
                                        },
                                        'onFail': function (err) {
                                            console.log(err);
                                            requestData['failed'] = indicatorColumn + titleIndex + ": Error retrieving email for employee on sheet row " + titleIndex + " indicator " + index;
                                            completed++;
                                            answerQuestions().then(function(){
                                                resolve();
                                            })
                                        },
                                        'async': true
                                    }, sheetEmp);
                                    break;

                                case 'orgchart_group':
                                    let sheetGroup = typeof (row[indicatorColumn]) !== "undefined" && row[indicatorColumn] !== null ? row[indicatorColumn].toString() : '';
                                    
                                    //update the sheetgroup names since they are not written this way on spreadsheet
                                    if (indicatorColumn === "A"){ //VISN #: name, or name District
                                        if (sheetGroup.indexOf(':') !== -1){
                                            sheetGroup = sheetGroup.replace(':', ' VHA -'); //VISN # VHA - name
                                        } else {
                                            sheetGroup = sheetGroup + " " + districtInfo;  //VBA or NCA  name district VBA
                                        }
                                    }

                                    //if it is a facility prefix the name with the visn or region
                                    if (indicatorColumn === "B"){
                                        let prefix;
                                        let colon_index = row["A"].toString().indexOf(':'); 
                                        if (colon_index !== -1 ){
                                            prefix = row["A"].slice(0, colon_index).toString() + ' - '; //visn num -
                                        } else {
                                            prefix = row["A"].toString().replace('District', districtInfo); //name district  ---> name VBA/NCA -
                                            prefix += ' - '; 
                                        }
                                        sheetGroup = prefix + sheetGroup; //visn # - group name
                                    }
                        
                                    //search using the updated (if nec) name
                                    nexusAPI.Groups.searchGroups({
                                        'onSuccess': function (groups) {
                                            if (groups.length === 1) {
                                                let grp = groups[Object.keys(groups)[0]];
                                                requestData[currentIndicator] = parseInt(grp.groupID);
                                                //console.log('groups', groups, grp); //group info object, and array
                                                tagGroup(grp.groupID, 'NATIONAL_MVPC_Database', 'tagged from search'); 
                                            } else if (groups.length > 1) {
                                                requestData['failed'] = indicatorColumn + titleIndex + ': Multiple groups found for ' + sheetGroup + '.  Make sure that the name is exact.';
                                            } else {
                                                //  post a new group if needed ... run twice ?
                                                $.ajax({
                                                    type: 'POST',
                                                    url: '<!--{$orgchartPath}-->/api/?a=group',
                                                    data: {
                                                        title: sheetGroup,
                                                        CSRFToken: '<!--{$CSRFToken}-->'
                                                    },
                                                    success: function(strGroupID) {
                                                        strGroupID = strGroupID || 0;
                                                        if(strGroupID !== 0 ) {
                                                            tagGroup(strGroupID, 'NATIONAL_MVPC_Database', 'tagged from post'); 
                                                            requestData[currentIndicator] = parseInt(strGroupID);
                                                        }
                                                        else { ///*******************
                                                            console.warn('group did not post')
                                                        }
                                                    },
                                                    cache: false
                                                });
                                            }
                                            completed++;
                                            answerQuestions().then(function(){
                                                resolve();})
                                        },
                                        'onFail': function (err) {
                                            requestData['failed'] = indicatorColumn + titleIndex + ": Error retrieving group on sheet row " + titleIndex + " indicator " + index;
                                            completed++;
                                            answerQuestions().then(function(){
                                                resolve();})
                                        },
                                        'async': true
                                    }, sheetGroup);
                                    break;
                                case 'orgchart_position':
                                    var sheetPosition = typeof (row[indicatorColumn]) !== "undefined" && row[indicatorColumn] !== null ? row[indicatorColumn].toString() : '';
                                    nexusAPI.Positions.searchPositions({
                                        'onSuccess': function (positions) {
                                            if (positions.length === 1) {
                                                var pos = positions[Object.keys(positions)[0]];
                                                requestData[currentIndicator] = parseInt(pos.positionID);
                                            } else if (positions.length > 1) {
                                                requestData['failed'] = indicatorColumn + titleIndex + ': Multiple positions found for ' + sheetPosition + '.  Make sure that the name is exact.';
                                            } else {
                                                requestData['failed'] = indicatorColumn + titleIndex + ': Position ' + sheetPosition + ' not found.';
                                            }
                                            completed++;
                                            answerQuestions().then(function(){
                                                resolve();})
                                        },
                                        'onFail': function (err) {
                                            requestData['failed'] = indicatorColumn + titleIndex + ": Error retrieving group on sheet row " + titleIndex + " indicator " + index;
                                            completed++;
                                            answerQuestions().then(function(){
                                                resolve();})
                                        },
                                        'async': true
                                    }, sheetPosition);
                                    break;
                                case 'date':
                                    var cellDate = typeof (row[indicatorColumn]) !== "undefined" && row[indicatorColumn] !== null ? row[indicatorColumn].toString() : '';

                                    // check if excel formatted number
                                    if (!isNaN(cellDate) && cellDate !== '') {
                                        var convertedDate = convertExcelDateToShortString(parseInt(cellDate));
                                        requestData[currentIndicator] = convertedDate;
                                    } else {
                                        requestData[currentIndicator] = cellDate;
                                    }

                                    completed++;
                                    answerQuestions().then(function(){
                                        resolve();})
                                    break;
                                default:
                                    //VA Admin Office is not on the spreadsheet
                                    //for custom import only
                                    if (currentIndicator === "1"){  //TODO: will vary by portal/forms CHANGE ID BELOW TOO
                                        requestData[currentIndicator] = document.getElementById('1_sheet_column').value; //<------
                                        completed++;
                                        answerQuestions().then(function (){
                                            resolve();})
                                        break;
                                    }
                                    requestData[currentIndicator] = row[indicatorColumn];
                                    completed++;
                                    answerQuestions().then(function (){
                                        resolve();})
                                    break;
                            }
                        }
                    }
                    });
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

        /**
         * Purpose: Add indicators according to additional form selection
         * @param categoryID (portal category ID, )
         */
        function addChosenFormIndicators(categoryID) {
            $.ajax({
                type: 'GET',
                url: './api/formStack/categoryList/all', //'./api/form/'+categoryID 'controller is undefined'
                success: function (categories) {
                    let selectedForm = document.getElementById('1_sheet_column').value + ' MVPC';
                    let chosenForm = categories.find(function(cat) {
                        return cat.categoryName === selectedForm;
                    });
                    if (chosenForm !== undefined) {
                        portalAPI.Forms.getIndicatorsForForm(chosenForm.categoryID,
                            function (results) {
                                currentIndicators = currentIndicators.concat(results);
                                for (let i = 0; i < results.length; i++) {
                                    let indicator = results[i];
                                    buildRows(indicator, 'merged-indicator');
                                }
                            },
                            function (error) {
                                console.warn('An error has occurred.');
                            }
                        );
                    } else {
                        //chosen form not found
                    }
                },
                cache: false
            });
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
                    numberBaseIndicators = currentIndicators.length;
                    indicatorArray = new Array();

                    for (let i = 0; i < results.length; i++) {
                        let indicator = results[i];
                        buildRows(indicator);
                    }
                    let elIndicator1Select = document.getElementById('1_sheet_column');
                    if(elIndicator1Select) {
                        document.getElementById('1_sheet_column').addEventListener('change', function () {
                            currentIndicators = currentIndicators.slice(0,numberBaseIndicators);
                            indicatorArray = indicatorArray.slice(0,numberBaseIndicators);
                            let prevMergedIndicatorRows = document.getElementsByClassName('merged-indicator');
                            while(prevMergedIndicatorRows[0]) {
                                prevMergedIndicatorRows[0].parentNode.removeChild(prevMergedIndicatorRows[0]);
                            }
                            addChosenFormIndicators(categorySelect.val()); //value (formID) of initial selection (portal categoryID)
                            districtInfo = document.getElementById('1_sheet_column').value;
                        });
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
