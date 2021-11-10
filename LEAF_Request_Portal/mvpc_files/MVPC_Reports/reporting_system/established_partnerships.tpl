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
</style>    


<script src="../libs/js/LEAF/XSSHelpers.js"></script>

<script>
    
var CSRFToken = '<!--{$CSRFToken}-->';
var portalAPI = LEAFRequestPortalAPI();
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
    
    query = new LeafFormQuery();
    query.importQuery({"terms":[{"id":"categoryID","operator":"=","match":"form_a03ae","gate":"AND"},{"id":"deleted","operator":"=","match":0,"gate":"AND"}],"joins":["service","initiatorName"],"sort":{},"getData":["39","30","32","41"]});
    query.addTerm('userID', '=', "<!--{$userID}-->");
    
    $.ajax({
		type: 'GET',
        url: '<!--{$orgchartPath}-->/api/employee/search/userName/_<!--{$userID}-->',
        success: function(res) {
            let nexID = res[0].empUID;
            if(nexID !== undefined && nexID !== null){
            	
                $.ajax({
                    type: 'GET',
                    url: '<!--{$orgchartPath}-->/api/employee/'+ nexID +'/backup', 
                    success: function(resBackup){
                        //console.log(resBackup);
                        if (resBackup && resBackup.length > 0 && resBackup[0].userName !== undefined){
                            let backupName = resBackup[0].userName
                            ///////////// QUERY EXE ///////////////
                            query.addTerm('userID', '=', backupName, 'OR');    
                            query.execute();   
                            //////////////////////////////////////		
                    	} else { //if there is not backup just ex w userID
                			query.execute();  
                		}
                    }  
                });
            } 
        },
        cache: false
    }); 
    
    
	//run if the query is valid.
	query.onSuccess(function(res) {
        var recordIDs = '';
        for (var i in res) {
        	// list of recordIDs as a CSV
            recordIDs += res[i].recordID + ',';
        }
        formGrid = new LeafFormGrid('grid'); // 'grid' maps to the associated HTML element ID
        formGrid.enableToolbar();
        formGrid.hideIndex(); // Hide standard UID column
        formGrid.setDataBlob(res); 
        formGrid.setHeaders([
            {name: '', indicatorID: 'deleteRow', editable: false, callback: function(data, blob) {
            	$('#'+data.cellContainerID).html('<img role="button" src="../libs/dynicons/?img=process-stop.svg&amp;w=16" alt="Delete Row '+data.recordID+'" title="Delete Row '+data.recordID+'" onclick="deleteRow('+data.recordID+')"; style="cursor: pointer">');
            }},
            {name: 'UID', indicatorID: 'uid', editable: false, callback: function(data, blob) {
            	$('#'+data.cellContainerID).html(data.recordID);
            }},
            {name: 'Name of Organization', indicatorID: 39},
            {name: 'Organization Phone Number or Web Address', indicatorID: 30},
            {name: 'type (check one)', indicatorID: 32},
            {name: 'Goal of Partnership', indicatorID: 41},
            {name: 'Initiator', indicatorID: 'initiator', editable: false, callback: function(data, blob) {
                $('#'+data.cellContainerID).html(blob[data.recordID].firstName + " " + blob[data.recordID].lastName);
            }}
        ]);
        formGrid.loadData(recordIDs);
    });
}

    
function createRowOpenDialog() {  
    $.ajax({
    	type: 'POST',
        url: './api/?a=form/new',
        dataType: 'json',
        data: {service: '', // Either a service ID # or leave blank
                  title: '', // Arbitrary title for the request
                  priority: 0,
                  numform_a03ae: 1, 
                  CSRFToken: '<!--{$CSRFToken}-->'}
    }).then(function(response) {
        let recordID = parseFloat(response);
        if(!isNaN(recordID) && isFinite(recordID) && recordID != 0) {
            formGrid.form().setRecordID(recordID);
            formGrid.form().setPostModifyCallback(function() {
                formGrid.form().dialog().hide();
                location.reload();
            });
            formGrid.form().getForm(29, 1); // parent ID
            
            // workaround dialog.setCancelHandler limitation for required fields
            $('#' + formGrid.form().dialog().containerID).on('dialogbeforeclose', function() {
                location.reload();
            });
            formGrid.form().dialog().show();
        }
        else {
            alert(response + '\n\nPlease contact your system administrator.');
        }
    });
}
    

$(function() {
    $('#headerTab').html('Established Partnerships');
	$('#createRow').on('click', function() {
        createRowOpenDialog();
    });
    dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    
    getData();
}); 

</script>

<button class="buttonNorm" id="createRow"><img src="../libs/dynicons/?img=list-add.svg&amp;w=32" alt="Add Activity">Add Partnership Entry</button>
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