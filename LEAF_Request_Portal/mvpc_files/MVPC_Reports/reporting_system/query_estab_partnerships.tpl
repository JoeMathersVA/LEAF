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
    
var gridColorData = {15:'#ff0000'};     
    
function updateHeaderColors(grid){
    let headers = grid.headers();
    headers.forEach(function(header) {
        if (gridColorData.hasOwnProperty(header.indicatorID)) {
            let bg_color = gridColorData[header.indicatorID];
            //IE uses text inputs. Allows only #<6digithex>
            if (!/^#[0-9a-f]{6}$/i.test(bg_color)){
                gridColorData[header.indicatorID] = '#D1DFFF';
                bg_color = '#D1DFFF';
            }
            let elHeader = document.getElementById(grid.getPrefixID() + "header_" + header.indicatorID);
            let elVHeader = document.getElementById("Vheader_" + header.indicatorID);
            let arrRGB = [];  //convert from hex to RGB
            for (let i = 1; i < 7; i += 2) {
                arrRGB.push(parseInt(bg_color.slice(i, i + 2), 16));
            }
            let maxVal = Math.max(arrRGB[0],arrRGB[1],arrRGB[2]); //IE dies with spread op
            let sum = arrRGB.reduce(function(total, currentVal){
                return total + currentVal;
            });
            //pick text color based on bgcolor, apply to headers
            let textColor = maxVal < 128 || (sum < 350 && arrRGB[1] < 225) ? 'white' : 'black';
            elHeader.style.setProperty('background-color', bg_color);
            elVHeader.style.setProperty('background-color', bg_color);
            elHeader.style.setProperty('color', textColor);
            elVHeader.style.setProperty('color', textColor);
        }
    });
}      

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
    query.importQuery({"terms":[{"id":"categoryID","operator":"=","match":"form_a03ae","gate":"AND"},{"id":"deleted","operator":"=","match":0,"gate":"AND"}],"joins":["service","initiatorName"],"sort":{},"getData":["39","30","41","32","42"]});

    
    let now = new Date();
    let timezoneoffset = now.getTimezoneOffset()*60; //minutes --> sec
    if (dateStart !== undefined && dateStart !== ""){  
        let ds = new Date(dateStart);
        let dsAdjusted = ds.getTime() + timezoneoffset*1000;
    	query.addTerm('date', '>=', new Date(dsAdjusted));    //date 1
    } 
    if (dateEnd !== undefined && dateEnd !== ""){  
        let de = new Date(dateEnd);
        let deAdjusted = de.getTime() + timezoneoffset*1000;
    	query.addTerm('date','<=', new Date(deAdjusted));     //date 2
    } 
    
    
	query.onSuccess(function(res) {
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
            {name: 'Name of Organization', indicatorID: 39},
            {name: 'Organization Phone Number or Web Address', indicatorID: 30},
            {name: 'type (check one)', indicatorID: 32},
            {name: 'Goal of Partnership', indicatorID: 41},
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

    $('#headerTab').html('Established Partnerships');
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

<!--
<label for="administration-select">Administration
<select name="administration-select" id="administration-select">
    <option value=""></option>
    <option value="NCA">NCA</option>
    <option value="VBA">VBA</option>
    <option value="VHA">VHA</option>
</select>
</label>
-->

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