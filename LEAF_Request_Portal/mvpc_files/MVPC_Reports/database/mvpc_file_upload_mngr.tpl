<style>
    #content {
    	margin: 1em;
    }
    #bodyarea {
    	width: fit-content;
        width: -moz-fit-content;
    }
    table[id^="LeafFormGrid"] {
    	margin: 0 auto 0 0;
    } 
    #createRow {
        margin: 0.2em 0;
    	padding: 0.2em 0.4em 0.2em 0;
    }
</style> 

<script src="../libs/js/LEAF/XSSHelpers.js"></script>
<script>
var CSRFToken = '<!--{$CSRFToken}-->';
const portalAPI = LEAFRequestPortalAPI();
portalAPI.setBaseURL('./api/?a=');
portalAPI.setCSRFToken(CSRFToken);

function deleteRow(uid) {
	dialog_confirm.setContent('<img src="../libs/dynicons/?img=process-stop.svg&amp;w=48" alt="Cancel Request" style="float: left; padding-right: 24px" /> Are you sure you want to delete this row?');

	dialog_confirm.setSaveHandler(function() {
		$.ajax({
			type: 'POST',
			url: 'api/form/'+ uid +'/cancel',
			data: {CSRFToken: CSRFToken},
            success: function(response) {
            	if(response == 1) {
                    location.reload();
                }
            	else {
            		alert(response);
            	}
            },
            cache: false
		});
	});
	dialog_confirm.show();
}
   
  
var query, formGrid, dialogConfirm;    
function getData() {
	// Create a new Query
	var query = new LeafFormQuery();
    query.importQuery({"terms":[{"id":"categoryID","operator":"=","match":"form_52dd6","gate":"AND"},{"id":"deleted","operator":"=","match":0,"gate":"AND"}],"joins":[""],"sort":{},"getData":["32"]});

	// This specifies the function to run if the query is valid.
	query.onSuccess(function(res) {
        var recordIDs = '';
        for (var i in res) {
        	// Currently need to store the resulting list of recordIDs as a CSV
            recordIDs += res[i].recordID + ',';
        }
        var formGrid = new LeafFormGrid('grid'); // 'grid' maps to the associated HTML element ID
        formGrid.setDataBlob(res);
        
        // The column headers are configured here
        formGrid.setHeaders([
            	{name: '', indicatorID: 'deleteRow', editable: false, callback: function(data, blob) {
            		$('#'+data.cellContainerID).html('<img role="button" src="../libs/dynicons/?img=process-stop.svg&amp;w=16" alt="Delete Row '+data.recordID+'" title="Delete Row '+data.recordID+'" onclick="deleteRow('+data.recordID+')"; style="cursor: pointer">');
            	}},
            	{name: 'UID', indicatorID: 'uid', editable: false, callback: function(data, blob) {
            		$('#'+data.cellContainerID).html(data.recordID);
            	    $('#'+data.cellContainerID).on('click', function() {
                         window.open('index.php?a=printview&recordID='+data.recordID, 'LEAF', 'width=800,resizable=yes,scrollbars=yes,menubar=yes');
                    });
                 }},
                 {name: 'File Upload', indicatorID: 32},
               ]);
        // Loads the CSV created earlier to help populate the spreadsheet
        formGrid.loadData(recordIDs);
    });
	query.execute();
}
    
function createRowOpenDialog() {
    $.ajax({
    	type: 'POST',
        url: './api/?a=form/new',
        dataType: 'json',
        data: {service: '', 
                  title: '', 
                  priority: 0,
                  numform_52dd6: 1, // mvpc file upload
                  CSRFToken: '<!--{$CSRFToken}-->'}
    }).then(function(response) {
        //console.log(response);
        location.reload();
    });
}  
    
// Ensures the webpage has fully loaded, before starting the program.
$(function() {
	$('#headerTab').html('MVPC File Manager');
	$('#createRow').on('click', function() {
        createRowOpenDialog();
    });
    dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    
    getData();

});

</script>
<button class="buttonNorm" id="createRow"><img src="../libs/dynicons/?img=list-add.svg&amp;w=32" alt="Add New File">Add New File</button>

<div id="grid"></div>
<div id="confirm_xhrDialog" style="background-color: #feffd1; border: 1px solid black; visibility: hidden; display: none">
<form id="confirm_record" enctype="multipart/form-data" action="javascript:void(0);">
    <div>
        <div id="confirm_loadIndicator" style="visibility: hidden; position: absolute; text-align: center; font-size: 24px; font-weight: bold; background: white; padding: 16px; height: 100px; width: 360px">Loading... <img src="images/largespinner.gif" alt="loading..." title="loading..." /></div>
        <div id="confirm_xhr" style="font-size: 130%; width: 400px; height: 120px; padding: 16px; overflow: auto"></div>
        <div style="position: absolute; left: 10px; font-size: 140%"><button class="buttonNorm" id="confirm_button_cancelchange"><img src="../libs/dynicons/?img=edit-undo.svg&amp;w=32" alt="No" title="No" /> No</button></div>
        <div style="text-align: right; padding-right: 6px"><button class="buttonNorm" id="confirm_button_save"><img src="../libs/dynicons/?img=dialog-apply.svg&amp;w=32" alt="Yes" title="Yes" /><span id="confirm_saveBtnText"> Yes</span></button></div><br />
    </div>
</form>