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
    #date1, #date2 {
    	margin-right: 1em;
        width: 125px;
    }
    #get-reports-by-dates {
        background-color: #2078b4;
        color: #f0f0ff;
        border: 1px outset #206eb2;
        cursor: pointer;
        text-shadow: 1px 1px 2px rgb(0,0,0);
        box-shadow: 0 0 3px 1px rgba(0,0,15,0.3);
        padding: 0.3em 0.5em;
        border-radius: 4px;
    }
    #get-reports-by-dates:hover, #get-reports-by-dates:focus, #get-reports-by-dates:active {
        color: #fff;
    	border: 1px outset #b8f0f0;
        background-color: #004ea2;
    }
    #get-reports-by-dates:active {
       	transform: translate(1px,1px);
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
function getData(dateStart, dateEnd) {
    
    query = new LeafFormQuery();
    query.importQuery({"terms":[{"id":"categoryID","operator":"=","match":"form_a0467","gate":"AND"},{"id":"deleted","operator":"=","match":0,"gate":"AND"}],"joins":["service","initiatorName"],"sort":{},"getData":["40","34","35","36","37", "38"]});
    
    let now = new Date();
    let timezoneoffset = now.getTimezoneOffset()*60; //minutes --> sec
    if (dateStart !== undefined && dateStart !== ""){  
        let ds = new Date(dateStart);
        let dsAdjusted = ds.getTime() + timezoneoffset*1000;
        console.log(dsAdjusted);
    	query.addTerm('date', '>=', new Date(dsAdjusted));    //date 1
    } 
    if (dateEnd !== undefined && dateEnd !== ""){  
        let de = new Date(dateEnd);
        let deAdjusted = de.getTime() + timezoneoffset*1000;
    	query.addTerm('date','<=', new Date(deAdjusted));     //date 2
    } 
    
	query.onSuccess(function(res) {
        console.log(res);
        var recordIDs = '';
        for (var i in res) {
            recordIDs += res[i].recordID + ',';
        }
        formGrid = new LeafFormGrid('grid'); 
        formGrid.enableToolbar();
        formGrid.hideIndex(); 
        formGrid.setDataBlob(res);   
        formGrid.setHeaders([
            {name: '', indicatorID: 'deleteRow', editable: false, callback: function(data, blob) {
            	$('#'+data.cellContainerID).html('<img role="button" src="../libs/dynicons/?img=process-stop.svg&amp;w=16" alt="Delete Row '+data.recordID+'" title="Delete Row '+data.recordID+'" onclick="deleteRow('+data.recordID+')"; style="cursor: pointer">');
            }},
            {name: 'UID', indicatorID: 'uid', editable: false, callback: function(data, blob) {
            	$('#'+data.cellContainerID).html(data.recordID);
            }},
            {name: 'Operations Element', indicatorID: 40},
            {name: 'Proposed Objectives and Proposed Outreach', indicatorID: 34},
            {name: 'Responsible Official(s)', indicatorID: 35},
            {name: 'Target Date/Frequency', indicatorID: 36},
            {name: 'Estimated Costs (Yearly)', indicatorID: 37},
            {name: 'Estimated Staff Hours', indicatorID: 38},
            {name: 'Initiator', indicatorID: 'initiator', editable: false, callback: function(data, blob) {
                $('#'+data.cellContainerID).html(blob[data.recordID].firstName + " " + blob[data.recordID].lastName);
            }},
            {name: 'Date Created', indicatorID: 'date', editable: false, callback: function(data, blob) {
                $('#'+data.cellContainerID).html(new Date(blob[data.recordID].date*1000).toDateString());
            }}
        ]);
        formGrid.loadData(recordIDs);
    });
    query.execute();
}

    	
   
    

$(function() {

    $('#headerTab').html('Operations Plan');
    dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    $('#get-reports-by-dates').on('click', function(){
        getData($('#date1').val(), $('#date2').val());
    });
    
}); 

</script>

<p>Select from the date pickers to search within a date range.</p>
<p>Only the selected dates will be used (For example, select no dates to search all records)</p>
<label for="date1">start date
<input id="date1" type="date"/></label>
<label for="date2">end date
<input id="date2" type="date"/></label>
<button id="get-reports-by-dates">Get Reports</button>
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